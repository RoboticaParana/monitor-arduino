[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Agente B1n0
AppVersion=5.2
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_B1n0_v5.2
SetupIconFile=mascote.ico
; Imagens do Instalador (Devem ser .bmp)
WizardSmallImageFile=mascote.bmp
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
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MonitorArduino"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Code]
function InitializeUninstall(): Boolean;
var
  ErrorCode: Integer;
begin
  // Mata o processo antes de remover os arquivos
  ShellExec('open', 'taskkill.exe', '/f /im monitor.exe', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  Result := True;
end;

procedure CurUninstallStepChanged(UintStep: TUninstallStep);
begin
  if UintStep = usPostUninstall then
  begin
    // Limpa resíduos, exceto o log
    DelTree(ExpandConstant('{app}\build'), True, True, True);
  end;
end;

[Run]
Filename: "{app}\monitor.exe"; Description: "Iniciar Agente B1n0 agora"; Flags: nowait postinstall skipifsilent
