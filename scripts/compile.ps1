Param(
    [string]$SingBoxExecutable = "sing-box",
    [string]$SourceDir = "rules",
    [string]$OutputDir = "dist"
)

if (-not (Get-Command $SingBoxExecutable -ErrorAction SilentlyContinue)) {
    Write-Error "sing-box executable '$SingBoxExecutable' not found in PATH"
    exit 1
}

if (-not (Test-Path $SourceDir -PathType Container)) {
    Write-Error "Source directory '$SourceDir' does not exist"
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$ruleFiles = Get-ChildItem -Path $SourceDir -Filter *.json -Recurse
if (-not $ruleFiles) {
    Write-Error "No JSON rule-set source files found under '$SourceDir'"
    exit 1
}

$sourceRoot = ((Resolve-Path $SourceDir).ProviderPath).TrimEnd('\','/')
$sourceRootWithSep = $sourceRoot + [System.IO.Path]::DirectorySeparatorChar

foreach ($file in $ruleFiles) {
    $relative = $file.FullName.Substring($sourceRootWithSep.Length)
    $relativeNoExt = [System.IO.Path]::ChangeExtension($relative, $null)
    $outputPath = Join-Path $OutputDir ($relativeNoExt + ".srs")
    $outputDir = Split-Path $outputPath -Parent
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    Write-Host "compiling $($file.FullName) -> $outputPath"
    & $SingBoxExecutable rule-set compile --output $outputPath $file.FullName
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host ("done. Generated {0} file(s) in '{1}'." -f (Get-ChildItem -Path $OutputDir -Filter *.srs -Recurse | Measure-Object | Select-Object -ExpandProperty Count), $OutputDir)
