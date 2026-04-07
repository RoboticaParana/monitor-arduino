[Setup]
AppId={{8B32145A-7C21-4E6E-A52D-1234567890ABC}
AppName=Agente B1n0
AppVersion=5.0
DefaultDirName=C:\ProgramData\MonitorArduino
DisableDirPage=yes
PrivilegesRequired=admin 
OutputDir=Output
OutputBaseFilename=Instalador_B1n0_v5.0
SetupIconFile=mascote.ico
Compression=lzma
SolidCompression=yes
; Idioma do Instalador
LanguageDetectionMethod=uilanguage
; Visual Moderno (Cores harmonizadas)
WizardStyle=modern
WizardSmallImageFile=mascote.ico

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "dist\monitor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Permissions: users-modify
Source: "mascote.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MonitorArduino"; ValueData: """{app}\monitor.exe"""; Flags: uninsdeletevalue

[Code]
function InitializeUninstall(): Boolean;
var
  ErrorCode: Integer;
begin
  // Mata o processo de forma silenciosa antes de remover arquivos
  ShellExec('open', 'taskkill.exe', '/f /im monitor.exe', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  Result := True;
end;

procedure CurUninstallStepChanged(UintStep: TUninstallStep);
begin
  if UintStep = usPostUninstall then
  begin
    // Limpa arquivos temporários mas preserva o log_arduino.txt
    DelTree(ExpandConstant('{app}\build'), True, True, True);
  end;
end;

[Run]
Filename: "{app}\monitor.exe"; Description: "Iniciar Agente B1n0 agora"; Flags: nowait postinstall skipifsilent
