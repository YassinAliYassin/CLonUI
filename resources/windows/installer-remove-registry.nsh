!ifndef CLONUI_INSTALLER_REMOVE_REGISTRY_NSH
!define CLONUI_INSTALLER_REMOVE_REGISTRY_NSH

!macro CLONUI_CLEAR_INSTALL_REGISTRY _REASON
  DeleteRegKey SHCTX "${UNINSTALL_REGISTRY_KEY}"
  DeleteRegKey SHCTX "${INSTALL_REGISTRY_KEY}"
  !insertmacro CLONUI_LOG_EVENT "event=registry-clear reason=${_REASON} uninstallKey=${UNINSTALL_REGISTRY_KEY} installKey=${INSTALL_REGISTRY_KEY}"
!macroend

!macro CLONUI_LOG_ATOMIC_REMOVE_FAILURE
  Push $9
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$CLonUISessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${CLONUI_FALLBACK_LOG}' }; \
    $$failed = '$CLonUIAtomicFailedPath'; \
    $$instDir = '$INSTDIR'; \
    $$oldInstallDir = '$CLonUIAtomicStagingDir'; \
    $$relative = $$failed; \
    if ($$failed.StartsWith($$instDir, [System.StringComparison]::CurrentCultureIgnoreCase)) { $$relative = $$failed.Substring($$instDir.Length).TrimStart('\') }; \
    $$tempCandidate = if ($$relative -and $$relative -ne $$failed) { Join-Path $$oldInstallDir $$relative } else { '' }; \
    $$kind = if ($$tempCandidate.Length -ge 260) { 'likely-long-path' } else { 'unknown' }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = '$CLonUISessionId'; version = '${VERSION}'; arch = '${CLONUI_TARGET_ARCH}'; updated = ('$CLonUIIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = 'remove-atomic-failed'; kind = $$kind; pathLength = $$failed.Length; tempCandidateLength = $$tempCandidate.Length; atomicFailedPath = $$failed; tempCandidate = $$tempCandidate }; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value ($$payload | ConvertTo-Json -Compress -Depth 8) \
  }"`
  Pop $9
  Pop $9
!macroend

!macro CLONUI_LOG_REMOVE_FAILURE_JSON _PHASE _FATAL _FAILED_PATH _EXTRA_FIELDS
  !insertmacro CLONUI_LOG_JSON_EVENT "failure" "$$lockerText = '$CLonUILockerList'; $$processes = @(); if ($$lockerText -and $$lockerText -notlike 'Windows did not identify*' -and $$lockerText -ne 'unknown process') { $$processes = @($$lockerText -split ',\s*' | Where-Object { $$_ } | ForEach-Object { if ($$_ -match '^(.*)\(([0-9]+)\)$$') { [ordered]@{ name = $$Matches[1]; pid = [int]$$Matches[2] } } else { [ordered]@{ name = $$_; pid = $$null } } }) }; $$payload.code = '${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED}'; $$payload.phase = '${_PHASE}'; $$payload.failedPath = '${_FAILED_PATH}'; $$payload.blockingProcesses = @($$processes); if ($$lockerText -like 'CLonUI installer(*)') { $$payload.fallbackReason = 'installer-self-lock'; $$payload.message = 'The installer process is using the install directory as its current output directory.' } elseif ($$processes.Count -eq 0) { $$payload.fallbackReason = 'restart-manager-no-process'; $$payload.message = 'Windows did not identify a specific locking process. Close terminals, editors, and file managers opened in the install folder.' } else { $$payload.fallbackReason = ''; $$payload.message = '' }; $$payload.fatal = ('${_FATAL}' -eq '1'); ${_EXTRA_FIELDS}"
!macroend

!macro CLONUI_REMOVE_INSTALL_DIR
  StrCpy $CLonUIRemoveResidueCount "0"
  ${If} $CLonUIRemoveResidueRoot == ""
    StrCpy $CLonUIRemoveResidueRoot "$INSTDIR"
  ${EndIf}
  StrCpy $CLonUIRemoveFirstFailedPath ""
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'Continue'; \
    $$log = '$CLonUISessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${CLONUI_FALLBACK_LOG}' }; \
    $$path = [System.IO.Path]::GetFullPath('$CLonUIRemoveResidueRoot'); \
    $$firstFailedFile = '$PLUGINSDIR\clonui-remove-first-failed.txt'; \
    Set-Content -LiteralPath $$firstFailedFile -Encoding UTF8 -NoNewline -Value ''; \
    function Write-InstallerLog($$message) { $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = '$CLonUISessionId'; version = '${VERSION}'; arch = '${CLONUI_TARGET_ARCH}'; updated = ('$CLonUIIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = 'remove-log'; message = $$message }; if ($$message -match '(^|\s)event=([^\s]+)') { $$payload.event = $$Matches[2] }; Add-Content -LiteralPath $$log -Encoding UTF8 -Value ($$payload | ConvertTo-Json -Compress -Depth 8) } \
    function Convert-LongPath($$itemPath) { if ($$itemPath.StartsWith('\\')) { return '\\?\UNC\' + $$itemPath.TrimStart('\') } return '\\?\' + $$itemPath } \
    function Remove-WithRetries($$item, $$isDir) { \
      $$delays = @(200,500,1000); \
      for ($$i = 0; $$i -lt $$delays.Count; $$i++) { \
        try { \
          if ($$isDir) { [System.IO.Directory]::Delete((Convert-LongPath $$item), $$false) } else { [System.IO.File]::Delete((Convert-LongPath $$item)) } \
          return $$true \
        } catch { \
          if ($$i -lt $$delays.Count - 1) { Start-Sleep -Milliseconds $$delays[$$i] } else { Write-InstallerLog ('event=remove-resilient-leftover path=' + $$item + ' attempts=3 error=' + $$_.Exception.GetType().FullName + ': ' + $$_.Exception.Message); return $$false } \
        } \
      } \
      return $$false \
    } \
    try { \
      if (-not (Test-Path -LiteralPath $$path)) { Write-InstallerLog ('remove-longpath result=0 instDir=' + $$path); exit 0 } \
      $$failed = New-Object System.Collections.Generic.List[string]; \
      foreach ($$file in @(Get-ChildItem -LiteralPath $$path -Force -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)) { if (-not (Remove-WithRetries $$file.FullName $$false)) { $$failed.Add($$file.FullName) } } \
      foreach ($$dir in @(Get-ChildItem -LiteralPath $$path -Force -Recurse -Directory -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)) { if (-not (Remove-WithRetries $$dir.FullName $$true)) { $$failed.Add($$dir.FullName) } } \
      if (-not (Remove-WithRetries $$path $$true)) { $$failed.Add($$path) } \
      Write-InstallerLog ('event=remove-resilient-summary failedCount=' + $$failed.Count + ' root=' + $$path); \
      if ($$failed.Count -gt 0) { Set-Content -LiteralPath $$firstFailedFile -Encoding UTF8 -NoNewline -Value $$failed[0]; exit $$failed.Count } \
      Write-InstallerLog ('remove-longpath result=0 instDir=' + $$path); \
      exit 0 \
    } catch { \
      Write-InstallerLog ('remove-longpath result=1 instDir=' + $$path + ' error=' + $$_.Exception.GetType().FullName + ': ' + $$_.Exception.Message); \
      exit 1 \
    } \
  }"`
  Pop $CLonUIRemoveDirResult

  ClearErrors
  SetDetailsPrint none
  FileOpen $CLonUIRemoveFirstFailedFile "$PLUGINSDIR\clonui-remove-first-failed.txt" r
  ${IfNot} ${Errors}
    FileRead $CLonUIRemoveFirstFailedFile $CLonUIRemoveFirstFailedPath
    FileClose $CLonUIRemoveFirstFailedFile
  ${EndIf}
  SetDetailsPrint lastused

  ${If} $CLonUIRemoveDirResult == "error"
    !insertmacro CLONUI_LOG_EVENT "event=remove-longpath fallback=RMDir reason=no-powershell root=$INSTDIR"
    RMDir /r "$CLonUIRemoveResidueRoot"
    ${If} ${FileExists} "$CLonUIRemoveResidueRoot\*.*"
      StrCpy $CLonUIRemoveDirResult "1"
    ${Else}
      StrCpy $CLonUIRemoveDirResult "0"
    ${EndIf}
  ${EndIf}

  ${If} $CLonUIRemoveDirResult != 0
    StrCpy $CLonUIRemoveResidueCount $CLonUIRemoveDirResult
  ${EndIf}
!macroend

!macro customRemoveFiles
  !insertmacro CLONUI_LOG_EVENT "remove-start instDir=$INSTDIR"
  Var /GLOBAL CLonUIRemoveDirResult
  Var /GLOBAL CLonUIAtomicFailedPath
  Var /GLOBAL CLonUIAtomicRemoveSucceeded
  Var /GLOBAL CLonUIAtomicStagingDir
  Var /GLOBAL CLonUIRemoveResidueCount
  Var /GLOBAL CLonUIRemoveResidueRoot
  Var /GLOBAL CLonUIRemoveFirstFailedPath
  Var /GLOBAL CLonUIRemoveFirstFailedFile
  StrCpy $CLonUIAtomicFailedPath ""
  StrCpy $CLonUIAtomicRemoveSucceeded "0"
  StrCpy $CLonUIAtomicStagingDir ""
  StrCpy $CLonUIRemoveResidueCount "0"
  StrCpy $CLonUIRemoveResidueRoot "$INSTDIR"
  StrCpy $CLonUIRemoveFirstFailedPath ""

  SetOutPath $TEMP
  StrCpy $CLonUICurrentOutDir "$TEMP"

  ${if} ${isUpdated}
    StrCpy $CLonUIAtomicStagingDir "$INSTDIR.__old"
    ${If} ${FileExists} "$CLonUIAtomicStagingDir\*.*"
      StrCpy $CLonUIRemoveResidueRoot "$CLonUIAtomicStagingDir"
      !insertmacro CLONUI_LOG_EVENT "remove-stale-staging start root=$CLonUIRemoveResidueRoot"
      !insertmacro CLONUI_REMOVE_INSTALL_DIR
      StrCpy $CLonUIRemoveResidueRoot "$INSTDIR"
    ${EndIf}

    clonui_retry_atomic_rename:
      ClearErrors
      Rename "$INSTDIR" "$CLonUIAtomicStagingDir"
    ${if} ${Errors}
      DetailPrint "Atomic update cleanup failed before replacing previous installation: $INSTDIR"
      StrCpy $CLonUIAtomicFailedPath "$INSTDIR"
      !insertmacro CLONUI_LOG_ATOMIC_REMOVE_FAILURE
      !insertmacro CLONUI_CAPTURE_FAILED_PATH_LOCKERS "$CLonUIAtomicFailedPath"
      ${IfNot} ${Silent}
        !insertmacro CLONUI_PROMPT_FAILED_PATH_LOCKERS "$CLonUIAtomicFailedPath" "atomic-failed" clonui_retry_atomic_rename clonui_cancel_atomic_rename clonui_continue_atomic_failed
        clonui_cancel_atomic_rename:
      ${EndIf}
      clonui_continue_atomic_failed:
      !insertmacro CLONUI_LOG_REMOVE_FAILURE_JSON "atomic-failed" "1" "$CLonUIAtomicFailedPath" "$$payload.atomicFailedPath = '$CLonUIAtomicFailedPath'"
      !insertmacro CLONUI_LOG_EVENT "code=${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=atomic-failed fatal=1 degraded=none firstFailed=$CLonUIAtomicFailedPath atomicFailedPath=$CLonUIAtomicFailedPath"
      !insertmacro CLONUI_CLEAR_INSTALL_REGISTRY "remove-failed-before-quit"
      !insertmacro CLONUI_FAIL_REPORTABLE_BILINGUAL ${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} "event=session-end result=fail code=${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=atomic-failed fatal=1 firstFailed=$CLonUIAtomicFailedPath lockers=$CLonUILockerList" "${CLONUI_MSG_REPLACE_LOCKED_EN}" "${CLONUI_MSG_REPLACE_LOCKED_ZH}" "${CLONUI_MSG_CLOSE_SHOWN_FILE_ACTION_EN}" "${CLONUI_MSG_CLOSE_SHOWN_FILE_ACTION_ZH}"
    ${else}
      !insertmacro CLONUI_LOG_EVENT "remove-atomic result=0 staging=$CLonUIAtomicStagingDir"
      StrCpy $CLonUIAtomicRemoveSucceeded "1"
      StrCpy $CLonUIRemoveResidueRoot "$CLonUIAtomicStagingDir"
    ${endif}
  ${endif}

  clonui_retry_remove_install_dir:
    !insertmacro CLONUI_REMOVE_INSTALL_DIR
  ${if} $CLonUIRemoveDirResult != 0
    !insertmacro CLONUI_CAPTURE_FAILED_PATH_LOCKERS "$CLonUIRemoveFirstFailedPath"
    ${if} $CLonUIAtomicRemoveSucceeded == "1"
      ${IfNot} ${Silent}
        !insertmacro CLONUI_PROMPT_FAILED_PATH_LOCKERS "$CLonUIRemoveFirstFailedPath" "residual-delete-failed" clonui_retry_remove_install_dir clonui_cancel_remove_after_rm clonui_continue_after_rm
        clonui_cancel_remove_after_rm:
          !insertmacro CLONUI_LOG_REMOVE_FAILURE_JSON "residual-delete-failed" "1" "$CLonUIRemoveFirstFailedPath" "$$payload.residueRoot = '$CLonUIRemoveResidueRoot'; $$payload.failedCount = '$CLonUIRemoveResidueCount'; $$payload.removeDirResult = '$CLonUIRemoveDirResult'; $$payload.atomicSucceeded = ('$CLonUIAtomicRemoveSucceeded' -eq '1')"
          !insertmacro CLONUI_LOG_EVENT "code=${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed userAction=cancel fatal=1 residueRoot=$CLonUIRemoveResidueRoot failedCount=$CLonUIRemoveResidueCount firstFailed=$CLonUIRemoveFirstFailedPath removeDirResult=$CLonUIRemoveDirResult removeResidueCount=$CLonUIRemoveResidueCount atomicFailedPath=$CLonUIAtomicFailedPath atomicSucceeded=$CLonUIAtomicRemoveSucceeded"
          !insertmacro CLONUI_FAIL_REPORTABLE_BILINGUAL ${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} "event=session-end result=fail code=${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed userAction=cancel fatal=1 firstFailed=$CLonUIRemoveFirstFailedPath lockers=$CLonUILockerList" "${CLONUI_MSG_PREVIOUS_FILE_OPEN_EN}" "${CLONUI_MSG_PREVIOUS_FILE_OPEN_ZH}" "${CLONUI_MSG_CLOSE_SHOWN_FILE_ACTION_EN}" "${CLONUI_MSG_CLOSE_SHOWN_FILE_ACTION_ZH}"
      ${EndIf}
      clonui_continue_after_rm:
      DetailPrint `CLonUI previous installation had locked residual files; continuing after atomic cleanup succeeded: $INSTDIR`
      !insertmacro CLONUI_LOG_EVENT "code=${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed degraded=continue fatal=0 residueRoot=$CLonUIRemoveResidueRoot failedCount=$CLonUIRemoveResidueCount firstFailed=$CLonUIRemoveFirstFailedPath removeDirResult=$CLonUIRemoveDirResult removeResidueCount=$CLonUIRemoveResidueCount atomicFailedPath=$CLonUIAtomicFailedPath atomicSucceeded=$CLonUIAtomicRemoveSucceeded"
    ${else}
      DetailPrint `Can't safely remove previous installation without atomic cleanup proof: $INSTDIR`
      ${IfNot} ${Silent}
        !insertmacro CLONUI_PROMPT_FAILED_PATH_LOCKERS "$CLonUIRemoveFirstFailedPath" "residual-delete-failed-no-atomic-proof" clonui_retry_remove_install_dir clonui_cancel_remove_no_atomic clonui_continue_remove_no_atomic
        clonui_cancel_remove_no_atomic:
      ${EndIf}
      clonui_continue_remove_no_atomic:
      !insertmacro CLONUI_LOG_REMOVE_FAILURE_JSON "residual-delete-failed-no-atomic-proof" "1" "$CLonUIRemoveFirstFailedPath" "$$payload.residueRoot = '$CLonUIRemoveResidueRoot'; $$payload.failedCount = '$CLonUIRemoveResidueCount'; $$payload.removeDirResult = '$CLonUIRemoveDirResult'; $$payload.atomicSucceeded = ('$CLonUIAtomicRemoveSucceeded' -eq '1')"
      !insertmacro CLONUI_LOG_EVENT "code=${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed-no-atomic-proof degraded=none fatal=1 residueRoot=$CLonUIRemoveResidueRoot failedCount=$CLonUIRemoveResidueCount firstFailed=$CLonUIRemoveFirstFailedPath removeDirResult=$CLonUIRemoveDirResult removeResidueCount=$CLonUIRemoveResidueCount atomicFailedPath=$CLonUIAtomicFailedPath atomicSucceeded=$CLonUIAtomicRemoveSucceeded"
      !insertmacro CLONUI_CLEAR_INSTALL_REGISTRY "remove-failed-before-quit"
      !insertmacro CLONUI_FAIL_REPORTABLE_BILINGUAL ${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} "event=session-end result=fail code=${CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED} phase=residual-delete-failed-no-atomic-proof fatal=1 firstFailed=$CLonUIRemoveFirstFailedPath removeDirResult=$CLonUIRemoveDirResult lockers=$CLonUILockerList" "${CLONUI_MSG_REMOVE_PREVIOUS_DIR_EN}" "${CLONUI_MSG_REMOVE_PREVIOUS_DIR_ZH}" "${CLONUI_MSG_CLOSE_INSTALL_DIR_ACTION_EN}" "${CLONUI_MSG_CLOSE_INSTALL_DIR_ACTION_ZH}"
    ${endif}
  ${else}
    !insertmacro CLONUI_LOG_EVENT "remove-final errors=0 instDir=$INSTDIR removeDirResult=$CLonUIRemoveDirResult removeResidueCount=$CLonUIRemoveResidueCount removeResidueRoot=$CLonUIRemoveResidueRoot atomicFailedPath=$CLonUIAtomicFailedPath atomicSucceeded=$CLonUIAtomicRemoveSucceeded"
  ${endif}
!macroend

!macro customUnInit
  !insertmacro CLONUI_LOG_EVENT "uninit instDir=$INSTDIR"
!macroend

!macro customUnInstall
  !insertmacro CLONUI_LOG_EVENT "uninstall-section start instDir=$INSTDIR"
!macroend

!endif
