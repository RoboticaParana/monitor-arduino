[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Agente B1n0
AppVersion=4.9
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_B1n0_v4.9
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes

[Files]
; Instalamos com permissão de modificação para o aluno (necessário para log e update)
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Permissions: users-modify
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MonitorArduino"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Code]
// Função para matar o processo antes de desinstalar
function InitializeUninstall(): Boolean;
var
  ErrorCode: Integer;
begin
  ShellExec('open', 'taskkill.exe', '/f /im monitor.exe', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  Result := True;
end;

// Após desinstalar, garante que apenas o log fique
procedure CurUninstallStepChanged(UintStep: TUninstallStep);
begin
  if UintStep = usPostUninstall then
  begin
    // O Inno Setup já remove os arquivos registrados. 
    // Aqui garantimos que qualquer lixo ou o EXE temporário de update suma.
    DelTree(ExpandConstant('{app}\build'), True, True, True);
    // Não incluímos o log_arduino.txt no comando de deletar para que ele permaneça.
  end;
end;

[Run]
Filename: "{app}\monitor.exe"; Description: "Iniciar Agente B1n0"; Flags: nowait postinstall skipifsilent
