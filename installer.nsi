!include "MUI2.nsh"

Name "Nexus App Hub"
OutFile "NexusAppHub_v0.3.12_Installer.exe"
InstallDir "$LOCALAPPDATA\Programs\NexusAppHub"
InstallDirRegKey HKCU "Software\NexusAppHub" "Install_Dir"
RequestExecutionLevel user
SetCompressor /SOLID lzma

; Interface Minimalista
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Portuguese"

Section "Nexus App Hub"
    SectionIn RO
    
    SetOutPath "$INSTDIR"
    File /r "build\windows\x64\runner\Release\*.*"
    File "assets\app.ico"
    
    ; Uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; Atalhos
    CreateDirectory "$SMPROGRAMS\Nexus App Hub"
    CreateShortcut "$SMPROGRAMS\Nexus App Hub\Nexus App Hub.lnk" "$INSTDIR\NexusAppHub.exe" "" "$INSTDIR\app.ico" 0
    CreateShortcut "$SMPROGRAMS\Nexus App Hub\Desinstalar.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
    CreateShortcut "$DESKTOP\Nexus App Hub.lnk" "$INSTDIR\NexusAppHub.exe" "" "$INSTDIR\app.ico" 0
    
    ; Registro do Windows (Adicionar ou Remover Programas com suporte a Silent)
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "DisplayName" "Nexus App Hub"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "DisplayVersion" "0.3.12"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "Publisher" "Antigravity Ecosystem"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "DisplayIcon" "$INSTDIR\app.ico"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "QuietUninstallString" '"$INSTDIR\Uninstall.exe" /S'
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "InstallLocation" "$INSTDIR"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub" "NoRepair" 1
SectionEnd

Section "Uninstall"
    Delete "$DESKTOP\Nexus App Hub.lnk"
    Delete "$SMPROGRAMS\Nexus App Hub\Nexus App Hub.lnk"
    Delete "$SMPROGRAMS\Nexus App Hub\Desinstalar.lnk"
    RMDir "$SMPROGRAMS\Nexus App Hub"
    
    RMDir /r "$INSTDIR\data"
    Delete "$INSTDIR\*.*"
    RMDir "$INSTDIR"
    
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\NexusAppHub"
    DeleteRegKey HKCU "Software\NexusAppHub"
SectionEnd