# ============================================================
#  Scan.ps1  -  Quét ổ C: (CHỈ ĐỌC) và phân loại 3 nhóm
#  safe (An toàn) / review (Xem xét) / protected (Không xóa)
#  Kỹ thuật: robocopy /L (liệt kê) để đo dung lượng rất nhanh,
#            không mở, không sửa, không xóa bất kỳ file nào.
#  Kết quả: <thư mục ứng dụng>\data\index.json
# ============================================================
param(
    [string]$Volume = 'C:\'
)

$ErrorActionPreference = 'SilentlyContinue'
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$toolDir  = $scriptDir
if ((Split-Path $toolDir -Leaf) -eq 'resources') { $toolDir = Split-Path $toolDir -Parent }
$dataDir  = Join-Path $toolDir 'data'
$null     = New-Item -ItemType Directory -Force -Path $dataDir
$nullDest = Join-Path $dataDir '_null'
$logPath  = Join-Path $dataDir 'scan.log'
$jsonPath = Join-Path $dataDir 'index.json'
$startTime = Get-Date
if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }

function Log([string]$m) {
    $line = "{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $m
    $line | Out-File -FilePath $logPath -Append -Encoding UTF8
    Write-Host $line
}

function Fmt([double]$b) {
    if ($b -ge 1GB) { return ("{0:n2} GB" -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ("{0:n0} MB" -f ($b / 1MB)) }
    if ($b -gt 0)   { return ("{0:n0} KB" -f ($b / 1KB)) }
    return '0'
}

# ---------- Đo dung lượng 1 thư mục bằng robocopy (chỉ liệt kê) ----------
function Get-RcSize {
    param([string]$Path)

    $exists = $false
    try { $null = Get-Item -LiteralPath $Path -Force -ErrorAction Stop; $exists = $true } catch { $exists = $false }
    if (-not $exists) { return $null }

    $rcArgs = @($Path, $nullDest, '/L', '/S', '/XJ', '/BYTES',
                '/NFL', '/NDL', '/NJH', '/R:0', '/W:0')
    $out = & robocopy @rcArgs 2>&1

    $bytes = [int64]0; $files = [int64]0; $deniedDirs = 0
    foreach ($line in $out) {
        $s = [string]$line
        if ($s -match '^\s*Bytes\s*:\s+(\d+)') { $bytes = [int64]$matches[1] }
        elseif ($s -match '^\s*Files\s*:\s+(\d+)') { $files = [int64]$matches[1] }
        elseif ($s -match '^\s*Dirs\s*:\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)') { $deniedDirs = [int]$matches[1] }
    }
    return [pscustomobject]@{ Bytes = $bytes; Files = $files; Denied = $deniedDirs }
}

function Get-FileSize([string]$Path) {
    try {
        $fi = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        return [pscustomobject]@{ Bytes = [int64]$fi.Length; Files = 1; Denied = 0 }
    } catch { return $null }
}

# ---------- Kho dòng kết quả ----------
$rows = New-Object System.Collections.ArrayList

function Add-Row {
    param(
        [string]$Path, [string]$Name, [string]$Category,
        [int64]$Bytes, [int64]$Files, [int]$Denied,
        [string]$Reason, [string]$Action
    )
    if ($Bytes -lt 1MB) { return }
    $note = ''
    if ($Denied -gt 0) { $note = " (bỏ qua $Denied thư mục không truy cập được)" }
    $catText = switch ($Category) { 'safe' { 'An toàn' } 'review' { 'Xem xét' } default { 'Không xóa' } }
    [void]$rows.Add([pscustomobject]@{
        Name     = $Name
        Path     = $Path
        Bytes    = [int64]$Bytes
        SizeText = Fmt $Bytes
        Files    = [int64]$Files
        Category = $Category
        CatText  = $catText
        Locked   = ($Category -eq 'protected')
        Reason   = $Reason + $note
        Action   = $Action
    })
}

function Add-Path {
    param([string]$Path, [string]$Category, [string]$Reason, [string]$Action, [string]$Name)
    $m = Get-RcSize $Path
    if ($null -eq $m) { Log ("  -- không có: {0}" -f $Path); return }
    if (-not $Name) { $Name = Split-Path -Leaf $Path }
    Add-Row -Path $Path -Name $Name -Category $Category -Bytes $m.Bytes -Files $m.Files -Denied $m.Denied -Reason $Reason -Action $Action
    Log ("  {0,-62} {1,10}  ({2:n0} file)" -f $Name, (Fmt $m.Bytes), $m.Files)
}

Log "=== BẮT ĐẦU QUÉT $Volume (chỉ đọc) ==="

$U = 'C:\Users\Tanho'
$L = "$U\AppData\Local"
$R = "$U\AppData\Roaming"
$CUR_CAPCUT = '9.9.0.4240'

# ============================================================
#  1) AN TOÀN
# ============================================================
Log "--- Nhóm AN TOÀN ---"

# CapCut: các bản cũ (giữ bản đang dùng)
$capcutApps = Join-Path $L 'CapCut\Apps'
if (Test-Path -LiteralPath $capcutApps) {
    Get-ChildItem -LiteralPath $capcutApps -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -ne $CUR_CAPCUT) {
            Add-Path -Path $_.FullName -Category 'safe' `
                -Reason "Bản CapCut cũ ($($_.Name)), không còn được dùng; mỗi bản ~1,8 GB" `
                -Action "Đóng CapCut hoàn toàn rồi xóa cả thư mục phiên bản này bằng tay." `
                -Name "CapCut cũ $($_.Name)"
        }
    }
}

Add-Path "$L\CapCut\User Data\Cache" 'safe' `
    'Cache xem trước/proxy của CapCut (tự tạo lại, không mất project)' `
    'Đóng CapCut rồi xóa nội dung thư mục.' 'CapCut - Cache'

Add-Path "$L\CapCut\User Data\Download" 'safe' `
    'Bộ cài/zip CapCut đã tải xong' `
    'Xóa nội dung thư mục.' 'CapCut - Download'

Add-Path "$L\Temp" 'safe' `
    'File tạm của người dùng (ứng dụng tự tạo lại)' `
    'Đóng app đang chạy rồi xóa file cũ; bỏ qua file đang khóa.' 'Temp (người dùng)'

Add-Path 'C:\Windows\Temp' 'safe' `
    'File tạm hệ thống' `
    'Xóa nội dung; một số file đang dùng sẽ bị bỏ qua.' 'Temp (Windows)'

Add-Path "$U\.cache\codex-runtimes" 'safe' `
    'Runtime Codex tải về, có thể tải lại khi cần' `
    'Xóa cả thư mục; Codex tự tải lại.' 'Codex runtimes'

Add-Path "$L\electron" 'safe' `
    'Cache tải Electron của các ứng dụng' `
    'Xóa nội dung; app tự tải lại nếu cần.' 'Electron cache'

$updaters = @(
    @{ p = "$L\@opencodedesktop-updater"; n = 'OpenCode Desktop updater' },
    @{ p = "$L\antigravity-updater";       n = 'Antigravity updater' },
    @{ p = "$L\draw.io-updater";           n = 'draw.io updater' },
    @{ p = "$L\Microsoft\PowerToys\Updates"; n = 'PowerToys Updates' },
    @{ p = "$L\GitHubDesktop\packages";    n = 'GitHub Desktop packages' },
    @{ p = 'C:\Program Files (x86)\Microsoft\EdgeUpdate\Download'; n = 'Edge Update download' }
)
foreach ($ud in $updaters) {
    Add-Path $ud.p 'safe' 'Bộ cài cập nhật đã tải xong (không cần giữ)' `
        'Xóa nội dung thư mục.' $ud.n
}

Add-Path 'C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization' `
    'safe' 'Cache chia sẻ Windows Update' `
    'Xóa qua Disk Cleanup ("Delivery Optimization Files").' 'Delivery Optimization'

Add-Path 'C:\Windows\SoftwareDistribution\Download' 'safe' `
    'Gói Windows Update đã cài xong' `
    'Xóa nội dung; Windows Update tự tải lại khi cần.' 'Windows Update - Download'

Add-Path 'C:\Windows\Logs' 'safe' `
    'Log cũ của Windows (CBS, DISM, setup...)' `
    'Xóa các file .log/.cab cũ, giữ thư mục.' 'Windows Logs'

Add-Path 'C:\$Recycle.Bin' 'safe' `
    'Thùng rác' `
    'Chuột phải Recycle Bin > Empty Recycle Bin.' 'Thùng rác'

# ============================================================
#  2) XEM XÉT
# ============================================================
Log "--- Nhóm XEM XÉT ---"

Add-Path "$L\CapCut\Videos" 'review' `
    'Video nguồn/đã xuất của bạn trong CapCut' `
    'Chỉ xóa nếu đã có bản sao lưu.' 'CapCut - Videos'

Add-Path "$R\ZaloData" 'review' `
    'Dữ liệu Zalo: ảnh, file đã nhận, database tin nhắn' `
    'Nên dùng "Xóa cache" trong Zalo; xóa thư mục = mất file đã nhận.' 'Zalo Data'

Add-Path "$R\Recordly\recordings" 'review' `
    'Video quay màn hình của bạn' `
    'Xóa từng video cũ nếu không cần.' 'Recordly recordings'

Add-Path "$U\Downloads" 'review' `
    'File bạn tải về' `
    'Dọn thủ công theo nhu cầu.' 'Downloads'

Add-Path "$L\Microsoft\Edge" 'review' `
    'Profile + cache trình duyệt Edge' `
    'Chỉ xóa thư mục Cache, KHÔNG xóa cả profile (mất đăng nhập).' 'Edge profile'

Add-Path "$L\Microsoft\Office" 'review' `
    'Cache Office' `
    'Có thể phải đăng nhập lại Office.' 'Office cache'

Add-Path "$L\CocCoc" 'review' `
    'Profile + cache CocCoc' `
    'Chỉ xóa cache, không xóa profile.' 'CocCoc profile'

Add-Path "$L\Google" 'review' `
    'Profile + cache Chrome/GoogleUpdater' `
    'Chỉ xóa cache, không xóa profile.' 'Google profile'

Add-Path "$U\.gemini" 'review' `
    'Cache/phiên ứng dụng Gemini' `
    'App tự tạo lại; có thể mất phiên đăng nhập.' '.gemini'

Add-Path "$U\.codex" 'review' `
    'Dữ liệu app Codex (phiên, log, plugin)' `
    'Chỉ xóa log/tmp; giữ auth.json.' '.codex'

Add-Path "$U\.local\share\opencode" 'review' `
    'Dữ liệu OpenCode: session, database, log' `
    'Xóa log/session cũ; giữ cấu hình nếu cần.' 'OpenCode data'

Add-Path "$L\Programs\Ollama" 'review' `
    'Ứng dụng Ollama (model AI đã xóa trước đó)' `
    'Gỡ bằng Uninstall nếu không dùng AI local.' 'Ollama app'

Add-Path "$L\Packages\TheDebianProject.DebianGNULinux_76v4gfsz19hv4" 'review' `
    'Đĩa ảo WSL Debian (ext4.vhdx)' `
    'Mất dữ liệu Linux nếu xóa; dùng wsl --unregister nếu không cần.' 'WSL Debian'

Add-Path 'C:\Windows\servicing\LCU' 'review' `
    'Staging của Windows Update (KHÔNG xóa tay)' `
    'Chỉ dọn bằng DISM /StartComponentCleanup.' 'Windows LCU'

$mrt = Get-FileSize 'C:\Windows\System32\MRT.exe'
if ($mrt) {
    Add-Row -Path 'C:\Windows\System32\MRT.exe' -Name 'MRT.exe' -Category 'review' `
        -Bytes $mrt.Bytes -Files 1 -Denied 0 `
        -Reason 'Malicious Software Removal Tool' `
        -Action 'Xóa được nhưng tháng sau Windows Update tải lại.'
    Log ("  {0,-62} {1,10}" -f 'MRT.exe', (Fmt $mrt.Bytes))
}

Add-Path 'C:\Tools' 'review' `
    'Công cụ bạn tự cài (w64devkit...)' `
    'Chỉ xóa nếu không dùng.' 'C:\Tools'

# ============================================================
#  3) KHÔNG XÓA (khóa)
# ============================================================
Log "--- Nhóm KHÔNG XÓA ---"

# --- Tổng các thư mục lớn ---
$winTotal  = Get-RcSize 'C:\Windows'
$userTotal = Get-RcSize $U
$pfTotal   = Get-RcSize 'C:\Program Files'
$pfxTotal  = Get-RcSize 'C:\Program Files (x86)'
$pdTotal   = Get-RcSize 'C:\ProgramData'
Log ("  Tổng: Windows {0} | Users\Tanho {1} | Program Files {2} | (x86) {3} | ProgramData {4}" -f `
    (Fmt $winTotal.Bytes), (Fmt $userTotal.Bytes), (Fmt $pfTotal.Bytes), (Fmt $pfxTotal.Bytes), (Fmt $pdTotal.Bytes))

# --- Dữ liệu cá nhân của người dùng (hiển thị riêng) ---
$personal = @(
    @{ p = "$U\Documents"; n = 'Documents (tài liệu)' },
    @{ p = "$U\Desktop";   n = 'Desktop (màn hình)' },
    @{ p = "$U\Pictures";  n = 'Pictures (ảnh)' },
    @{ p = "$U\Videos";    n = 'Videos' },
    @{ p = "$U\Music";     n = 'Music' },
    @{ p = "$U\OneDrive";  n = 'OneDrive' },
    @{ p = "$U\Zomboid";   n = 'Zomboid (save game)' }
)
foreach ($d in $personal) {
    Add-Path $d.p 'protected' `
        'Dữ liệu cá nhân của bạn - không xóa bằng tool' `
        'Tự quản lý/backup; không xóa thủ công trong thư mục này.' $d.n
}

# --- Phần còn lại của Users\Tanho ---
$userSub = [int64]0
foreach ($it in $rows) {
    if ($it.Path.StartsWith($U + '\', [System.StringComparison]::OrdinalIgnoreCase)) { $userSub += $it.Bytes }
}
$userRest = [int64]($userTotal.Bytes - $userSub)
Add-Row -Path $U -Name 'Users\Tanho - còn lại' -Category 'protected' `
    -Bytes $userRest -Files 0 -Denied 0 `
    -Reason 'AppData, cấu hình ứng dụng, dữ liệu ẩn khác (đã trừ các mục phân loại ở trên)' `
    -Action 'Không xóa thủ công; chỉ dọn qua từng ứng dụng.'

# --- Windows: phần không thuộc mục an toàn/xem xét ---
$winSub = [int64]0
foreach ($it in $rows) {
    if ($it.Path.StartsWith('C:\Windows\', [System.StringComparison]::OrdinalIgnoreCase)) { $winSub += $it.Bytes }
}
$winRest = [int64]($winTotal.Bytes - $winSub)
Add-Row -Path 'C:\Windows' -Name 'Windows (hệ thống)' -Category 'protected' `
    -Bytes $winRest -Files 0 -Denied $winTotal.Denied `
    -Reason 'Thành phần hệ thống Windows (đã trừ mục an toàn/xem xét)' `
    -Action 'Không xóa. Chỉ dọn qua DISM / Disk Cleanup.'

# --- Ứng dụng đã cài ---
Add-Row -Path 'C:\Program Files' -Name 'Program Files' -Category 'protected' `
    -Bytes $pfTotal.Bytes -Files $pfTotal.Files -Denied $pfTotal.Denied `
    -Reason 'Ứng dụng đã cài (64-bit)' -Action 'Gỡ bằng Uninstall, không xóa thư mục.'

Add-Row -Path 'C:\Program Files (x86)' -Name 'Program Files (x86)' -Category 'protected' `
    -Bytes $pfxTotal.Bytes -Files $pfxTotal.Files -Denied $pfxTotal.Denied `
    -Reason 'Ứng dụng đã cài (32-bit)' -Action 'Gỡ bằng Uninstall, không xóa thư mục.'

Add-Row -Path 'C:\ProgramData' -Name 'ProgramData' -Category 'protected' `
    -Bytes $pdTotal.Bytes -Files $pdTotal.Files -Denied $pdTotal.Denied `
    -Reason 'Dữ liệu/cache hệ thống & ứng dụng (Defender, Package Cache...)' `
    -Action 'Không xóa. Dọn bằng Disk Cleanup.'

# --- Thư mục gốc còn lại ---
$smallDirs = @(
    @{ p = 'C:\Recovery';      r = 'Phân vùng/dữ liệu khôi phục hệ thống' },
    @{ p = 'C:\System Volume Information'; r = 'Bóng hệ thống (System Restore)' },
    @{ p = 'C:\AiO-Files';     r = 'Bộ cài AiO (dữ liệu của bạn)' },
    @{ p = 'C:\MATS';          r = 'Microsoft Assessment Toolkit' },
    @{ p = 'C:\evkey';         r = 'Bộ gõ EVKey (đã cài)' },
    @{ p = 'C:\Intel';         r = 'Dữ liệu Intel (logs, driver)' },
    @{ p = 'C:\Dell';          r = 'Dữ liệu Dell (logs, driver)' },
    @{ p = 'C:\common_attachment'; r = 'Dữ liệu hệ thống' },
    @{ p = 'C:\inetpub';       r = 'Thư mục IIS mặc định' },
    @{ p = 'C:\PerfLogs';      r = 'Log hiệu năng hệ thống' },
    @{ p = 'C:\XboxGames';     r = 'Game/hệ thống Xbox' },
    @{ p = $toolDir;   r = 'Chính công cụ lọc này' }
)
foreach ($d in $smallDirs) {
    Add-Path $d.p 'protected' $d.r 'Không xóa thủ công.' $null
}

# --- File hệ thống ở gốc ổ ---
foreach ($f in @('C:\pagefile.sys','C:\swapfile.sys','C:\hiberfil.sys','C:\dumpstack.log.tmp')) {
    $m = Get-FileSize $f
    if ($m -and $m.Bytes -gt 0) {
        Add-Row -Path $f -Name (Split-Path -Leaf $f) -Category 'protected' `
            -Bytes $m.Bytes -Files 1 -Denied 0 `
            -Reason 'File hệ thống bắt buộc của Windows' `
            -Action 'KHÔNG xóa.'
    }
}

# ============================================================
#  TỔNG HỢP
# ============================================================
$vol  = Get-Volume -DriveLetter C
$used = [int64]$vol.Size - [int64]$vol.SizeRemaining

$safeBytes = [int64]0; $safeItems = 0
$revBytes  = [int64]0; $revItems  = 0
$proRowSum = [int64]0; $proItems  = 0
foreach ($it in $rows) {
    switch ($it.Category) {
        'safe'   { $safeBytes += $it.Bytes; $safeItems++ }
        'review' { $revBytes  += $it.Bytes; $revItems++ }
        default  { $proRowSum += $it.Bytes; $proItems++ }
    }
}
$proBytes = [int64]($used - $safeBytes - $revBytes)
if ($proBytes -lt 0) { $proBytes = 0 }

# Phần chênh lệch còn lại của ổ (MFT, System Restore, thư mục bị chặn quyền...)
$rest = [int64]($proBytes - $proRowSum)
if ($rest -gt 1MB) {
    Add-Row -Path 'C:\' -Name 'Phần hệ thống còn lại của ổ' -Category 'protected' `
        -Bytes $rest -Files 0 -Denied 0 `
        -Reason 'MFT, System Volume Information, vùng bị chặn quyền truy cập, chênh lệch hardlink' `
        -Action 'Không xóa.'
    $proItems++
}

$sorted = @($rows | Sort-Object Bytes -Descending)

$result = [pscustomobject]@{
    Generated = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Volume    = [pscustomobject]@{
        Letter    = 'C:'
        SizeBytes = [int64]$vol.Size
        UsedBytes = $used
        FreeBytes = [int64]$vol.SizeRemaining
        SizeGB    = [math]::Round($vol.Size / 1GB, 2)
        UsedGB    = [math]::Round($used / 1GB, 2)
        FreeGB    = [math]::Round($vol.SizeRemaining / 1GB, 2)
        FreePct   = [math]::Round($vol.SizeRemaining / $vol.Size * 100, 1)
    }
    Scan      = [pscustomobject]@{
        Roots   = $rows.Count
        Seconds = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
    }
    Totals    = [pscustomobject]@{
        SafeBytes      = $safeBytes; SafeItems      = $safeItems
        ReviewBytes    = $revBytes;  ReviewItems    = $revItems
        ProtectedBytes = $proBytes;  ProtectedItems = $proItems
        UsedBytes      = $used
    }
    Items     = $sorted
}

try {
    $json = $result | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($jsonPath, $json, (New-Object System.Text.UTF8Encoding($true)))
    Log ("Đã ghi {0} ({1} mục)" -f $jsonPath, $sorted.Count)
} catch {
    Log ("LỖI ghi JSON: {0}" -f $_.Exception.Message)
}

Log ("An toàn {0} ({1} mục) | Xem xét {2} ({3} mục) | Không xóa {4} ({5} mục) | Ổ C: dùng {6}, trống {7}" -f `
    (Fmt $safeBytes), $safeItems, (Fmt $revBytes), $revItems, (Fmt $proBytes), $proItems, `
    (Fmt $used), (Fmt $vol.SizeRemaining))
Log ("=== HOÀN TẤT sau {0:n0} giây ===" -f ((Get-Date) - $startTime).TotalSeconds)
Write-Host ""
$exePath = Join-Path $toolDir 'ToolFilter.exe'
if (Test-Path -LiteralPath $exePath) {
    Write-Host ("Xong. Mở tool: {0}" -f $exePath) -ForegroundColor Green
} else {
    Write-Host ("Xong. Mở tool: {0}" -f (Join-Path $toolDir 'Start-Tool.cmd')) -ForegroundColor Green
}
