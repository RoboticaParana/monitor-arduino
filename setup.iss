[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Agente B1n0
AppVersion=7.2
DefaultDirName={commonpf}\AgenteB1n0
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_AgenteB1n0_v7.2
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "dist\monitor\monitor.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "AgenteB1n0"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Run]
Filename: "{app}\monitor.exe"; Description: "Iniciar Agente B1n0"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "taskkill"; Parameters: "/f /im monitor.exe"; Flags: runhidden; RunOnceId: "StopB1n0_v7"