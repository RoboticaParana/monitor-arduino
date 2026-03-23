[Setup]
AppName=Monitor Arduino
AppVersion=2.0
DefaultDirName={commonappdata}\RoboticsMonitor
OutputBaseFilename=Instalador_Monitor
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
SetupIconFile=mascote.ico

[Dirs]
Name: "{commonappdata}\RoboticsMonitor"; Permissions: users-modify

[Files]
Source: "dist\monitor.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "mascote.png"; DestDir: "{app}"

[Icons]
Name: "{commonstartup}\Monitor Arduino"; Filename: "{app}\monitor.exe"

[Run]
Filename: "{app}\monitor.exe"; Flags: nowait postinstall

[Code]
procedure KillProcess();
var
  ResultCode: Integer;
begin
  Exec('taskkill', '/IM monitor.exe /F', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    KillProcess();
end;