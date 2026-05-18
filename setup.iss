[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Agente B1n0
AppVersion=7.4.17
DefaultDirName={localappdata}\AgenteB1n0
DisableDirPage=yes
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=Instalador_AgenteB1n0_v7.4.17
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes

[Files]
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "dist\manager\manager.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\manager\_internal\*"; DestDir: "{app}\_internal"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "AgenteB1n0Manager"; ValueData: """{app}\manager.exe"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\manager.exe"; Description: "Iniciar Agente B1n0"; Flags: nowait postinstall skipifsilent
[UninstallRun]
Filename: "taskkill"; Parameters: "/f /im monitor.exe"; Flags: runhidden; RunOnceId: "StopMonitor"
Filename: "taskkill"; Parameters: "/f /im manager.exe"; Flags: runhidden; RunOnceId: "StopManager"
