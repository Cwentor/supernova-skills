# install.ps1 — 把 my-skills 各技能 junction 到 .agents\skills
# 用法: powershell -File install.ps1 [-DryRun]
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$repo   = $PSScriptRoot | Split-Path -Parent
$target = Join-Path $env:USERPROFILE '.agents\skills'
$backup = Join-Path $env:USERPROFILE ('.agents\skills-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))

if (-not (Test-Path $target)) { New-Item -ItemType Directory -Force -Path $target | Out-Null }

# 收集所有带 SKILL.md 的技能目录（一期 meta/dev，后续期 lang/write/ops 建好即自动纳入）
$skills = Get-ChildItem (Join-Path $repo 'meta'), (Join-Path $repo 'dev'), (Join-Path $repo 'lang'), (Join-Path $repo 'write'), (Join-Path $repo 'ops') -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }

$report = [System.Collections.Generic.List[string]]::new()
foreach ($s in $skills) {
    $dest = Join-Path $target $s.Name
    if (Test-Path $dest) {
        $item = Get-Item $dest -Force
        if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
            if ($DryRun) { $report.Add("[DRY] 移除旧 junction: $($s.Name)") }
            else { $item.Delete(); $report.Add("[OK ] 移除旧 junction: $($s.Name)") }
        }
        else {
            if ($DryRun) { $report.Add("[DRY] 备份旧拷贝: $($s.Name) -> $backup") }
            else {
                if (-not (Test-Path $backup)) { New-Item -ItemType Directory -Force -Path $backup | Out-Null }
                Move-Item $dest (Join-Path $backup $s.Name)
                $report.Add("[OK ] 备份旧拷贝: $($s.Name)")
            }
        }
    }
    if ($DryRun) { $report.Add("[DRY] 建 junction: $($s.Name)") }
    else {
        New-Item -ItemType Junction -Path $dest -Target $s.FullName | Out-Null
        $report.Add("[OK ] 建 junction: $($s.Name)")
    }
}

$report | ForEach-Object { Write-Output $_ }
Write-Output ("---- 共 {0} 个技能处理完毕 {1} ----" -f $skills.Count, $(if ($DryRun) { '(DRY RUN，未动文件)' } else { '' }))
if (-not $DryRun -and (Test-Path $backup)) { Write-Output "被替换旧拷贝备份于: $backup" }
Write-Output '提示: 安装/卸载后需新开会话才生效。'
