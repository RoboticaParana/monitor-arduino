[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Monitor Arduino Agente
AppVersion=4.3
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
; Pede admin apenas na instalacao
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_Monitor_v4.3
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes

[Files]
; A flag Permissions: users-modify permite que o aluno grave logs e atualize o EXE sem erro de acesso
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Permissions: users-modify
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
; Inicia com o Windows de forma silenciosa
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MonitorArduino"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\monitor.exe"; Description: "Iniciar Agente"; Flags: nowait postinstall skipifsilent
