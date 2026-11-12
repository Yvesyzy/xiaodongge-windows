[CmdletBinding()]
param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $projectRoot ('release\codex_windows_cover_native_' + [DateTimeOffset]::Now.ToUnixTimeMilliseconds())
}
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $outputRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Artwork test output must be inside this project'
}
[void](New-Item -ItemType Directory -Path $outputRoot -Force)
$nativePath = Join-Path $projectRoot 'desktop\native\codex_windows_native.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($nativePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ('Invalid native PowerShell source: ' + ($parseErrors | Out-String)) }
$definitions = $ast.EndBlock.Statements | Where-Object { $_ -isnot [System.Management.Automation.Language.TryStatementAst] }
. ([scriptblock]::Create(($definitions | ForEach-Object { $_.Extent.Text }) -join "`n"))
Add-Type -AssemblyName System.Drawing
Add-Type 'public sealed class CodexArtworkMedia { public object Thumbnail { get; set; } }'
$types = Initialize-NativeTypes
$referenceType = Get-WinRtType 'Windows.Storage.Streams.RandomAccessStreamReference, Windows, ContentType=WindowsRuntime'
$checks = New-Object 'System.Collections.Generic.List[string]'
$hashEvidence = New-Object 'System.Collections.Generic.List[object]'
function Get-ByteHash([byte[]]$Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Assert-Artwork([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    [void]$checks.Add($Message)
}
function Read-FixtureArtwork([string]$Path) {
    $file = Await-WinRt ($types.StorageFile::GetFileFromPathAsync($Path)) $types.StorageFile
    $media = New-Object CodexArtworkMedia
    $media.Thumbnail = $referenceType::CreateFromFile($file)
    $result = Get-PlaybackArtwork $media $types
    if ($null -ne $result) {
        $originalHash = Get-ByteHash ([IO.File]::ReadAllBytes($Path))
        $returnedHash = Get-ByteHash ([Convert]::FromBase64String($result.Substring($result.IndexOf(',') + 1)))
        [void]$hashEvidence.Add([ordered]@{ file=[IO.Path]::GetFileName($Path);
            originalSha256=$originalHash; returnedSha256=$returnedHash; equal=($originalHash -ceq $returnedHash) })
    }
    return $result
}
function Write-FixtureImage([string]$Path, [int]$Width, [int]$Height, [Drawing.Imaging.ImageFormat]$Format = [Drawing.Imaging.ImageFormat]::Png) {
    $fixture = New-Object Drawing.Bitmap($Width, $Height)
    $drawing = [Drawing.Graphics]::FromImage($fixture)
    try {
        $drawing.Clear([Drawing.Color]::Transparent)
        $drawing.FillRectangle([Drawing.Brushes]::Teal, 0, 0, [int]($Width / 2), $Height)
        $fixture.Save($Path, $Format)
    } finally { $drawing.Dispose(); $fixture.Dispose() }
}
$fixturePath = Join-Path $outputRoot 'codex_synthetic_thumbnail.png'
Write-FixtureImage $fixturePath 768 384
$cover = Read-FixtureArtwork $fixturePath
Assert-Artwork ($cover -is [string] -and $cover.StartsWith('data:image/png;base64,')) 'Real WinRT reference preserves PNG format'
$bytes = [Convert]::FromBase64String($cover.Substring($cover.IndexOf(',') + 1))
$encoded = New-Object IO.MemoryStream(,$bytes)
$decoded = [Drawing.Image]::FromStream($encoded)
try {
    Assert-Artwork ($decoded.Width -eq 768 -and $decoded.Height -eq 384) 'Original 768 x 384 dimensions are preserved'
    Assert-Artwork ([Convert]::ToBase64String($bytes) -ceq [Convert]::ToBase64String([IO.File]::ReadAllBytes($fixturePath))) 'Original PNG bytes and transparency are preserved exactly'
} finally { $decoded.Dispose(); $encoded.Dispose() }
foreach ($format in @([Drawing.Imaging.ImageFormat]::Jpeg, [Drawing.Imaging.ImageFormat]::Bmp, [Drawing.Imaging.ImageFormat]::Gif)) {
    $formatPath = Join-Path $outputRoot ('codex_original_' + $format.ToString().ToLowerInvariant() + '.img')
    Write-FixtureImage $formatPath 1024 640 $format
    $rawCover = Read-FixtureArtwork $formatPath
    Assert-Artwork ($null -ne $rawCover) ('Valid original ' + $format + ' is readable')
    $rawBytes = [Convert]::FromBase64String($rawCover.Substring($rawCover.IndexOf(',') + 1))
    Assert-Artwork ([Convert]::ToBase64String($rawBytes) -ceq [Convert]::ToBase64String([IO.File]::ReadAllBytes($formatPath))) ('Original ' + $format + ' bytes are preserved exactly')
}
$noThumbnail = New-Object CodexArtworkMedia
Assert-Artwork ($null -eq (Get-PlaybackArtwork $noThumbnail $types)) 'Absent thumbnail returns no artwork'
$badPath = Join-Path $outputRoot 'codex_invalid_thumbnail.png'
[IO.File]::WriteAllBytes($badPath, [byte[]]@(0, 1, 2, 3))
Assert-Artwork ($null -eq (Read-FixtureArtwork $badPath)) 'Corrupt thumbnail returns no artwork'
$largePath = Join-Path $outputRoot 'codex_oversize_thumbnail.png'
$largeFile = [IO.File]::Create($largePath)
try { $largeFile.SetLength($script:MaxArtworkInputBytes + 1) } finally { $largeFile.Dispose() }
Assert-Artwork ($null -eq (Read-FixtureArtwork $largePath)) 'Input larger than four MiB is skipped without compression'
$pixelPath = Join-Path $outputRoot 'codex_pixel_limit_thumbnail.png'
Write-FixtureImage $pixelPath 5000 4001
Assert-Artwork ($null -eq (Read-FixtureArtwork $pixelPath)) 'Input larger than twenty million pixels is rejected'
$smallPath = Join-Path $outputRoot 'codex_small_thumbnail.png'
Write-FixtureImage $smallPath 40 20
$smallCover = Read-FixtureArtwork $smallPath
$smallBytes = [Convert]::FromBase64String($smallCover.Substring($smallCover.IndexOf(',') + 1))
$smallMemory = New-Object IO.MemoryStream(,$smallBytes)
$smallImage = [Drawing.Image]::FromStream($smallMemory)
try { Assert-Artwork ($smallImage.Width -eq 40 -and $smallImage.Height -eq 20) 'Small thumbnails are not enlarged' }
finally { $smallImage.Dispose(); $smallMemory.Dispose() }
$script:ArtworkTimeoutMs = 0
Assert-Artwork ($null -eq (Read-FixtureArtwork $fixturePath)) 'Expired artwork budget returns no artwork'
$report = [ordered]@{ status = 'passed'; checkedAt = [DateTimeOffset]::Now.ToString('o');
    runtime = $PSVersionTable.PSVersion.ToString(); scope = 'Real WinRT references with synthetic files; no player or personal archive';
    checks = @($checks.ToArray()); originalByteHashes = @($hashEvidence.ToArray()) }
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $outputRoot 'codex_native_artwork_checks.json') -Encoding UTF8
Write-Output ('ARTWORK_CHECKS_PASSED count=' + $checks.Count + ' output=' + $outputRoot)
