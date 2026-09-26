# uninstall.ps1 — 只移除 my-skills 建的 junction，不动其他任何目录
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$repo   = $PSScriptRoot | Split-Path -Parent
$target = Join-Path $env:USERPROFILE '.agents\skills'

$skills = Get-ChildItem (Join-Path $repo 'meta'), (Join-Path $repo 'dev'), (Join-Path $repo 'lang'), (Join-Path $repo 'write'), (Join-Path $repo 'ops') -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }

$removed = 0
foreach ($s in $skills) {
    $dest = Join-Path $target $s.Name
    if (Test-Path $dest) {
        $item = Get-Item $dest -Force
        if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
            if ($DryRun) { Write-Output "[DRY] 移除 junction: $($s.Name)" }
            else { $item.Delete(); Write-Output "[OK ] 移除 junction: $($s.Name)"; $removed++ }
        }
        else {
            Write-Output "[跳过] $($s.Name) 不是 junction（可能是真实目录），未动。"
        }
    }
}
Write-Output "---- 移除 $removed 个 junction ----"
Write-Output '提示: 卸载后需新开会话才生效。备份目录(.agents\skills-backup-*)不受影响。'
