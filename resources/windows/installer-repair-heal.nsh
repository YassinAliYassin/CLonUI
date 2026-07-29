!ifndef CLONUI_INSTALLER_REPAIR_HEAL_NSH
!define CLONUI_INSTALLER_REPAIR_HEAL_NSH

Var /GLOBAL CLonUIRegistryInstallIsValid
Var /GLOBAL CLonUIInnerFailureSummary
Var /GLOBAL CLonUIInnerRootCode
Var /GLOBAL CLonUIInnerFailureReadResult

!macro CLONUI_READ_LAST_INNER_FAILURE
  InitPluginsDir
  StrCpy $CLonUIInnerRootCode ""
  StrCpy $CLonUIInnerFailureSummary "No specific locking process was identified. Close CLonUI, terminals, editors, and file managers opened in the install folder."
  nsExec::ExecToStack `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$logPath = '$CLonUISessionLogPath'; \
    $$summary = 'No specific locking process was identified. Close CLonUI, terminals, editors, and file managers opened in the install folder.'; \
    $$code = ''; \
    if ($$logPath -and (Test-Path -LiteralPath $$logPath)) { \
      $$events = @(Get-Content -LiteralPath $$logPath -ErrorAction SilentlyContinue | ForEach-Object { try { $$_ | ConvertFrom-Json } catch { $$null } } | Where-Object { $$_ }); \
      $$failure = @($$events | Where-Object { $$_.event -eq 'failure' -and $$_.updated -eq $$true } | Select-Object -Last 1)[0]; \
      if (-not $$failure) { $$failure = @($$events | Where-Object { $$_.event -eq 'failure' } | Select-Object -Last 1)[0] }; \
      if ($$failure) { \
        $$code = ([string]$$failure.code).Trim(); \
        $$phase = ([string]$$failure.phase).Trim(); \
        $$path = ([string]$$failure.failedPath).Trim(); \
        $$blocking = ''; \
        $$processes = @($$failure.blockingProcesses); \
        if ($$processes.Count -gt 0) { $$blocking = (@($$processes | ForEach-Object { if ($$_.pid) { [string]$$_.name + '(' + [string]$$_.pid + ')' } else { [string]$$_.name } }) -join ', ') }; \
        if (-not $$blocking) { $$blocking = ([string]$$failure.message).Trim() }; \
        if (-not $$blocking) { $$blocking = 'Windows did not identify a specific locking process. Close terminals, editors, and file managers opened in the install folder.' }; \
        $$parts = @('- Outer installer: previous uninstaller exited with code $R0', ('- Inner failure: ' + $$code + ' phase ' + $$phase)); \
        if ($$path) { $$parts += ('- File or folder: ' + $$path) }; \
        $$parts += ('- Blocking process: ' + $$blocking); \
        $$summary = $$parts -join [Environment]::NewLine; \
      } \
    }; \
    if (-not $$code) { $$code = '-----' }; \
    [Console]::Out.Write($$code + '|' + $$summary) \
  }"`
  Pop $CLonUIInnerFailureReadResult
  Pop $CLonUIInnerFailureReadResult
  StrCpy $CLonUIInnerRootCode $CLonUIInnerFailureReadResult 5
  ${If} $CLonUIInnerRootCode == "-----"
    StrCpy $CLonUIInnerRootCode ""
  ${EndIf}
  StrCpy $CLonUIInnerFailureSummary $CLonUIInnerFailureReadResult 4096 6
!macroend

!macro CLONUI_LOG_UNINSTALLER_REPAIR _PHASE
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$CLonUISessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${CLONUI_FALLBACK_LOG}' }; \
    $$path = '$INSTDIR\${UNINSTALL_FILENAME}'; \
    $$item = Get-Item -LiteralPath $$path -ErrorAction SilentlyContinue; \
    $$version = if ($$item) { $$item.VersionInfo.ProductVersion } else { '' }; \
    $$length = if ($$item) { $$item.Length } else { '' }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = '$CLonUISessionId'; version = '${VERSION}'; arch = '${CLONUI_TARGET_ARCH}'; updated = ('$CLonUIIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = 'uninstaller-repair'; phase = '${_PHASE}'; path = $$path; exists = [bool]$$item; productVersion = $$version; length = $$length }; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value ($$payload | ConvertTo-Json -Compress -Depth 8) \
  }"`
  Pop $CLonUIRepairLogResult
!macroend

!macro CLONUI_REPAIR_INSTALLED_UNINSTALLER
  Var /GLOBAL CLonUIInstalledUninstaller
  Var /GLOBAL CLonUIBundledUninstaller
  Var /GLOBAL CLonUIRepairLogResult

  !insertmacro CLONUI_LOG_UNINSTALLER_REPAIR "before"
  StrCpy $CLonUIInstalledUninstaller "$INSTDIR\${UNINSTALL_FILENAME}"

  InitPluginsDir
  StrCpy $CLonUIBundledUninstaller "$PLUGINSDIR\CLonUI-fixed-uninstaller.exe"
  SetOverwrite on
  File "/oname=$PLUGINSDIR\CLonUI-fixed-uninstaller.exe" "${UNINSTALLER_OUT_FILE}"

  ${If} ${FileExists} "$CLonUIInstalledUninstaller"
    ClearErrors
    CopyFiles /SILENT "$CLonUIBundledUninstaller" "$CLonUIInstalledUninstaller"
    ${If} ${Errors}
      !insertmacro CLONUI_LOG_UNINSTALLER_REPAIR "copy-failed-retry"
      !insertmacro CLONUI_STOP_APP_PROCESSES
      Sleep 1000

      ClearErrors
      CopyFiles /SILENT "$CLonUIBundledUninstaller" "$CLonUIInstalledUninstaller"
      ${If} ${Errors}
        ${If} ${FileExists} "$CLonUIBundledUninstaller"
          !insertmacro CLONUI_LOG_UNINSTALLER_REPAIR "copy-failed-using-bundled"
          !insertmacro CLONUI_LOG_EVENT "event=uninstaller-repair phase=copy-failed-using-bundled"
        ${Else}
          !insertmacro CLONUI_FAIL_REPORTABLE_BILINGUAL ${CLONUI_E_UNINSTALLER_COPY_OR_REBUILD_FAILED} "uninstaller-repair copy-failed-retry-bundled-missing" "${CLONUI_MSG_UNINSTALLER_COPY_LOCKED_EN}" "${CLONUI_MSG_UNINSTALLER_COPY_LOCKED_ZH}" "${CLONUI_MSG_UNINSTALLER_REPAIR_ACTION_EN}" "${CLONUI_MSG_UNINSTALLER_REPAIR_ACTION_ZH}"
        ${EndIf}
      ${Else}
        !insertmacro CLONUI_LOG_UNINSTALLER_REPAIR "after-copy-retry"
      ${EndIf}
    ${Else}
      !insertmacro CLONUI_LOG_UNINSTALLER_REPAIR "after-copy"
    ${EndIf}
  ${Else}
    ClearErrors
    CopyFiles /SILENT "$CLonUIBundledUninstaller" "$CLonUIInstalledUninstaller"
    ${If} ${Errors}
      !insertmacro CLONUI_FAIL_REPORTABLE_BILINGUAL ${CLONUI_E_UNINSTALLER_COPY_OR_REBUILD_FAILED} "uninstaller-repair rebuild-failed" "${CLONUI_MSG_UNINSTALLER_REBUILD_FAILED_EN}" "${CLONUI_MSG_UNINSTALLER_REBUILD_FAILED_ZH}" "${CLONUI_MSG_UNINSTALLER_REPAIR_ACTION_EN}" "${CLONUI_MSG_UNINSTALLER_REPAIR_ACTION_ZH}"
    ${EndIf}

    ${IfNot} ${FileExists} "$CLonUIInstalledUninstaller"
      !insertmacro CLONUI_FAIL_REPORTABLE_BILINGUAL ${CLONUI_E_UNINSTALLER_COPY_OR_REBUILD_FAILED} "uninstaller-repair rebuild-missing-after-copy" "${CLONUI_MSG_UNINSTALLER_REBUILD_MISSING_EN}" "${CLONUI_MSG_UNINSTALLER_REBUILD_MISSING_ZH}" "${CLONUI_MSG_UNINSTALLER_REPAIR_ACTION_EN}" "${CLONUI_MSG_UNINSTALLER_REPAIR_ACTION_ZH}"
    ${EndIf}

    !insertmacro CLONUI_LOG_UNINSTALLER_REPAIR "rebuilt"
    !insertmacro CLONUI_LOG_EVENT "event=uninstaller-repair phase=rebuilt"
  ${EndIf}
!macroend

!macro CLONUI_HEAL_INSTALL_REGISTRY
  Var /GLOBAL CLonUIRegInstallLocation
  Var /GLOBAL CLonUIRegUninstallString
  Var /GLOBAL CLonUIRegInstallExe

  StrCpy $CLonUIRegistryInstallIsValid "0"

  ReadRegStr $CLonUIRegInstallLocation SHCTX "${INSTALL_REGISTRY_KEY}" "InstallLocation"
  ReadRegStr $CLonUIRegUninstallString SHCTX "${UNINSTALL_REGISTRY_KEY}" "UninstallString"

  ${If} $CLonUIRegInstallLocation == ""
    !insertmacro CLONUI_LOG_EVENT "event=registry-heal phase=missing-install-location uninstallString=$CLonUIRegUninstallString"
    !insertmacro CLONUI_CLEAR_INSTALL_REGISTRY "missing-install-location"
  ${Else}
    StrCpy $CLonUIRegInstallExe "$CLonUIRegInstallLocation\${CLONUI_APP_EXECUTABLE_FILENAME}"
    ${If} ${FileExists} "$CLonUIRegInstallExe"
      StrCpy $INSTDIR "$CLonUIRegInstallLocation"
      StrCpy $CLonUIRegistryInstallIsValid "1"
      !insertmacro CLONUI_LOG_EVENT "event=registry-heal phase=valid-install-location instDir=$INSTDIR uninstallString=$CLonUIRegUninstallString"
    ${Else}
      !insertmacro CLONUI_LOG_EVENT "event=registry-heal phase=stale-install-location installLocation=$CLonUIRegInstallLocation uninstallString=$CLonUIRegUninstallString"
      !insertmacro CLONUI_CLEAR_INSTALL_REGISTRY "stale-install-location"
    ${EndIf}
  ${EndIf}
!macroend

!macro CLONUI_LOG_UNINSTALL_RESULT _ROOT_KEY _HAD_ERRORS
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$CLonUISessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${CLONUI_FALLBACK_LOG}' }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = '$CLonUISessionId'; version = '${VERSION}'; arch = '${CLONUI_TARGET_ARCH}'; updated = ('$CLonUIIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = 'uninstall-result'; root = '${_ROOT_KEY}'; launchErrors = '${_HAD_ERRORS}'; exitCode = '$R0' }; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value ($$payload | ConvertTo-Json -Compress -Depth 8) \
  }"`
  Pop $CLonUIUninstallLogResult
!macroend

!macro CLONUI_HANDLE_UNINSTALL_RESULT _ROOT_KEY _LABEL_PREFIX
  ${If} ${Errors}
    StrCpy $CLonUIUninstallHadErrors "1"
  ${Else}
    StrCpy $CLonUIUninstallHadErrors "0"
  ${EndIf}

  !insertmacro CLONUI_LOG_UNINSTALL_RESULT "${_ROOT_KEY}" "$CLonUIUninstallHadErrors"

  ${If} $CLonUIUninstallHadErrors == "1"
    DetailPrint `Uninstall was not successful. Not able to launch uninstaller!`
    Return
  ${EndIf}

  ${If} $R0 != 0
      DetailPrint `Uninstall was not successful. Uninstaller error code: $R0.`
      !insertmacro CLONUI_READ_LAST_INNER_FAILURE
      ${If} $CLonUILockerList != ""
        StrCpy $CLonUIInnerFailureSummary "- Failure: previous uninstaller failed with exit code $R0$\r$\n- File or folder: $INSTDIR$\r$\n- Blocking process: $CLonUILockerList"
      ${EndIf}
      !insertmacro CLONUI_LOG_EVENT "event=old-uninstaller-failed action=report exitCode=$R0 lockers=$CLonUILockerList uninstallerDetail=$CLonUIInnerFailureSummary"
      ${If} $CLonUIInnerRootCode != ""
        !insertmacro CLONUI_FAIL_REPORTABLE_ROOTED_BILINGUAL_DIAGNOSTICS "$CLonUIInnerRootCode" ${CLONUI_E_OLD_UNINSTALL_FAILED} "old-uninstaller exitCode=$R0 lockers=$CLonUILockerList uninstallerDetail=$CLonUIInnerFailureSummary" "${CLONUI_MSG_OLD_UNINSTALL_FAILED_EN}" "${CLONUI_MSG_OLD_UNINSTALL_FAILED_ZH}" "${CLONUI_MSG_OLD_UNINSTALL_ACTION_EN}" "${CLONUI_MSG_OLD_UNINSTALL_ACTION_ZH}" "$CLonUIInnerFailureSummary" "$CLonUIInnerFailureSummary"
      ${Else}
        !insertmacro CLONUI_FAIL_REPORTABLE_BILINGUAL_DIAGNOSTICS ${CLONUI_E_OLD_UNINSTALL_FAILED} "old-uninstaller exitCode=$R0 lockers=$CLonUILockerList uninstallerDetail=$CLonUIInnerFailureSummary" "${CLONUI_MSG_OLD_UNINSTALL_FAILED_EN}" "${CLONUI_MSG_OLD_UNINSTALL_FAILED_ZH}" "${CLONUI_MSG_OLD_UNINSTALL_ACTION_EN}" "${CLONUI_MSG_OLD_UNINSTALL_ACTION_ZH}" "$CLonUIInnerFailureSummary" "$CLonUIInnerFailureSummary"
      ${EndIf}
  ${EndIf}
!macroend

!macro customInit
  !insertmacro CLONUI_HEAL_INSTALL_REGISTRY
  ${If} $CLonUIRegistryInstallIsValid == "1"
    !insertmacro CLONUI_REPAIR_INSTALLED_UNINSTALLER
  ${EndIf}
!macroend

!macro customUnInstallCheck
  !insertmacro CLONUI_HANDLE_UNINSTALL_RESULT "SHELL_CONTEXT" "shctx"
!macroend

!macro customUnInstallCheckCurrentUser
  !insertmacro CLONUI_HANDLE_UNINSTALL_RESULT "HKEY_CURRENT_USER" "hkcu"
!macroend

!endif
