# Tao anh chup giao dien cho README (dung du lieu mau, khong co duong dan ca nhan).
# Chay: powershell -ExecutionPolicy Bypass -File build\New-Screenshot.ps1
param(
    [string]$OutFile = (Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\screenshot.png')
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$null = New-Item -ItemType Directory -Force -Path (Split-Path $OutFile)

function Item($name, $path, $mb, $cat) {
    $bytes = [int64]($mb * 1MB)
    $size = if ($mb -ge 1024) { "{0:n2} GB" -f ($mb / 1024) } else { "{0:n0} MB" -f $mb }
    return [pscustomobject]@{
        Name     = $name
        Path     = $path
        Bytes    = $bytes
        SizeText = $size
        Files    = 0
        Category = $cat
        CatText  = $(switch ($cat) { 'safe' { 'An toàn' } 'review' { 'Xem xét' } default { 'Không xóa' } })
        Locked   = ($cat -eq 'protected')
        Reason   = 'Dữ liệu minh hoạ cho ảnh chụp README.'
        Action   = 'Xem chi tiết trong ứng dụng.'
    }
}

$items = @(
    (Item 'Windows (hệ thống)'        'C:\Windows'                                        22999 'protected'),
    (Item 'Program Files'             'C:\Program Files'                                  15555 'protected'),
    (Item 'Users\Demo - còn lại'      'C:\Users\Demo'                                     13600 'protected'),
    (Item 'Program Files (x86)'       'C:\Program Files (x86)'                              6090 'protected'),
    (Item 'CapCut - Cache'            'C:\Users\Demo\AppData\Local\CapCut\User Data\Cache'  4321 'safe'),
    (Item 'Ollama app'                'C:\Users\Demo\AppData\Local\Programs\Ollama'         3180 'review'),
    (Item 'Zalo Data'                 'C:\Users\Demo\AppData\Roaming\ZaloData'              2925 'review'),
    (Item 'Edge profile'              'C:\Users\Demo\AppData\Local\Microsoft\Edge'          2050 'review'),
    (Item 'CapCut cũ 9.8.0.4211'      'C:\Users\Demo\AppData\Local\CapCut\Apps\9.8.0.4211'   1850 'safe'),
    (Item 'Codex runtimes'            'C:\Users\Demo\.cache\codex-runtimes'                 1690 'safe'),
    (Item 'Temp (người dùng)'         'C:\Users\Demo\AppData\Local\Temp'                    1620 'safe'),
    (Item 'Windows LCU'               'C:\Windows\servicing\LCU'                            1770 'review')
)

# Cac muc minh hoa nho (de tong so muc khop voi so lieu 3 nhom)
for ($n = 1; $n -le 16; $n++) {
    $items += Item ("Cache ứng dụng {0:00}" -f $n) ("C:\Users\Demo\AppData\Local\AppCache\{0:00}" -f $n) (25 + $n * 7) 'safe'
}
for ($n = 1; $n -le 12; $n++) {
    $items += Item ("Dữ liệu ứng dụng {0:00}" -f $n) ("C:\Users\Demo\AppData\Roaming\AppData{0:00}" -f $n) (40 + $n * 11) 'review'
}
for ($n = 1; $n -le 8; $n++) {
    $items += Item ("Thư mục hệ thống {0:00}" -f $n) ("C:\ProgramData\System{0:00}" -f $n) (50 + $n * 13) 'protected'
}

$demo = [pscustomobject]@{
    Generated = '2026-11-22 20:54:16'
    Volume    = [pscustomobject]@{
        Letter = 'C:'; SizeGB = 125.28; UsedGB = 100.26; FreeGB = 25.02; FreePct = 20.0
        SizeBytes = [int64](125.28 * 1GB); UsedBytes = [int64](100.26 * 1GB); FreeBytes = [int64](25.02 * 1GB)
    }
    Scan      = [pscustomobject]@{ Roots = 48; Seconds = 128 }
    Totals    = [pscustomobject]@{
        SafeBytes = [int64](21.50 * 1GB); SafeItems = 20
        ReviewBytes = [int64](15.60 * 1GB); ReviewItems = 16
        ProtectedBytes = [int64](62.22 * 1GB); ProtectedItems = 12
        UsedBytes = [int64](100.26 * 1GB)
    }
    Items = @($items | Sort-Object Bytes -Descending)
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("tf-demo-{0}.json" -f [guid]::NewGuid().ToString('N'))
$json = $demo | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($tmp, $json, (New-Object System.Text.UTF8Encoding($true)))

& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $root 'Tool-Filter.ps1') -DataPath $tmp -Shot $OutFile
$code = $LASTEXITCODE
Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
if ($code -ne 0) { throw "Tao anh that bai (exit $code)" }
Write-Host ("Screenshot: {0}" -f $OutFile)
