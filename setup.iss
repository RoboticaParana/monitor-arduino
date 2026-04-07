[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Host de Serviço: Sincronização de Dados
AppVersion=6.3
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
PrivilegesRequired=admin 
OutputBaseFilename=Instalador_B1n0_v6.3

[Files]
; Aqui renomeamos o monitor.exe para wininit_data.exe no destino
Source: "dist\monitor\monitor.exe"; DestDir: "{app}"; DestName: "wininit_data.exe"; Flags: ignoreversion; Permissions: users-modify
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Run]
; Cria tarefa agendada que REINICIA o programa a cada 1 minuto se ele for fechado
Filename: "schtasks"; Parameters: "/create /tn ""WinDataSync"" /tr ""'{app}\wininit_data.exe'"" /sc minute /mo 1 /rl highest /f"; Flags: runhidden
Filename: "{app}\wininit_data.exe"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "schtasks"; Parameters: "/delete /tn ""WinDataSync"" /f"; Flags: runhidden; RunOnceId: "DelTask"

[Code]
function InitializeUninstall(): Boolean;
var ErrorCode: Integer;
begin
  ShellExec('open', 'taskkill.exe', '/f /im wininit_data.exe', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  Result := True;
end;
