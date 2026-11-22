# Tao icon ung dung (app.ico) va logo PNG bang System.Drawing.
# Chay: powershell -ExecutionPolicy Bypass -File build\New-Icon.ps1
param(
    [string]$OutDir = (Split-Path -Parent $PSScriptRoot)
)

Add-Type -AssemblyName System.Drawing

$icoPath  = Join-Path $PSScriptRoot 'app.ico'
$logoPath = Join-Path $OutDir 'docs\logo.png'
$null = New-Item -ItemType Directory -Force -Path (Split-Path $logoPath)

function New-IconBitmap([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $s = $size / 256.0
    $pad = 6 * $s
    $rect = New-Object System.Drawing.RectangleF $pad, $pad, ($size - 2 * $pad), ($size - 2 * $pad)
    $r = 52 * $s

    # Bo goc (rounded rectangle path)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
    $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()

    $c1 = [System.Drawing.Color]::FromArgb(255, 59, 130, 246)
    $c2 = [System.Drawing.Color]::FromArgb(255, 29, 78, 216)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 90.0
    $g.FillPath($brush, $path)

    # Bieu tuong pheu loc mau trang
    $pts = @(
        (New-Object System.Drawing.PointF (60 * $s), (70 * $s)),
        (New-Object System.Drawing.PointF (196 * $s), (70 * $s)),
        (New-Object System.Drawing.PointF (142 * $s), (142 * $s)),
        (New-Object System.Drawing.PointF (142 * $s), (192 * $s)),
        (New-Object System.Drawing.PointF (128 * $s), (208 * $s)),
        (New-Object System.Drawing.PointF (114 * $s), (192 * $s)),
        (New-Object System.Drawing.PointF (114 * $s), (142 * $s))
    )
    $wb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(250, 255, 255, 255))
    $g.FillPolygon($wb, $pts)

    $g.Dispose()
    return $bmp
}

function Get-PngBytes([System.Drawing.Bitmap]$bmp) {
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $ms.ToArray()
    $ms.Dispose()
    return $bytes
}

# --- ICO nhieu kich thuoc ---
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$frames = @()
foreach ($s in $sizes) {
    $bmp = New-IconBitmap $s
    $frames += ,@($s, (Get-PngBytes $bmp))
    $bmp.Dispose()
}

$fs = [System.IO.File]::Create($icoPath)
$bw = New-Object System.IO.BinaryWriter $fs
$bw.Write([uint16]0)
$bw.Write([uint16]1)
$bw.Write([uint16]$frames.Count)
$offset = 6 + 16 * $frames.Count
foreach ($f in $frames) {
    $s = [int]$f[0]
    $data = [byte[]]$f[1]
    $bw.Write([byte]$(if ($s -ge 256) { 0 } else { $s }))
    $bw.Write([byte]$(if ($s -ge 256) { 0 } else { $s }))
    $bw.Write([byte]0)     # palette
    $bw.Write([byte]0)     # reserved
    $bw.Write([uint16]1)   # planes
    $bw.Write([uint16]32)  # bpp
    $bw.Write([uint32]$data.Length)
    $bw.Write([uint32]$offset)
    $offset += $data.Length
}
foreach ($f in $frames) { $bw.Write([byte[]]$f[1]) }
$bw.Flush(); $bw.Close(); $fs.Close()

# --- Logo PNG 512px ---
$logo = New-IconBitmap 512
$logo.Save($logoPath, [System.Drawing.Imaging.ImageFormat]::Png)
$logo.Dispose()

Write-Host ("Icon : {0} ({1:n0} bytes)" -f $icoPath, (Get-Item $icoPath).Length)
Write-Host ("Logo : {0} ({1:n0} bytes)" -f $logoPath, (Get-Item $logoPath).Length)
