!ifndef CLONUI_INSTALLER_OBSERVABILITY_NSH
!define CLONUI_INSTALLER_OBSERVABILITY_NSH

!define CLONUI_APP_EXECUTABLE_FILENAME "CLonUI.exe"
!define CLONUI_FALLBACK_LOG "clonui-installer-${VERSION}-fallback-log.jsonl"

!pragma warning disable 6001
Var /GLOBAL CLonUISessionId
Var /GLOBAL CLonUIIsUpdated
Var /GLOBAL CLonUISessionLogResult
Var /GLOBAL CLonUISessionLogPath

!macro CLONUI_SESSION_HEADER
  !insertmacro CLONUI_SLOG "event=header arch=${CLONUI_TARGET_ARCH} updated=$CLonUIIsUpdated instDir=$INSTDIR version=${VERSION} log=$CLonUISessionLogPath detail=customHeader"
!macroend

!macro CLONUI_SLOG _MESSAGE
  Push $9
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$CLonUISessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${CLONUI_FALLBACK_LOG}' }; \
    $$session = '$CLonUISessionId'; \
    if (-not $$session) { $$session = 'uninitialized' }; \
    $$message = '${_MESSAGE}'; \
    $$event = 'log'; \
    if ($$message -match '(^|\s)event=([^\s]+)') { $$event = $$Matches[2] } else { $$first = @($$message -split '\s+', 2)[0]; if ($$first -and $$first -notmatch '=') { $$event = $$first } }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = $$session; version = '${VERSION}'; arch = '${CLONUI_TARGET_ARCH}'; updated = ('$CLonUIIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = $$event; message = $$message }; \
    $$json = $$payload | ConvertTo-Json -Compress -Depth 8; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value $$json \
  }"`
  Pop $9
  Pop $9
!macroend

!macro CLONUI_LOG_EVENT _MESSAGE
  Push $9
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$CLonUISessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${CLONUI_FALLBACK_LOG}' }; \
    $$session = '$CLonUISessionId'; \
    if (-not $$session) { $$session = 'uninitialized' }; \
    $$message = '${_MESSAGE}'; \
    $$event = 'log'; \
    if ($$message -match '(^|\s)event=([^\s]+)') { $$event = $$Matches[2] } else { $$first = @($$message -split '\s+', 2)[0]; if ($$first -and $$first -notmatch '=') { $$event = $$first } }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = $$session; version = '${VERSION}'; arch = '${CLONUI_TARGET_ARCH}'; updated = ('$CLonUIIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = $$event; message = $$message }; \
    $$json = $$payload | ConvertTo-Json -Compress -Depth 8; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value $$json \
  }"`
  Pop $9
  Pop $9
!macroend

!macro CLONUI_LOG_JSON_EVENT _EVENT _JSON_FIELDS
  Push $9
  nsExec::Exec `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { \
    $$ErrorActionPreference = 'SilentlyContinue'; \
    $$log = '$CLonUISessionLogPath'; \
    if (-not $$log) { $$log = Join-Path $$env:TEMP '${CLONUI_FALLBACK_LOG}' }; \
    $$session = '$CLonUISessionId'; \
    if (-not $$session) { $$session = 'uninitialized' }; \
    $$payload = [ordered]@{ schemaVersion = 1; ts = (Get-Date -Format o); session = $$session; version = '${VERSION}'; arch = '${CLONUI_TARGET_ARCH}'; updated = ('$CLonUIIsUpdated' -eq '1'); instDir = '$INSTDIR'; event = '${_EVENT}' }; \
    ${_JSON_FIELDS}; \
    $$json = $$payload | ConvertTo-Json -Compress -Depth 8; \
    Add-Content -LiteralPath $$log -Encoding UTF8 -Value $$json \
  }"`
  Pop $9
  Pop $9
!macroend

!macro CLONUI_SESSION_BEGIN
  ${GetParameters} $R9
  ClearErrors
  ${GetOptions} $R9 "--installer-log=" $R8
  ${IfNot} ${Errors}
    StrCpy $CLonUISessionLogPath $R8
  ${EndIf}
  ClearErrors
  ${GetOptions} $R9 "--installer-session=" $R8
  ${IfNot} ${Errors}
    StrCpy $CLonUISessionId $R8
  ${EndIf}

  ${If} $CLonUISessionLogPath == ""
    nsExec::ExecToStack `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "$$id = '$CLonUISessionId'; if (-not $$id) { $$id = [guid]::NewGuid().ToString('N').Substring(0,12) }; $$stamp = Get-Date -Format 'yyyyMMdd'; $$name = 'clonui-installer-${VERSION}-' + $$stamp + '-log.jsonl'; $$log = Join-Path $$env:TEMP $$name; [Console]::Out.Write($$id + '|' + $$log)"`
    Pop $CLonUISessionLogResult
    Pop $CLonUISessionLogResult
    StrCpy $CLonUISessionId $CLonUISessionLogResult 12
    StrCpy $CLonUISessionLogPath $CLonUISessionLogResult 1024 13
  ${ElseIf} $CLonUISessionId == ""
    nsExec::ExecToStack `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "[Console]::Out.Write([guid]::NewGuid().ToString('N').Substring(0,12))"`
    Pop $CLonUISessionLogResult
    Pop $CLonUISessionLogResult
    StrCpy $CLonUISessionId $CLonUISessionLogResult
  ${EndIf}

  ClearErrors
  ${GetOptions} $R9 "--updated" $R8
  StrCpy $CLonUIIsUpdated "0"
  ${IfNot} ${Errors}
    StrCpy $CLonUIIsUpdated "1"
  ${EndIf}

  !insertmacro CLONUI_SLOG "event=session-begin detail=preInit"
!macroend

!macro CLONUI_LOG_EXTRACT_RESULT _METHOD
  ${IfNot} ${FileExists} "$INSTDIR\CLonUI.exe"
    !insertmacro CLONUI_FAIL_UX \
      "${CLONUI_E_EXTRACT_FAILED}" \
      "event=extract result=fail method=${_METHOD} missing=CLonUI.exe" \
      "${CLONUI_MSG_EXTRACT_FAILED_ZH}" \
      "${CLONUI_MSG_EXTRACT_FAILED_EN}" \
      "${CLONUI_MSG_EXTRACT_FAILED_ACTION_ZH}" \
      "${CLONUI_MSG_EXTRACT_FAILED_ACTION_EN}" \
      "extract result=fail method=${_METHOD} missing=CLonUI.exe instDir=$INSTDIR" \
      "extract result=fail method=${_METHOD} missing=CLonUI.exe instDir=$INSTDIR"
  ${Else}
    !insertmacro CLONUI_SLOG "event=extract result=ok method=${_METHOD} detail=customFiles_${CLONUI_TARGET_ARCH}"
  ${EndIf}
!macroend

!macro CLONUI_SESSION_SUCCESS
  !insertmacro CLONUI_SLOG "event=session-end result=success detail=customInstall"
!macroend

!endif
