#Requires -Version 7.0
[CmdletBinding()]
param([string] $MetadataPath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if (-not $MetadataPath) { $MetadataPath = Join-Path $root 'release\codex_windows_installer_test_latest.json' }
$metadata = Get-Content -LiteralPath $MetadataPath -Raw | ConvertFrom-Json
if (-not $metadata.testIdentity -or -not $metadata.appId.StartsWith('xiaodongge.windows.codex-test-') -or
    -not $metadata.group.StartsWith('codex_xiaodongge_installer_')) { throw 'Only a -TestIdentity installer may be tested automatically.' }
$release = (Resolve-Path -LiteralPath (Join-Path $root 'release')).Path + '\'
$setup = (Resolve-Path -LiteralPath $metadata.setup).Path
if (-not $setup.StartsWith($release, [StringComparison]::OrdinalIgnoreCase) -or
    (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash -ne $metadata.sha256) { throw 'Test installer path or hash mismatch.' }
$qa = Join-Path $release ('codex_installer_qa_' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss_fff'))
$install = Join-Path $qa 'installed'
$profile = Join-Path $qa 'profile'
$shortcut = Join-Path ([Environment]::GetFolderPath('Programs')) ($metadata.group + '\小懂哥.lnk')
if (Test-Path -LiteralPath (Split-Path -Parent $shortcut)) { throw 'Test shortcut group already exists.' }
New-Item -ItemType Directory -Path $qa | Out-Null
$checks = [Collections.Generic.List[string]]::new()
$failure = $null
$uninstaller = $null

function Run-Installer([string] $File, [string[]] $Arguments) {
    $processInfo = [Diagnostics.ProcessStartInfo]::new()
    $processInfo.FileName = $File
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.WindowStyle = 'Hidden'
    foreach ($argument in $Arguments) { $processInfo.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::Start($processInfo)
    try {
        if (-not $process.WaitForExit(120000)) { throw 'Installer exceeded the 120-second limit; inspect the test process and log.' }
        if ($process.ExitCode -ne 0) { throw "Installer returned $($process.ExitCode): $File" }
    } finally { $process.Dispose() }
}

function Registration {
    @(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.PSObject.Properties['InstallLocation'] -and $_.InstallLocation.TrimEnd('\') -eq $install })
}

function Check-Payload {
    $manifest = Get-Content -LiteralPath (Join-Path $install 'codex_package_manifest.json') -Raw | ConvertFrom-Json
    foreach ($entry in $manifest.files) {
        $file = Join-Path $install $entry.path
        if ((Get-Item -LiteralPath $file).Length -ne $entry.bytes -or
            (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Installed payload differs: $($entry.path)" }
    }
    if ($metadata.signed) {
        foreach ($file in @((Join-Path $install 'codex_xiaodongge.exe'), $uninstaller)) {
            $signature = Get-AuthenticodeSignature -LiteralPath $file
            if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Thumbprint -ne $metadata.certificateThumbprint -or
                $null -eq $signature.TimeStamperCertificate) { throw 'Installed app or uninstaller signature mismatch.' }
        }
    }
}

$silent = @('/SP-', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NOCLOSEAPPLICATIONS', '/NORESTARTAPPLICATIONS', '/RESTARTEXITCODE=3010')
try {
    Run-Installer $setup ($silent + @("/DIR=$install", '/TASKS=', "/LOG=$(Join-Path $qa 'codex_install.log')"))
    $uninstaller = @(Get-ChildItem -LiteralPath $install -File | Where-Object { $_.Name -match '^unins\d+\.exe$' })[0].FullName
    Check-Payload
    if (@(Registration).Count -ne 1 -or -not (Test-Path -LiteralPath $shortcut)) { throw 'Per-user registration or Start Menu shortcut missing.' }
    $shell = New-Object -ComObject WScript.Shell
    if ($shell.CreateShortcut($shortcut).TargetPath -ne (Join-Path $install 'codex_xiaodongge.exe')) { throw 'Shortcut target mismatch.' }
    $checks.Add('per-user install, Start Menu shortcut, uninstall registration and installed file hashes')
    & node (Join-Path $PSScriptRoot 'codex_check_installed_app.mjs') (Join-Path $install 'codex_xiaodongge.exe') $profile write
    if ($LASTEXITCODE -ne 0) { throw 'Installed Electron write check failed.' }
    $checks.Add('installed Electron startup, isolated profile, synthetic SQLite and Chromium storage write')
    $sentinel = Join-Path $install 'codex_user_keep.txt'
    Set-Content -LiteralPath $sentinel -Value 'synthetic user file; uninstall must preserve this' -Encoding utf8
    Run-Installer $setup ($silent + @('/TASKS=', "/LOG=$(Join-Path $qa 'codex_upgrade.log')"))
    Check-Payload
    if (@(Registration).Count -ne 1) { throw 'Upgrade changed registration or install location.' }
    & node (Join-Path $PSScriptRoot 'codex_check_installed_app.mjs') (Join-Path $install 'codex_xiaodongge.exe') $profile read
    if ($LASTEXITCODE -ne 0) { throw 'Upgrade persistence check failed.' }
    $checks.Add('same-identity reinstall reuses location; SQLite and Chromium storage survive upgrade')
    $protected = @(Get-ChildItem -LiteralPath $profile -Recurse -File | ForEach-Object {
        [pscustomobject]@{ path = $_.FullName; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    })
    $protected += [pscustomobject]@{ path = $sentinel; sha256 = (Get-FileHash -LiteralPath $sentinel -Algorithm SHA256).Hash }
    $programFiles = @(Get-ChildItem -LiteralPath $install -Recurse -File | Where-Object { $_.FullName -ne $sentinel }).FullName
    Run-Installer $uninstaller @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=$(Join-Path $qa 'codex_uninstall.log')")
    $uninstaller = $null
    for ($attempt = 0; $attempt -lt 20 -and @($programFiles | Where-Object { Test-Path -LiteralPath $_ }).Count; $attempt++) {
        Start-Sleep -Milliseconds 250
    }
    if (@($programFiles | Where-Object { Test-Path -LiteralPath $_ }).Count) { throw 'Uninstall left tracked program files behind.' }
    if (@(Registration).Count -or (Test-Path -LiteralPath $shortcut) -or (Test-Path -LiteralPath (Join-Path $install 'codex_xiaodongge.exe'))) {
        throw 'Uninstall left program, registration or shortcut behind.'
    }
    foreach ($file in $protected) {
        if ((Get-FileHash -LiteralPath $file.path -Algorithm SHA256).Hash -ne $file.sha256) { throw 'Uninstall modified retained data.' }
    }
    $checks.Add('uninstall removes program, registration and shortcuts; profile and user-created file hashes unchanged')
} catch { $failure = $_.Exception.Message }
finally {
    if ($uninstaller -and (Test-Path -LiteralPath $uninstaller)) {
        try { Run-Installer $uninstaller @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') }
        catch { $failure = "$failure; isolated test uninstall failed: $($_.Exception.Message)" }
    }
    $result = [ordered]@{ passed = $null -eq $failure; checks = $checks.ToArray(); failure = $failure;
        signed = $metadata.signed; setupSha256 = $metadata.sha256; qa = $qa; appId = $metadata.appId }
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $qa 'codex_installer_checks.json') -Encoding utf8
    $result | ConvertTo-Json -Depth 6
}
if ($failure) { throw $failure }
