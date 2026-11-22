# ============================================================
#  Build-Portable.ps1
#  Đóng gói Tool Filter thành ứng dụng desktop portable:
#    app\ToolFilter.exe + resources\ + README + LICENSE
#    dist\ToolFilter-Portable-v<version>.zip
#  Chạy: powershell -ExecutionPolicy Bypass -File build\Build-Portable.ps1
# ============================================================
param(
    [string]$Version = '1.0.0',
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'
$buildDir = $PSScriptRoot
$root     = Split-Path $buildDir -Parent
if (-not $OutDir) { $OutDir = Join-Path $root 'app' }
$distDir  = Join-Path $root 'dist'
$null = New-Item -ItemType Directory -Force -Path $OutDir, $distDir

$v = $Version.TrimStart('v', 'V')
$v = ($v -replace '[^0-9\.]', '')
$parts = @($v -split '\.' | Where-Object { $_ -ne '' })
while ($parts.Count -lt 4) { $parts += '0' }
$asmVersion = ($parts[0..3] -join '.')

Write-Host "== Tool Filter portable build ==" -ForegroundColor Cyan
Write-Host "   Version : $v"
Write-Host "   Output  : $OutDir"

# ---------- 1. Icon ----------
$ico = Join-Path $buildDir 'app.ico'
if (-not (Test-Path -LiteralPath $ico)) {
    Write-Host "   Tao icon..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $buildDir 'New-Icon.ps1') | Out-Null
}
if (-not (Test-Path -LiteralPath $ico)) { throw "Khong tao duoc icon: $ico" }

# ---------- 2. Lam sach thu muc output ----------
Write-Host "   Lam sach $OutDir ..."
Get-ChildItem -LiteralPath $OutDir -Force | Remove-Item -Recurse -Force
$resDir = Join-Path $OutDir 'resources'
$null = New-Item -ItemType Directory -Force -Path $resDir

# ---------- 3. Chep script ----------
foreach ($f in @('Tool-Filter.ps1', 'Scan.ps1')) {
    $src = Join-Path $root $f
    if (-not (Test-Path -LiteralPath $src)) { throw "Thieu file nguon: $src" }
    Copy-Item -LiteralPath $src -Destination $resDir
}
Copy-Item -LiteralPath $ico -Destination $resDir

# ---------- 4. Bien dich launcher ----------
Write-Host "   Bien dich ToolFilter.exe ..."
$csc = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc)) {
    $csc = (Get-ChildItem 'C:\Windows\Microsoft.NET\Framework*\v4.0.30319\csc.exe' -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName)
}
if (-not $csc) { throw "Khong tim thay csc.exe (.NET Framework 4)." }

$exe = Join-Path $OutDir 'ToolFilter.exe'
$verFile = Join-Path ([System.IO.Path]::GetTempPath()) ("tf-version-{0}.cs" -f [guid]::NewGuid().ToString('N'))
@"
using System.Reflection;
[assembly: AssemblyVersion("$asmVersion")]
[assembly: AssemblyFileVersion("$asmVersion")]
"@ | Set-Content -LiteralPath $verFile -Encoding UTF8

& $csc /nologo /target:winexe /optimize+ /codepage:65001 `
    "/out:$exe" "/win32icon:$ico" `
    /reference:System.dll /reference:System.Windows.Forms.dll `
    (Join-Path $buildDir 'Launcher.cs') $verFile
if ($LASTEXITCODE -ne 0) { throw "csc that bai (exit $LASTEXITCODE)" }
Remove-Item -LiteralPath $verFile -Force

# ---------- 5. Tai lieu kem theo ----------
Copy-Item -LiteralPath (Join-Path $buildDir 'PORTABLE-README.md') -Destination (Join-Path $OutDir 'README.md')
Copy-Item -LiteralPath (Join-Path $buildDir 'Troubleshoot.cmd')    -Destination $OutDir
$license = Join-Path $root 'LICENSE'
if (Test-Path -LiteralPath $license) { Copy-Item -LiteralPath $license -Destination $OutDir }

# ---------- 6. ZIP ----------
Write-Host "   Dong goi ZIP ..."
$stage = Join-Path $distDir '_stage'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
$stageApp = Join-Path $stage 'ToolFilter-Portable'
$null = New-Item -ItemType Directory -Force -Path $stageApp
Copy-Item -Path (Join-Path $OutDir '*') -Destination $stageApp -Recurse -Force

$zip = Join-Path $distDir ("ToolFilter-Portable-v{0}.zip" -f $v)
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path $stageApp -DestinationPath $zip -CompressionLevel Optimal
Remove-Item -LiteralPath $stage -Recurse -Force

$zipMb = [math]::Round((Get-Item -LiteralPath $zip).Length / 1MB, 2)
$exeKb = [math]::Round((Get-Item -LiteralPath $exe).Length / 1KB)
Write-Host ""
Write-Host ("Xong:") -ForegroundColor Green
Write-Host ("  {0}  ({1} KB)" -f $exe, $exeKb)
Write-Host ("  {0}  ({1} MB)" -f $zip, $zipMb)
Write-Host ""
Write-Host "Thu chay: $exe"
