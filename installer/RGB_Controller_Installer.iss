[Setup]
AppName=RGB Controller
AppVersion=1.0
DefaultDirName={pf}\RGBController
OutputBaseFilename=RGBControllerSetup
PrivilegesRequired=admin
Compression=lzma
SolidCompression=yes

[Files]
Source: "RGB Controller.exe"; DestDir: "{app}"; Flags: ignoreversion

[Code]

const
  DevilZoneZipURL = 'https://powerdriver.s3.us-west-1.amazonaws.com/RGB/DevilZone_V122.zip';
  OpenRGBMSIURL  = 'https://openrgb.org/releases/release_candidate_1.0rc1/OpenRGB_1.0rc1_Windows_64_1fbacde.msi';



function RunPSFile(const PSPath: string): Boolean;
var
  ResultCode: Integer;
  Args: string;
begin
  Args := '-NoProfile -ExecutionPolicy Bypass -File "' + PSPath + '"';
  Result := Exec('powershell.exe', Args, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

function SavePS_DownloadExtract(const PSPath, Url, ZipPath, ExtractTo: string): Boolean;
var
  PSContent: string;
begin
  PSContent :=
    '$ErrorActionPreference = ''Stop'''+#13#10+
    'try {'+#13#10+
    '  if (Test-Path -LiteralPath "' + ExtractTo + '") {'+#13#10+
    '    Remove-Item -LiteralPath "' + ExtractTo + '" -Recurse -Force' +#13#10+
    '  }' +#13#10+
    '  Invoke-WebRequest -Uri "' + Url + '" -OutFile "' + ZipPath + '"' +#13#10+
    '  Expand-Archive -LiteralPath "' + ZipPath + '" -DestinationPath "' + ExtractTo + '" -Force' +#13#10+
    '  exit 0' +#13#10+
    '} catch {'+#13#10+
    '  Write-Error $_' +#13#10+
    '  exit 1' +#13#10+
    '}' +#13#10;

  Result := SaveStringToFile(PSPath, PSContent, False);
end;

function DownloadFile(const Url, Dest: string): Boolean; 
var
  PSPath, PSContent: string;
begin
  PSPath := ExpandConstant('{tmp}\download_file.ps1');
  PSContent :=
    '$ErrorActionPreference = ''Stop''' + #13#10 +
    'Invoke-WebRequest -Uri "' + Url + '" -OutFile "' + Dest + '"' + #13#10 +
    'exit 0';

  SaveStringToFile(PSPath, PSContent, False);

  Result := RunPSFile(PSPath);

  if FileExists(PSPath) then
    DeleteFile(PSPath);
end;

procedure TryRunMSIInstaller(const MSIPath: string); 
var
  ResultCode: Integer;
  Started: Boolean;
begin
  if not FileExists(MSIPath) then
  begin
    MsgBox('MSI Installer missing: ' + MSIPath, mbError, MB_OK);
    Exit;
  end;

  Started := Exec('msiexec.exe', '/i "' + MSIPath + '" /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if (not Started) or (ResultCode <> 0) then
  begin
    MsgBox('MSI Installer failed or returned non-zero: ' + MSIPath + #13#10 +
           'Exit code: ' + IntToStr(ResultCode) + #13#10 +
           'Please install manually if required.', mbError, MB_OK);
  end;
end;

procedure InstallFromMSI(const Name, MSIUrl: string); 
var
  TmpDir, MSIFile: string;
  ok: Boolean;
begin
  TmpDir := ExpandConstant('{tmp}');
  MSIFile := TmpDir + '\' + ExtractFileName(MSIUrl);

  ok := DownloadFile(MSIUrl, MSIFile);
  if not ok then
  begin
    MsgBox('Failed to download ' + Name + ' from: ' + MSIUrl, mbError, MB_OK);
    Exit;
  end;

  TryRunMSIInstaller(MSIFile);

  if FileExists(MSIFile) then
    DeleteFile(MSIFile);
end;


function DownloadAndExtract(const Name, Url, ZipPath, ExtractDir: string): Boolean;
var
  PSFile: string;
  ok: Boolean;
begin
  PSFile := ExpandConstant('{tmp}\download_extract_' + Name + '.ps1');

  if FileExists(PSFile) then
    DeleteFile(PSFile);

  ok := SavePS_DownloadExtract(PSFile, Url, ZipPath, ExtractDir);
  if not ok then
  begin
    MsgBox('Failed to write PowerShell script: ' + PSFile, mbError, MB_OK);
    Result := False;
    Exit;
  end;

  Result := RunPSFile(PSFile);

  if FileExists(PSFile) then
    DeleteFile(PSFile);
end;

procedure TryRunSilentInstaller(const InstallerPath: string);
var
  ResultCode: Integer;
  Started: Boolean;
begin
  if not FileExists(InstallerPath) then
  begin
    MsgBox('Installer missing: ' + InstallerPath, mbError, MB_OK);
    Exit;
  end;

  Started := Exec(InstallerPath, '/SILENT', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if (not Started) or (ResultCode <> 0) then
  begin
    Started := Exec(InstallerPath, '/S', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    if (not Started) or (ResultCode <> 0) then
    begin
      MsgBox('Installer failed or returned non-zero: ' + InstallerPath + #13#10 +
             'Exit code: ' + IntToStr(ResultCode) + #13#10 +
             'Please install manually if required.', mbError, MB_OK);
    end;
  end;
end;

function IsOpenRGBInstalled(): Boolean;
begin
  Result := DirExists('C:\Program Files\OpenRGB') or
            DirExists('C:\Program Files (x86)\OpenRGB') or
            FileExists('C:\Program Files\OpenRGB\OpenRGB.exe');
end;

function IsDevilZoneInstalled(): Boolean;
begin
  Result := DirExists('C:\Program Files (x86)\PowerColor DevilZone') or
            DirExists('C:\Program Files\PowerColor DevilZone');
end;

procedure InstallFromZip(const Name, Url, InstallerRelName: string);
var
  TmpDir, ZipFile, ExtractDir, InstallerPath: string;
  ok: Boolean;
begin
  TmpDir := ExpandConstant('{tmp}');
  ZipFile := TmpDir + '\' + ExtractFileName(Url);
  ExtractDir := TmpDir + '\' + Name;

  ok := DownloadAndExtract(Name, Url, ZipFile, ExtractDir);
  if not ok then
  begin
    MsgBox('Failed to download or extract ' + Name + ' from: ' + Url, mbError, MB_OK);
    Exit;
  end;

  InstallerPath := ExtractDir + '\' + InstallerRelName;
  if not FileExists(InstallerPath) then
  begin
    MsgBox('Expected installer not found inside archive: ' + InstallerPath, mbError, MB_OK);
    Exit;
  end;

  TryRunSilentInstaller(InstallerPath);

  if FileExists(ZipFile) then
    DeleteFile(ZipFile);
end;

procedure CreateScheduledTaskSafe(const TaskName, TaskExePath, TaskArgs: string);
var
  Cmd, TRPart: string;
  ResultCode: Integer;
begin
  Exec('schtasks.exe', '/Delete /TN "' + TaskName + '" /F', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  if TaskArgs = '' then
    TRPart := '"' + TaskExePath + '"'
  else
    TRPart := '"' + TaskExePath + '" ' + TaskArgs;

  Cmd := '/Create /SC ONLOGON /RL HIGHEST /TN "' + TaskName + '" /TR "' + TRPart + '"';
  Exec('schtasks.exe', Cmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function InitializeSetup(): Boolean;
var
  Response: Integer;
begin
  Result := True;

  if not IsOpenRGBInstalled() then
begin
  Response := MsgBox('OpenRGB not detected. Download and install now?', mbConfirmation, MB_YESNO);
  if Response = IDYES then
    InstallFromMSI('OpenRGB', OpenRGBMSIURL);
end;


  if not IsDevilZoneInstalled() then
  begin
    Response := MsgBox('PowerColor DevilZone not detected. Download and install now?', mbConfirmation, MB_YESNO);
    if Response = IDYES then
      InstallFromZip('DevilZone', DevilZoneZipURL, 'DevilZone_Installer_1.2.2.exe');
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    CreateScheduledTaskSafe('DevilZoneElevated', 'C:\Program Files (x86)\PowerColor DevilZone\DevilZone.exe', '');
    CreateScheduledTaskSafe('RunRGBController', ExpandConstant('{app}\RGB Controller.exe'), '');
  end;
end;
