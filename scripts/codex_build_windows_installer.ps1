#Requires -Version 7.0
[CmdletBinding()]
param(
    [string] $SourceFolder,
    [string] $CompilerPath,
    [string] $SignToolPath,
    [ValidatePattern('^[A-Fa-f0-9]{40}$')] [string] $CertificateThumbprint,
    [ValidateSet('CurrentUser', 'LocalMachine')] [string] $CertificateStore = 'CurrentUser',
    [switch] $AllowUnsigned,
    [switch] $TestIdentity
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if (-not $IsWindows -or [Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne 'X64') {
    throw 'Build on Windows x64 with PowerShell 7.'
}
if ($AllowUnsigned -and $CertificateThumbprint) { throw 'Choose a certificate or -AllowUnsigned, not both.' }
if (-not $AllowUnsigned -and -not $CertificateThumbprint) {
    throw 'A trusted code-signing certificate thumbprint is required. Use -AllowUnsigned explicitly for an unsigned installer.'
}
if (-not $SourceFolder) {
    $SourceFolder = (Get-Content -LiteralPath (Join-Path $root 'release\codex_windows_latest.json') -Raw | ConvertFrom-Json).folder
}
$SourceFolder = (Resolve-Path -LiteralPath $SourceFolder).Path
$manifestPath = Join-Path $SourceFolder 'codex_package_manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$package = Get-Content -LiteralPath (Join-Path $root 'package.json') -Raw | ConvertFrom-Json
if ($manifest.version -ne $package.version -or $manifest.executable -ne 'codex_xiaodongge.exe' -or
    $manifest.userDataIdentity -ne 'xiaodongge-windows') { throw 'Portable package identity or version mismatch.' }
$inventory = @(Get-ChildItem -LiteralPath $SourceFolder -Recurse -Force)
if ((Get-Item -LiteralPath $SourceFolder).Attributes -band [IO.FileAttributes]::ReparsePoint -or
    @($inventory | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
    throw 'Package must not contain filesystem links.'
}
$prefix = $SourceFolder.TrimEnd('\') + '\'
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $manifest.files) {
    $file = [IO.Path]::GetFullPath((Join-Path $SourceFolder $entry.path))
    if (-not $file.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($file)) {
        throw 'Invalid or duplicate package path.'
    }
    if ((Get-Item -LiteralPath $file).Length -ne $entry.bytes -or
        (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Package integrity failed: $($entry.path)" }
}
if ($seen.Count -ne $manifest.fileCount -or @($inventory | Where-Object { -not $_.PSIsContainer }).Count -ne $seen.Count + 1) {
    throw 'Package inventory mismatch.'
}
if (-not $seen.Contains((Join-Path $SourceFolder $manifest.executable))) { throw 'Application executable is missing from the manifest.' }
if (-not $CompilerPath) {
    $compiler = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($compiler) { $CompilerPath = $compiler.Source }
    else {
        $installed = @(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
            Where-Object { $_.PSObject.Properties['DisplayName'] -and $_.DisplayName -like 'Inno Setup 7*' })
        if ($installed.Count) { $CompilerPath = Join-Path $installed[0].InstallLocation 'ISCC.exe' }
    }
}
if (-not $CompilerPath -or -not (Test-Path -LiteralPath $CompilerPath -PathType Leaf)) { throw 'Install Inno Setup 7, or supply -CompilerPath.' }
$CompilerPath = (Resolve-Path -LiteralPath $CompilerPath).Path
$compilerSignature = Get-AuthenticodeSignature -LiteralPath $CompilerPath
if ($compilerSignature.Status -ne 'Valid') { throw 'Inno Setup compiler must have a valid trusted signature.' }

function Assert-Signature([string] $File) {
    & $SignToolPath verify /pa /all /tw $File
    if ($LASTEXITCODE -ne 0) { throw "Signature verification failed: $File" }
    $signature = Get-AuthenticodeSignature -LiteralPath $File
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Thumbprint -ne $CertificateThumbprint -or
        $null -eq $signature.TimeStamperCertificate) { throw "Publisher, trust or timestamp verification failed: $File" }
}

if (-not $AllowUnsigned) {
    $certificate = Get-Item -LiteralPath "Cert:\$CertificateStore\My\$CertificateThumbprint"
    $codeSigning = @($certificate.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.37' } |
        ForEach-Object { $_.EnhancedKeyUsages } | Where-Object { $_.Value -eq '1.3.6.1.5.5.7.3.3' }).Count
    if (-not $certificate.HasPrivateKey -or -not $codeSigning -or $certificate.NotAfter -le (Get-Date) -or
        $certificate.NotBefore -gt (Get-Date)) { throw 'Certificate needs a private key, code-signing usage and current validity.' }
    if (-not $SignToolPath) {
        $sdk = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots'
        $versions = Get-ChildItem -LiteralPath (Join-Path $sdk.KitsRoot10 'bin') -Directory |
            Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } | Sort-Object { [version] $_.Name } -Descending
        foreach ($sdkVersion in $versions) {
            $tool = Join-Path $sdkVersion.FullName 'x64\signtool.exe'
            if (Test-Path -LiteralPath $tool -PathType Leaf) { $SignToolPath = $tool; break }
        }
    }
    if (-not $SignToolPath -or (Get-AuthenticodeSignature -LiteralPath $SignToolPath).Status -ne 'Valid') {
        throw 'A trusted Windows SDK signtool.exe is required.'
    }
    $SignToolPath = (Resolve-Path -LiteralPath $SignToolPath).Path
}
$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss_fff')
$mode = if ($AllowUnsigned) { 'unsigned' } else { 'signed' }
$name = "codex_xiaodongge_windows_$($package.version)_x64_setup_${mode}_$stamp"
$output = Join-Path $root "release\$name"
New-Item -ItemType Directory -Path $output | Out-Null
$appId = 'xiaodongge.windows'
$group = '小懂哥'
if ($TestIdentity) { $appId += ".codex-test-$stamp"; $group = "codex_xiaodongge_installer_$stamp" }
$payload = Join-Path $output 'codex_payload'
Copy-Item -LiteralPath $SourceFolder -Destination $payload -Recurse
Copy-Item -LiteralPath (Join-Path $root 'desktop\codex_README.md') -Destination (Join-Path $payload 'codex_使用说明.md') -Force
$changedFiles = @('codex_使用说明.md')
$compilerArgs = @('/Qp', "/DCODEX_VERSION=$($package.version)", "/DCODEX_APP_ID=$appId", "/DCODEX_GROUP=$group",
    "/DCODEX_OUTPUT=$output", "/DCODEX_FILENAME=$name")
if (-not $AllowUnsigned) {
    $signArgs = @('sign', '/sha1', $CertificateThumbprint, '/fd', 'SHA256', '/tr', 'http://timestamp.digicert.com', '/td', 'SHA256')
    $storeFlag = ''
    if ($CertificateStore -eq 'LocalMachine') { $signArgs += '/sm'; $storeFlag = ' /sm' }
    $exe = Join-Path $payload $manifest.executable
    & $SignToolPath @signArgs $exe
    if ($LASTEXITCODE -ne 0) { throw 'Application signing failed.' }
    Assert-Signature $exe
    $changedFiles += $manifest.executable
    $signCommand = '/Scodex_windows_sign=$q' + $SignToolPath.Replace('$', '$$') + '$q sign /sha1 ' +
        $CertificateThumbprint + $storeFlag + ' /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $f'
    $compilerArgs += @('/DCODEX_SIGNED=1', $signCommand)
}
foreach ($changedFile in $changedFiles) {
    $entry = @($manifest.files | Where-Object { $_.path -eq $changedFile })
    if ($entry.Count -ne 1) { throw "Manifest entry missing: $changedFile" }
    $entry[0].bytes = (Get-Item -LiteralPath (Join-Path $payload $changedFile)).Length
    $entry[0].sha256 = (Get-FileHash -LiteralPath (Join-Path $payload $changedFile) -Algorithm SHA256).Hash.ToLowerInvariant()
}
$manifest.bytes = ($manifest.files | Measure-Object -Property bytes -Sum).Sum
$manifest.createdAt = (Get-Date).ToUniversalTime().ToString('o')
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $payload 'codex_package_manifest.json') -Encoding utf8
$compilerArgs += @("/DCODEX_SOURCE=$payload", (Join-Path $PSScriptRoot 'codex_windows_installer.iss'))
& $CompilerPath @compilerArgs
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }
$setup = Join-Path $output "$name.exe"
if (-not $AllowUnsigned) {
    Assert-Signature $setup
    $uninstallers = @(Get-ChildItem -LiteralPath (Join-Path $output 'codex_signed_uninstaller') -File)
    if (-not $uninstallers.Count) { throw 'Signed uninstaller was not produced.' }
    foreach ($uninstaller in $uninstallers) { Assert-Signature $uninstaller.FullName }
}
$sha256 = (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$setup.sha256.txt" -Value "$sha256  $name.exe" -Encoding utf8
$result = [ordered]@{ version = $package.version; setup = $setup; bytes = (Get-Item -LiteralPath $setup).Length;
    sha256 = $sha256; signed = -not [bool]$AllowUnsigned; certificateThumbprint = $CertificateThumbprint;
    appId = $appId; group = $group; testIdentity = [bool]$TestIdentity; source = $SourceFolder;
    sourceManifestSha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant();
    verifiedFiles = $seen.Count; compilerFileVersion = (Get-Item -LiteralPath $CompilerPath).VersionInfo.FileVersion;
    compilerSha256 = (Get-FileHash -LiteralPath $CompilerPath -Algorithm SHA256).Hash.ToLowerInvariant() }
$metadataName = if ($TestIdentity) { 'codex_windows_installer_test_latest.json' } else { 'codex_windows_installer_latest.json' }
$json = $result | ConvertTo-Json -Depth 6
$json | Set-Content -LiteralPath (Join-Path $root "release\$metadataName") -Encoding utf8
$json | Set-Content -LiteralPath (Join-Path $output 'codex_installer_manifest.json') -Encoding utf8
Write-Output $json
