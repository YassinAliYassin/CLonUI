; ARM64 architecture entry for the NSIS installer.

!include "x64.nsh"

!define CLONUI_TARGET_ARCH "arm64"
!define CLONUI_RUNTIME_KEY "win32-arm64"
!define CLONUI_EXTRACT_METHOD "zip"

!addincludedir "${PROJECT_DIR}\resources\windows"
!include "installer-common.nsh"

!macro customHeader
  !insertmacro CLONUI_INSTALLER_CUSTOM_HEADER
!macroend

!macro preInit
  !insertmacro CLONUI_INSTALLER_PREINIT
!macroend

!macro customFiles_arm64
  !insertmacro CLONUI_LOG_EXTRACT_RESULT "zip"
!macroend

; Architecture guard. Inserted from CLONUI_INSTALLER_PREINIT (preInit) so it runs before any
; registry mutation, replacing the old .onVerifyInstDir placement which fired after customInit
; had already healed/cleared/repaired an existing install's registry. (Sentry ELECTRON-3BX)
!macro CLONUI_ASSERT_TARGET_ARCH
  Var /GLOBAL CLonUIActualArch
  ${IfNot} ${IsNativeARM64}
    !insertmacro CLONUI_DETECT_NATIVE_ARCH $CLonUIActualArch
    !insertmacro CLONUI_FAIL_UX \
      "${CLONUI_E_ARCH_MISMATCH}" \
      "target=arm64 actual=$CLonUIActualArch" \
      "${CLONUI_MSG_ARCH_MISMATCH_ZH}" \
      "${CLONUI_MSG_ARCH_MISMATCH_EN}" \
      "${CLONUI_MSG_ARCH_MISMATCH_ACTION_ZH}" \
      "${CLONUI_MSG_ARCH_MISMATCH_ACTION_EN}" \
      "target=arm64 actual=$CLonUIActualArch" \
      "target=arm64 actual=$CLonUIActualArch"
  ${EndIf}
!macroend
