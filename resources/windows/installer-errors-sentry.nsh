!ifndef CLONUI_INSTALLER_ERRORS_SENTRY_NSH
!define CLONUI_INSTALLER_ERRORS_SENTRY_NSH

!include "${PROJECT_DIR}\resources\windows\support\_sentry-dsn.generated.nsh"
!include "${PROJECT_DIR}\resources\windows\installer-messages.nsh"

!define CLONUI_E_UNINSTALLER_COPY_OR_REBUILD_FAILED "E1001"
!define CLONUI_E_OLD_UNINSTALL_FAILED "E1002"
!define CLONUI_E_INSTALL_DIR_REMOVE_OR_LOCKED "E1003"
!define CLONUI_E_EXTRACT_FAILED "E1010"
!define CLONUI_E_DISK_INSUFFICIENT "E1020"
!define CLONUI_E_BUNDLED_AIONCORE_INCOMPLETE "E1030"
!define CLONUI_E_CORE_APP_FILES_INCOMPLETE "E1031"
!define CLONUI_E_ARCH_MISMATCH "E1040"
!define CLONUI_E_ACTIVE_INSTALLER_CONFLICT "E1050"
!define CLONUI_E_REGISTRY_STATE_INVALID "E1060"
!define CLONUI_E_ACTIVE_MARKER_WRITE_FAILED "E1070"
!define CLONUI_E_INVALID_INSTALL_PATH "E1090"

!macro CLONUI_FAIL_UX _CODE _DETAIL _MSG_ZH _MSG_EN _ACTION_ZH _ACTION_EN _DIAGNOSTICS_ZH _DIAGNOSTICS_EN
  !insertmacro CLONUI_SLOG "event=session-end result=fail code=${_CODE} detail=${_DETAIL}"
  Push $9
  ${If} ${Silent}
    StrCpy $9 "auto"
  ${Else}
    StrCpy $9 "yes"
    MessageBox MB_YESNO|MB_ICONSTOP \
      "${CLONUI_MSG_INSTALL_FAILED_ZH} (${_CODE})$\r$\n$\r$\n\
      ${_MSG_ZH}$\r$\n$\r$\n\
      ${CLONUI_MSG_SUGGESTED_ACTION_ZH}:$\r$\n${_ACTION_ZH}$\r$\n$\r$\n\
      ${CLONUI_MSG_DIAGNOSTICS_ZH}:$\r$\n${_DIAGNOSTICS_ZH}$\r$\n$\r$\n\
      ${CLONUI_MSG_INSTALLER_LOG_ZH}:$\r$\n$CLonUISessionLogPath$\r$\n$\r$\n\
      ${CLONUI_MSG_SEND_REPORT_ZH}$\r$\n$\r$\n\
      ${CLONUI_MSG_BLOCK_SEPARATOR}$\r$\n$\r$\n\
      ${CLONUI_MSG_INSTALL_FAILED_EN} (${_CODE})$\r$\n$\r$\n\
      ${_MSG_EN}$\r$\n$\r$\n\
      ${CLONUI_MSG_SUGGESTED_ACTION_EN}:$\r$\n${_ACTION_EN}$\r$\n$\r$\n\
      ${CLONUI_MSG_DIAGNOSTICS_EN}:$\r$\n${_DIAGNOSTICS_EN}$\r$\n$\r$\n\
      ${CLONUI_MSG_INSTALLER_LOG_EN}:$\r$\n$CLonUISessionLogPath$\r$\n$\r$\n\
      ${CLONUI_MSG_SEND_REPORT_EN}" \
      /SD IDNO IDNO +2
    Goto +2
    StrCpy $9 "no"
  ${EndIf}
  ${If} $9 == "no"
    !insertmacro CLONUI_SLOG "event=report-skipped reason=user-declined code=${_CODE}"
  ${ElseIf} $9 == "auto"
    !insertmacro CLONUI_SLOG "event=report-auto reason=silent code=${_CODE}"
    !insertmacro CLONUI_REPORT_TO_SENTRY_NOUI "${_CODE}" "${_DETAIL}"
  ${Else}
    !insertmacro CLONUI_REPORT_TO_SENTRY "${_CODE}" "${_DETAIL}"
  ${EndIf}
  Pop $9
  !insertmacro CLONUI_CLEAR_ACTIVE_INSTALLER_MARKER
  SetErrorLevel 2
  Quit
!macroend

!macro CLONUI_FAIL_REPORTABLE _CODE _DETAIL _MSG_EN _ACTION_EN
  !insertmacro CLONUI_FAIL_UX ${_CODE} "${_DETAIL}" "${CLONUI_MSG_GENERIC_FAILURE_ZH}" "${_MSG_EN}" "${CLONUI_MSG_GENERIC_ACTION_ZH}" "${_ACTION_EN}" "${_DETAIL}" "${_DETAIL}"
!macroend

!macro CLONUI_FAIL_REPORTABLE_ROOTED _ROOT_CODE _WRAPPER_CODE _DETAIL _MSG_EN _ACTION_EN
  !insertmacro CLONUI_FAIL_UX "${_ROOT_CODE}" "wrapperCode=${_WRAPPER_CODE} ${_DETAIL}" "${CLONUI_MSG_GENERIC_FAILURE_ZH}" "${_MSG_EN}" "${CLONUI_MSG_GENERIC_ACTION_ZH}" "${_ACTION_EN}" "${_DETAIL}" "${_DETAIL}"
!macroend

!macro CLONUI_FAIL_REPORTABLE_BILINGUAL _CODE _DETAIL _MSG_EN _MSG_ZH _ACTION_EN _ACTION_ZH
  !insertmacro CLONUI_FAIL_UX ${_CODE} "${_DETAIL}" "${_MSG_ZH}" "${_MSG_EN}" "${_ACTION_ZH}" "${_ACTION_EN}" "${_DETAIL}" "${_DETAIL}"
!macroend

!macro CLONUI_FAIL_REPORTABLE_ROOTED_BILINGUAL _ROOT_CODE _WRAPPER_CODE _DETAIL _MSG_EN _MSG_ZH _ACTION_EN _ACTION_ZH
  !insertmacro CLONUI_FAIL_UX "${_ROOT_CODE}" "wrapperCode=${_WRAPPER_CODE} ${_DETAIL}" "${_MSG_ZH}" "${_MSG_EN}" "${_ACTION_ZH}" "${_ACTION_EN}" "${_DETAIL}" "${_DETAIL}"
!macroend

!macro CLONUI_FAIL_REPORTABLE_BILINGUAL_DIAGNOSTICS _CODE _DETAIL _MSG_EN _MSG_ZH _ACTION_EN _ACTION_ZH _DIAGNOSTICS_EN _DIAGNOSTICS_ZH
  !insertmacro CLONUI_FAIL_UX ${_CODE} "${_DETAIL}" "${_MSG_ZH}" "${_MSG_EN}" "${_ACTION_ZH}" "${_ACTION_EN}" "${_DIAGNOSTICS_ZH}" "${_DIAGNOSTICS_EN}"
!macroend

!macro CLONUI_FAIL_REPORTABLE_ROOTED_BILINGUAL_DIAGNOSTICS _ROOT_CODE _WRAPPER_CODE _DETAIL _MSG_EN _MSG_ZH _ACTION_EN _ACTION_ZH _DIAGNOSTICS_EN _DIAGNOSTICS_ZH
  !insertmacro CLONUI_FAIL_UX "${_ROOT_CODE}" "wrapperCode=${_WRAPPER_CODE} ${_DETAIL}" "${_MSG_ZH}" "${_MSG_EN}" "${_ACTION_ZH}" "${_ACTION_EN}" "${_DIAGNOSTICS_ZH}" "${_DIAGNOSTICS_EN}"
!macroend

!macro CLONUI_REPORT_TO_SENTRY _CODE _DETAIL
  !insertmacro CLONUI_REPORT_TO_SENTRY_IMPL "${_CODE}" "${_DETAIL}" ""
!macroend

!macro CLONUI_REPORT_TO_SENTRY_NOUI _CODE _DETAIL
  !insertmacro CLONUI_REPORT_TO_SENTRY_IMPL "${_CODE}" "${_DETAIL}" "-NoUi"
!macroend

!macro CLONUI_REPORT_TO_SENTRY_IMPL _CODE _DETAIL _NO_UI
  Push $9
  InitPluginsDir
  File /oname=$PLUGINSDIR\clonui-report-installer-failure.ps1 "${PROJECT_DIR}\resources\windows\support\report-installer-failure.ps1"
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\clonui-report-installer-failure.ps1" -Dsn "${CLONUI_SENTRY_DSN}" -LogPath "$CLonUISessionLogPath" -Code "${_CODE}" -Detail "${_DETAIL}" -Release "${VERSION}" -Arch "${CLONUI_TARGET_ARCH}" -Session "$CLonUISessionId" -Updated "$CLonUIIsUpdated" ${_NO_UI}`
  Pop $9
  Pop $9
!macroend

!endif
