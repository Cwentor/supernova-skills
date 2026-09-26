# install.ps1 — 把 my-skills 各技能 junction 到 .agents\skills
# 用法: powershell -File install.ps1 [-DryRun]
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$repo   = $PSScriptRoot | Split-Path -Parent
$target = Join-Path $env:USERPROFILE '.agents\skills'
$backup = Join-Path $env:USERPROFILE ('.agents\skills-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))

if (-not (Test-Path $target)) { New-Item -ItemType Directory -Force -Path $target | Out-Null }

# 一期被替代的旧技能（旧名 -> 新名）。安装时移入备份，避免同一意图新旧双触发。
$superseded = @{
    'ask-matt'                     = 'meta-skill-router'
    'code-review'                  = 'dev-review-code'
    'code-reviewer'                = 'dev-review-code'
    'codebase-design'              = 'dev-codebase-design'
    'diagnosing-bugs'              = 'dev-debugging'
    'domain-modeling'              = 'dev-domain-modeling'
    'git-guardrails-claude-code'   = 'dev-git-guardrails'
    'implement'                    = 'dev-executing-plans'
    'implement-spec'               = 'dev-executing-plans'
    'improve-codebase-architecture'= 'dev-improve-architecture'
    'prototype'                    = 'dev-prototype'
    'resolving-merge-conflicts'    = 'dev-git-conflicts'
    'setup-matt-pocock-skills'     = 'dev-triage'
    'setup-pre-commit'             = 'dev-setup-precommit'
    'tdd'                          = 'dev-tdd'
    'to-spec'                      = 'dev-spec'
    'to-tickets'                   = 'dev-tickets'
    'triage'                       = 'dev-triage'
    'wayfinder'                    = 'dev-tickets'
}

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

# 处理被替代的旧技能：移入备份（真实目录）或移除（旧链接），绝不硬删
foreach ($old in $superseded.Keys) {
    $p = Join-Path $target $old
    if (Test-Path $p) {
        $item = Get-Item $p -Force
        if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
            if ($DryRun) { $report.Add("[DRY] 移除被替代旧链接: $old") }
            else { $item.Delete(); $report.Add("[OK ] 移除被替代旧链接: $old") }
        }
        else {
            if ($DryRun) { $report.Add("[DRY] 备份被替代旧技能: $old (-> $($superseded[$old]))") }
            else {
                if (-not (Test-Path $backup)) { New-Item -ItemType Directory -Force -Path $backup | Out-Null }
                Move-Item $p (Join-Path $backup $old)
                $report.Add("[OK ] 备份被替代旧技能: $old (-> $($superseded[$old]))")
            }
        }
    }
}

$report | ForEach-Object { Write-Output $_ }
Write-Output ("---- 共 {0} 个技能处理完毕 {1} ----" -f $skills.Count, $(if ($DryRun) { '(DRY RUN，未动文件)' } else { '' }))
if (-not $DryRun -and (Test-Path $backup)) { Write-Output "被替换旧拷贝备份于: $backup" }
Write-Output '提示: 安装/卸载后需新开会话才生效。'
