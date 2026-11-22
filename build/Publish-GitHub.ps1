# ============================================================
#  Publish-GitHub.ps1
#  Đưa repo này lên GitHub và tạo Release kèm file ZIP portable.
#
#  Cách dùng (khuyến nghị):
#     $env:GITHUB_TOKEN = 'ghp_...'          # token có quyền repo
#     powershell -ExecutionPolicy Bypass -File .\build\Publish-GitHub.ps1
#
#  Hoặc:
#     powershell -ExecutionPolicy Bypass -File .\build\Publish-GitHub.ps1 `
#         -Owner hiyake-20-06 -Repo tool-filter -Token 'ghp_...'
#
#  Token chỉ dùng trong bộ nhớ, không được ghi ra file hay in ra màn hình.
# ============================================================
param(
    [string]$Owner,
    [string]$Repo = 'tool-filter',
    [ValidateSet('public', 'private')]
    [string]$Visibility = 'public',
    [string]$Token,
    [string]$Version = '1.0.0',
    [string]$Description = 'Lọc dung lượng ổ C: - ứng dụng desktop chỉ đọc, portable cho Windows',
    [string[]]$Topics = @('windows', 'powershell', 'wpf', 'disk-cleanup', 'portable', 'vietnamese'),
    [switch]$SkipRelease,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    function Say($m, $c = 'Gray') { Write-Host $m -ForegroundColor $c }
    function Fail($m) { Write-Host "LỖI: $m" -ForegroundColor Red; exit 1 }

    # ---------- Kiểm tra repo git ----------
    if (-not (Test-Path (Join-Path $root '.git'))) { Fail "Chưa có .git — chạy 'git init' trước." }
    $branch = (& git rev-parse --abbrev-ref HEAD).Trim()
    if (-not $branch) { Fail 'Không xác định được nhánh hiện tại.' }
    $dirty = (& git status --porcelain) -join ''
    if ($dirty) { Say 'Cảnh báo: còn thay đổi chưa commit. Hãy commit trước khi phát hành.' 'Yellow' }
    $commit = (& git rev-parse HEAD).Trim()

    # ---------- Token ----------
    if (-not $Token) { $Token = $env:GITHUB_TOKEN }
    if (-not $Token) { $Token = $env:GH_TOKEN }
    if (-not $Token -and $DryRun) {
        $label = $(if ($Owner) { "$Owner/$Repo" } else { "<owner>/$Repo" })
        Say "== [dry-run] $label (nhánh $branch, $Visibility) ==" 'Cyan'
        Say "[dry-run] tạo/kiểm tra repo $label"
        Say "[dry-run] git remote set-url origin https://github.com/$label.git"
        Say "[dry-run] git push -u origin $branch"
        if (-not $SkipRelease) { Say "[dry-run] tạo release v$Version + đính kèm dist\ToolFilter-Portable-v$Version.zip" }
        exit 0
    }
    if (-not $Token) {
        Say ''
        Say 'Chưa có token GitHub. Tạo Personal Access Token (classic) với quyền "repo":' 'Yellow'
        Say '  https://github.com/settings/tokens/new?scopes=repo&description=Tool%20Filter'
        Say ''
        Say 'Rồi chạy lại:' 'Yellow'
        Say '  $env:GITHUB_TOKEN = ''ghp_...'''
        Say '  powershell -ExecutionPolicy Bypass -File .\build\Publish-GitHub.ps1'
        exit 1
    }

    $headers = @{
        Authorization          = "token $Token"
        Accept                 = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
        'User-Agent'           = 'ToolFilter-Publisher'
    }
    $api = 'https://api.github.com'

    # ---------- Xác định chủ repo ----------
    if (-not $Owner) {
        try { $Owner = (Invoke-RestMethod -Uri "$api/user" -Headers $headers -Method Get).login }
        catch { Fail "Token không hợp lệ hoặc không có quyền: $($_.Exception.Message)" }
    }
    $slug = "$Owner/$Repo"
    Say "== Phát hành $slug (nhánh $branch) ==" 'Cyan'

    # ---------- Tạo repo nếu chưa có ----------
    $exists = $true
    try { $null = Invoke-RestMethod -Uri "$api/repos/$slug" -Headers $headers -Method Get }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) { $exists = $false } else { throw }
    }

    if (-not $exists) {
        Say "   Tạo repo mới $slug ($Visibility)..."
        $body = @{ name = $Repo; description = $Description; private = ($Visibility -eq 'private'); has_issues = $true; has_wiki = $false } | ConvertTo-Json
        $null = Invoke-RestMethod -Uri "$api/user/repos" -Headers $headers -Method Post -Body $body -ContentType 'application/json'
        Say '   Đã tạo repo.' 'Green'
    } else {
        Say '   Repo đã tồn tại, cập nhật mô tả + topics...'
        $body = @{ description = $Description; homepage = '' } | ConvertTo-Json
        $null = Invoke-RestMethod -Uri "$api/repos/$slug" -Headers $headers -Method Patch -Body $body -ContentType 'application/json'
    }

    if ($Topics.Count -gt 0) {
        $tb = @{ names = $Topics } | ConvertTo-Json
        try { $null = Invoke-RestMethod -Uri "$api/repos/$slug/topics" -Headers $headers -Method Put -Body $tb -ContentType 'application/json' } catch { }
    }

    # ---------- Remote + push ----------
    $cleanUrl = "https://github.com/$slug.git"
    $existing = (& git remote) -split "`n" | ForEach-Object { $_.Trim() }
    if ($existing -contains 'origin') { & git remote set-url origin $cleanUrl }
    else { & git remote add origin $cleanUrl }
    Say "   Đẩy mã nguồn lên $cleanUrl ..."

    $authUrl = "https://x-access-token:$Token@github.com/$slug.git"
    $log = (& git -c credential.helper= push $authUrl "refs/heads/$branch:refs/heads/$branch" 2>&1 | Out-String)
    $log = $log -replace [regex]::Escape($Token), '***'
    if ($LASTEXITCODE -ne 0) { Write-Host $log; Fail "git push thất bại (mã $LASTEXITCODE)." }
    Say '   Đã đẩy mã nguồn.' 'Green'

    # ---------- Release ----------
    if ($SkipRelease) { Say '   Bỏ qua bước tạo Release (-SkipRelease).' 'Yellow' }
    else {
        $zip = Join-Path $root ("dist\ToolFilter-Portable-v{0}.zip" -f $Version)
        if (-not (Test-Path -LiteralPath $zip)) {
            Say "   Chưa có $zip — đang build..." 'Yellow'
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Build-Portable.ps1') -Version $Version
            if (-not (Test-Path -LiteralPath $zip)) { Fail "Build không tạo ra $zip" }
        }

        $tag = "v$Version"
        $notesFile = Join-Path $root 'CHANGELOG.md'
        $notes = "Bản phát hành $tag của Tool Filter.`n`nXem CHANGELOG.md để biết chi tiết."
        if (Test-Path -LiteralPath $notesFile) {
            $all = Get-Content -Raw -Encoding UTF8 $notesFile
            $m = [regex]::Match($all, "(?ms)^##\s*\[$([regex]::Escape($Version))\][^\n]*\n(.*?)(?=^##\s|\z)")
            if ($m.Success) { $notes = $m.Groups[1].Value.Trim() }
        }

        $relBody = @{
            tag_name         = $tag
            target_commitish = $commit
            name             = "Tool Filter $tag"
            body             = $notes
            draft            = $false
            prerelease       = $false
        } | ConvertTo-Json

        $rel = $null
        try { $rel = Invoke-RestMethod -Uri "$api/repos/$slug/releases/tags/$tag" -Headers $headers -Method Get } catch { }
        if ($rel) {
            Say "   Release $tag đã có, cập nhật..."
            $rel = Invoke-RestMethod -Uri "$api/repos/$slug/releases/$($rel.id)" -Headers $headers -Method Patch -Body $relBody -ContentType 'application/json'
        } else {
            Say "   Tạo release $tag ..."
            $rel = Invoke-RestMethod -Uri "$api/repos/$slug/releases" -Headers $headers -Method Post -Body $relBody -ContentType 'application/json'
        }

        $assetName = Split-Path $zip -Leaf
        $already = @($rel.assets | Where-Object { $_.name -eq $assetName })
        foreach ($a in $already) {
            Say "   Gỡ asset cũ $assetName ..."
            $null = Invoke-RestMethod -Uri "$api/repos/$slug/releases/assets/$($a.id)" -Headers $headers -Method Delete
        }
        Say "   Tải lên $assetName ..."
        $null = Invoke-RestMethod -Uri "https://uploads.github.com/repos/$slug/releases/$($rel.id)/assets?name=$assetName" `
            -Headers $headers -Method Post -ContentType 'application/zip' -InFile $zip
        Say '   Đã đính kèm file ZIP.' 'Green'
        Say ("   Release: {0}" -f $rel.html_url) 'Green'
    }

    Say ''
    Say 'Hoàn tất:' 'Green'
    Say ("  Repo    : https://github.com/{0}" -f $slug)
    if (-not $SkipRelease) { Say ("  Release : https://github.com/{0}/releases/tag/v{1}" -f $slug, $Version) }
    Say ''
    Say 'Gợi ý: bật GitHub Actions (tab Actions) để tự build khi bạn đẩy tag mới.' 'DarkGray'
}
finally { Pop-Location }
