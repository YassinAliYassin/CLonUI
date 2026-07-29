!ifndef CLONUI_INSTALLER_UPDATE_VERIFY_NSH
!define CLONUI_INSTALLER_UPDATE_VERIFY_NSH

Var /GLOBAL CLonUIUninstallHadErrors
Var /GLOBAL CLonUIUninstallLogResult
Var /GLOBAL CLonUIVerifyResourceResult
Var /GLOBAL CLonUIUpdatedAppExitWaitResult
Var /GLOBAL CLonUIActiveMarkerExecResult
Var /GLOBAL CLonUIActiveMarkerResult

!define CLONUI_ACTIVE_INSTALLER_MARKER "clonui-installer-active.marker"

!macro CLONUI_BRING_UPDATED_INSTALLER_TO_FRONT
  ${If} ${isUpdated}
    BringToFront
    !insertmacro CLONUI_SLOG "event=updated-installer-foreground action=bring-to-front"
  ${EndIf}
!macroend

!macro CLONUI_WAIT_FOR_UPDATED_APP_EXIT
  ${If} ${isUpdated}
    !insertmacro CLONUI_SLOG "event=updated-app-exit-wait phase=start"
    StrCpy $CLonUIUpdatedAppExitWaitResult "0"

    nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
      $$ErrorActionPreference = 'SilentlyContinue'; \
      $$deadline = (Get-Date).AddSeconds(10); \
      $$target = [System.IO.Path]::GetFullPath((Join-Path '$INSTDIR' '${CLONUI_APP_EXECUTABLE_FILENAME}')); \
      do { \
        $$hits = @(Get-CimInstance -ClassName Win32_Process | Where-Object { \
          $$path = $$_.ExecutablePath; \
          if (-not $$path) { $$path = $$_.Path } \
          $$_.Name -ieq '${CLONUI_APP_EXECUTABLE_FILENAME}' -and $$path -and \
          [string]::Equals([System.IO.Path]::GetFullPath($$path), $$target, [System.StringComparison]::CurrentCultureIgnoreCase) \
        }); \
        if ($$hits.Count -eq 0) { exit 0 }; \
        Start-Sleep -Milliseconds 500; \
      } while ((Get-Date) -lt $$deadline); \
      exit 1 \
    }"`
    Pop $CLonUIUpdatedAppExitWaitResult

    ${If} $CLonUIUpdatedAppExitWaitResult != 0
      !insertmacro CLONUI_SLOG "event=updated-app-exit-wait phase=timeout action=stop"
      !insertmacro CLONUI_STOP_APP_PROCESSES
    ${EndIf}

    !insertmacro CLONUI_SLOG "event=updated-app-exit-wait phase=done result=$CLonUIUpdatedAppExitWaitResult"
  ${EndIf}
!macroend

!macro CLONUI_RECORD_ACTIVE_INSTALLER_MARKER
  nsExec::ExecToStack `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$marker = Join-Path $$env:TEMP '${CLONUI_ACTIVE_INSTALLER_MARKER}'; \
    if (-not (Test-Path -LiteralPath $$marker)) { Write-Output 'missing'; exit 0 }; \
    $$item = Get-Item -LiteralPath $$marker; \
    if ($$item.LastWriteTime -lt (Get-Date).AddHours(-2)) { Write-Output 'stale'; exit 0 }; \
    Write-Output 'active' \
  }"`
  Pop $CLonUIActiveMarkerExecResult
  Pop $CLonUIActiveMarkerResult
  ${If} $CLonUIActiveMarkerResult == "active"
    !insertmacro CLONUI_SLOG "event=installer-active-marker state=active"
  ${ElseIf} $CLonUIActiveMarkerResult == "stale"
    !insertmacro CLONUI_SLOG "event=installer-active-marker state=stale"
  ${Else}
    !insertmacro CLONUI_SLOG "event=installer-active-marker state=missing"
  ${EndIf}
!macroend

!macro CLONUI_WRITE_ACTIVE_INSTALLER_MARKER
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$marker = Join-Path $$env:TEMP '${CLONUI_ACTIVE_INSTALLER_MARKER}'; \
    Set-Content -LiteralPath $$marker -Encoding UTF8 -Value ('pid=' + $$PID + ';session=$CLonUISessionId;started=' + (Get-Date -Format o)) \
  }"`
  Pop $CLonUIActiveMarkerResult
!macroend

!macro CLONUI_CLEAR_ACTIVE_INSTALLER_MARKER
  !ifndef BUILD_UNINSTALLER
    nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
      $$ErrorActionPreference = 'SilentlyContinue'; \
      Remove-Item -LiteralPath (Join-Path $$env:TEMP '${CLONUI_ACTIVE_INSTALLER_MARKER}') -Force \
    }"`
    Pop $CLonUIActiveMarkerResult
  !endif
!macroend

!macro CLONUI_OVERRIDE_SINGLE_INSTANCE
!macroend

!macro CLONUI_OVERRIDE_APP_CANNOT_BE_CLOSED_MESSAGE
  !pragma warning disable 6030
  LangString appCannotBeClosed 1033 "${CLONUI_MSG_APP_CANNOT_BE_CLOSED_ZH}$\r$\n$\r$\n${CLONUI_MSG_BLOCK_SEPARATOR}$\r$\n$\r$\n${CLONUI_MSG_APP_CANNOT_BE_CLOSED_EN}"
  LangString appCannotBeClosed 2052 "${CLONUI_MSG_APP_CANNOT_BE_CLOSED_ZH}$\r$\n$\r$\n${CLONUI_MSG_BLOCK_SEPARATOR}$\r$\n$\r$\n${CLONUI_MSG_APP_CANNOT_BE_CLOSED_EN}"
  !pragma warning default 6030
!macroend

!macro CLONUI_INSTALLER_CUSTOM_HEADER
  !insertmacro CLONUI_OVERRIDE_SINGLE_INSTANCE
  !insertmacro CLONUI_OVERRIDE_APP_CANNOT_BE_CLOSED_MESSAGE
!macroend

!macro CLONUI_RELEASE_INSTALL_DIR_OUTDIR
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  StrCpy $CLonUICurrentOutDir "$PLUGINSDIR"
!macroend

; Resolve the machine's real native architecture (arm64 / x64 / x86) for diagnostics.
; Backed by IsWow64Process2 (via x64.nsh), so it reports the true hardware arch even when
; the installer runs under x86/x64 emulation. Replaces the old hardcoded "non-arm64" detail.
!macro CLONUI_DETECT_NATIVE_ARCH _OUT
  ${If} ${IsNativeARM64}
    StrCpy ${_OUT} "arm64"
  ${ElseIf} ${RunningX64}
    StrCpy ${_OUT} "x64"
  ${Else}
    StrCpy ${_OUT} "x86"
  ${EndIf}
!macroend

!macro CLONUI_INSTALLER_PREINIT
  !ifdef BUILD_UNINSTALLER
    StrCpy $CLonUISessionId ""
    StrCpy $CLonUIIsUpdated "0"
    StrCpy $CLonUISessionLogResult ""
    StrCpy $CLonUISessionLogPath "$TEMP\${CLONUI_FALLBACK_LOG}"
    StrCpy $CLonUIUninstallHadErrors "0"
    StrCpy $CLonUIUninstallLogResult ""
    StrCpy $CLonUIVerifyResourceResult ""
    StrCpy $CLonUIUpdatedAppExitWaitResult ""
    StrCpy $CLonUIActiveMarkerExecResult ""
    StrCpy $CLonUIActiveMarkerResult ""
    StrCpy $CLonUIStopResult ""
    StrCpy $CLonUILockerListZh ""
    StrCpy $CLonUILockerListEn ""
  !else
    !insertmacro CLONUI_RELEASE_INSTALL_DIR_OUTDIR
    !insertmacro CLONUI_SESSION_BEGIN
    !insertmacro CLONUI_SLOG "event=installer-outdir-release outDir=$CLonUICurrentOutDir instDir=$INSTDIR"
    ; Guard target/machine architecture as early as possible: this runs before customInit's
    ; registry heal/clear/repair, so a wrong-arch installer aborts without mutating an existing
    ; correct-arch install's registry or uninstaller state. (Sentry ELECTRON-3BX / code E1040)
    !insertmacro CLONUI_ASSERT_TARGET_ARCH
    !insertmacro CLONUI_BRING_UPDATED_INSTALLER_TO_FRONT
    !insertmacro CLONUI_RECORD_ACTIVE_INSTALLER_MARKER
    !insertmacro CLONUI_WRITE_ACTIVE_INSTALLER_MARKER
  !endif
!macroend

!macro CLONUI_VERIFY_REQUIRED_FILE _PATH _LABEL
  ${IfNot} ${FileExists} "${_PATH}"
    !insertmacro CLONUI_LOG_EVENT "verify-required-file missing label=${_LABEL} path=${_PATH}"
    !insertmacro CLONUI_FAIL_UX \
      "${CLONUI_E_CORE_APP_FILES_INCOMPLETE}" \
      "verify-required-file missing label=${_LABEL} path=${_PATH}" \
      "${CLONUI_MSG_VERIFY_REQUIRED_FILE_ZH} ${_LABEL}" \
      "${CLONUI_MSG_VERIFY_REQUIRED_FILE_EN} ${_LABEL}" \
      "${CLONUI_MSG_VERIFY_REQUIRED_FILE_ACTION_ZH}" \
      "${CLONUI_MSG_VERIFY_REQUIRED_FILE_ACTION_EN}" \
      "verify-required-file missing label=${_LABEL} path=${_PATH}" \
      "verify-required-file missing label=${_LABEL} path=${_PATH}"
  ${Else}
    !insertmacro CLONUI_LOG_EVENT "verify-required-file ok label=${_LABEL} path=${_PATH}"
  ${EndIf}
!macroend

!macro CLONUI_VERIFY_CORE_APP_FILES
  !insertmacro CLONUI_LOG_EVENT "verify-install start instDir=$INSTDIR"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\CLonUI.exe" "CLonUI.exe"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\ffmpeg.dll" "ffmpeg.dll"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\libEGL.dll" "libEGL.dll"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\libGLESv2.dll" "libGLESv2.dll"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\d3dcompiler_47.dll" "d3dcompiler_47.dll"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\dxcompiler.dll" "dxcompiler.dll"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\dxil.dll" "dxil.dll"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\vk_swiftshader.dll" "vk_swiftshader.dll"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\vulkan-1.dll" "vulkan-1.dll"
  !insertmacro CLONUI_VERIFY_REQUIRED_FILE "$INSTDIR\resources\app.asar" "resources\app.asar"
!macroend

!macro CLONUI_VERIFY_BUNDLED_AIONCORE_RESOURCES _RUNTIME_KEY
  InitPluginsDir
  File "/oname=$PLUGINSDIR\verify-bundled-aioncore-install.ps1" "${PROJECT_DIR}\resources\windows\support\verify-bundled-aioncore-install.ps1"
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\verify-bundled-aioncore-install.ps1" -InstallDir "$INSTDIR" -RuntimeKey "${_RUNTIME_KEY}" -LogPath "$CLonUISessionLogPath"`
  Pop $CLonUIVerifyResourceResult

  ${If} $CLonUIVerifyResourceResult != 0
    !insertmacro CLONUI_FAIL_UX \
      "${CLONUI_E_BUNDLED_AIONCORE_INCOMPLETE}" \
      "event=session-end result=fail code=${CLONUI_E_BUNDLED_AIONCORE_INCOMPLETE} detail=bundled-aioncore-incomplete runtime=${_RUNTIME_KEY} result=$CLonUIVerifyResourceResult" \
      "${CLONUI_MSG_BUNDLED_AIONCORE_INCOMPLETE_ZH}" \
      "${CLONUI_MSG_BUNDLED_AIONCORE_INCOMPLETE_EN}" \
      "${CLONUI_MSG_BUNDLED_AIONCORE_INCOMPLETE_ACTION_ZH}" \
      "${CLONUI_MSG_BUNDLED_AIONCORE_INCOMPLETE_ACTION_EN}" \
      "bundled-aioncore-incomplete runtime=${_RUNTIME_KEY} result=$CLonUIVerifyResourceResult instDir=$INSTDIR" \
      "bundled-aioncore-incomplete runtime=${_RUNTIME_KEY} result=$CLonUIVerifyResourceResult instDir=$INSTDIR"
  ${EndIf}
!macroend

!macro customInstall
  !insertmacro CLONUI_VERIFY_CORE_APP_FILES
  !insertmacro CLONUI_VERIFY_BUNDLED_AIONCORE_RESOURCES "${CLONUI_RUNTIME_KEY}"
  !insertmacro CLONUI_LOG_EVENT "verify-install ok instDir=$INSTDIR"
  !insertmacro CLONUI_CLEAR_ACTIVE_INSTALLER_MARKER
  !insertmacro CLONUI_SESSION_SUCCESS
!macroend

!endif
