[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Monitor Arduino
AppVersion=3.9
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
PrivilegesRequired=admin
OutputDir=Output
OutputBaseFilename=Instalador_Monitor_v3.9
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes

[Files]
; Pega todos os arquivos da pasta gerada pelo PyInstaller
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MonitorArduino"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\monitor.exe"; Description: "Iniciar Monitor"; Flags: nowait postinstall skipifsilent
