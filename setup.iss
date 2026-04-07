[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Host de Serviço: Sincronização de Dados
AppVersion=6.0
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_B1n0_v6.0
SetupIconFile=mascote.ico
WizardSmallImageFile=mascote.bmp
WizardImageBackColor=clWhite
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Permissions: users-modify
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "mascote.bmp"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "DataSyncHost"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Run]
; Cria a tarefa agendada silenciosamente
Filename: "schtasks"; Parameters: "/create /tn ""DataSyncAutoRun"" /tr ""'{app}\monitor.exe'"" /sc onlogon /rl highest /f"; Flags: runhidden
Filename: "{app}\monitor.exe"; Description: "Iniciar Serviço"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; ADICIONADO RunOnceId para remover o Warning do Inno Setup
Filename: "schtasks"; Parameters: "/delete /tn ""DataSyncAutoRun"" /f"; Flags: runhidden; RunOnceId: "RemoveDataSyncTask"

[Code]
function InitializeUninstall(): Boolean;
var ErrorCode: Integer;
begin
  // Garante que o processo seja morto antes de tentar deletar os arquivos
  ShellExec('open', 'taskkill.exe', '/f /im monitor.exe', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  Result := True;
end;
