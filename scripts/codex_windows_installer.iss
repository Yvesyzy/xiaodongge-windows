; Inputs are supplied by codex_build_windows_installer.ps1 after manifest verification.
[Setup]
AppId={#CODEX_APP_ID}
AppName=小懂哥
AppVersion={#CODEX_VERSION}
AppPublisher=Yves
AppPublisherURL=https://github.com/Yvesyzy/xiaodongge-windows
AppSupportURL=https://github.com/Yvesyzy/xiaodongge-windows/issues
AppUpdatesURL=https://github.com/Yvesyzy/xiaodongge-windows/releases
DefaultDirName={localappdata}\Programs\xiaodongge-windows
DefaultGroupName={#CODEX_GROUP}
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\codex_xiaodongge.exe
OutputDir={#CODEX_OUTPUT}
OutputBaseFilename={#CODEX_FILENAME}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
#ifdef CODEX_SIGNED
SignTool=codex_windows_sign
SignedUninstaller=yes
SignedUninstallerDir={#CODEX_OUTPUT}\codex_signed_uninstaller
#else
SignedUninstaller=no
#endif

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#CODEX_SOURCE}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\小懂哥"; Filename: "{app}\codex_xiaodongge.exe"; WorkingDir: "{app}"; AppUserModelID: "xiaodongge.windows"
Name: "{autodesktop}\小懂哥"; Filename: "{app}\codex_xiaodongge.exe"; WorkingDir: "{app}"; Tasks: desktopicon; AppUserModelID: "xiaodongge.windows"

[Run]
Filename: "{app}\codex_xiaodongge.exe"; Description: "{cm:LaunchProgram,小懂哥}"; Flags: nowait postinstall skipifsilent
