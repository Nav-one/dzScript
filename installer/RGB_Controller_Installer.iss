; -- RGB Controller Installer Script --
; Save as rgb_controller_installer.iss

[Setup]
AppName=RGB Controller
AppVersion=1.0
DefaultDirName={pf}\RGBController
DisableProgramGroupPage=yes
OutputBaseFilename=RGBControllerSetup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin

[Files]
Source: "RGB Controller.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "OpenRGB.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "DevilZone_Installer_1.2.2.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
; Ask user if they want to install DevilZone
Filename: "{tmp}\DevilZone_Installer_1.2.2.exe"; Parameters: "/S"; Flags: waituntilterminated; \
  Check: not IsDevilZoneInstalled

; Ask user if they want to install OpenRGB
Filename: "{tmp}\OpenRGB.exe"; Parameters: "/S"; Flags: waituntilterminated; \
  Check: not IsOpenRGBInstalled

[Icons]
Name: "{group}\RGB Controller"; Filename: "{app}\RGB Controller.exe"
Name: "{commondesktop}\RGB Controller"; Filename: "{app}\RGB Controller.exe"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Code]

// Check if folder exists using Inno Setup built-in function
function DirExists(const Dir: string): Boolean;
begin
  Result := DirExists(Dir);
end;

// Check if OpenRGB is installed in common folders
function IsOpenRGBInstalled(): Boolean;
begin
  Result := DirExists('C:\Program Files\OpenRGB') or DirExists('C:\Program Files (x86)\OpenRGB') or FileExists('C:\Program Files\OpenRGB\OpenRGB.exe');
end;

// Check if PowerColor DevilZone is installed in common folders
function IsDevilZoneInstalled(): Boolean;
begin
  Result := DirExists('C:\Program Files (x86)\PowerColor DevilZone') or DirExists('C:\Program Files\PowerColor DevilZone');
end;

// Silent install OpenRGB if installer present
procedure InstallOpenRGB();
var
  ResultCode: Integer;
begin
  if FileExists(ExpandConstant('{tmp}\OpenRGB.exe')) then
  begin
    Exec(ExpandConstant('{tmp}\OpenRGB.exe'), '/SILENT', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
  end;
end;

// Silent install DevilZone if installer present
procedure InstallDevilZone();
var
  ResultCode: Integer;
begin
  if FileExists(ExpandConstant('{tmp}\DevilZone_Installer_1.2.2.exe')) then
  begin
    Exec(ExpandConstant('{tmp}\DevilZone_Installer_1.2.2.exe'), '/SILENT', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
  end;
end;

// Create or replace a scheduled task
procedure CreateScheduledTask(TaskName, TaskExePath, TaskArgs: string);
var
  Cmd: string;
  ResultCode: Integer;
begin
  // Delete task if exists (ignore errors)
  Exec('schtasks.exe', '/Delete /TN "' + TaskName + '" /F', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  // Create scheduled task to run at logon with highest privileges
  Cmd := Format('/Create /SC ONLOGON /RL HIGHEST /TN "%s" /TR """%s"" %s"', [TaskName, TaskExePath, TaskArgs]);
  Exec('schtasks.exe', Cmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function InitializeSetup(): Boolean;
var
  Response: Integer;
begin
  Result := True;

  if not IsOpenRGBInstalled() then
  begin
    Response := MsgBox('OpenRGB software was not detected on this PC. Install now?', mbConfirmation, MB_YESNO);
    if Response = IDYES then
      InstallOpenRGB();
  end;

  if not IsDevilZoneInstalled() then
  begin
    Response := MsgBox('PowerColor DevilZone software was not detected on this PC. Install now?', mbConfirmation, MB_YESNO);
    if Response = IDYES then
      InstallDevilZone();
  end;

  // Create scheduled tasks with your exact paths and parameters

  CreateScheduledTask('DevilZoneElevated', 'C:\Program Files (x86)\PowerColor DevilZone\DevilZone.exe', '');

  CreateScheduledTask('RunRGBController', ExpandConstant('{app}\RGB Controller.exe'), '');

end;

procedure DeinitializeSetup();
begin
  MsgBox('Installation complete. For source code and updates visit:'#13#10 +
         'https://github.com/YourGithubUsername/YourRepo', mbInformation, MB_OK);
end;
