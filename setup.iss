[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Monitor Arduino Agente
AppVersion=4.5
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_Monitor_v4.5
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes

[Files]
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Permissions: users-modify
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MonitorArduino"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\monitor.exe"; Description: "Iniciar Agente"; Flags: nowait postinstall skipifsilent
