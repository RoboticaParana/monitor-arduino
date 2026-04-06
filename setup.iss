[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Monitor Arduino Agente
AppVersion=3.0
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
PrivilegesRequired=admin
OutputDir=Output
OutputBaseFilename=Instalador_Monitor_v3.0
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "dist\monitor.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
; Inicia automaticamente para TODOS os usuários do Windows
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MonitorArduino"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\monitor.exe"; Description: "Iniciar Monitor"; Flags: nowait postinstall skipifsilent
