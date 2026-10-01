# lint.ps1 — my-skills 质量门禁：frontmatter / 行数 / 禁用词 / 交叉引用一致性
# 用法: powershell -File scripts\lint.ps1
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot | Split-Path -Parent

# 未上线技能（一期之后的期），一期技能正文中出现即 FAIL；meta-skill-router 的「后续期」章节豁免
$future = @('meta-questionnaire','meta-handoff','meta-security-audit','meta-find-skills','meta-writing-for-agents','meta-grill-me','meta-grilling','meta-photo-get','meta-modsearch','ops-github-conventions')

$dirs = foreach ($c in @('meta','dev','lang','write','ops')) {
    Get-ChildItem (Join-Path $repo $c) -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }
}
$names = @($dirs | ForEach-Object { $_.Name })
$pass = 0; $warned = 0; $failed = 0

foreach ($d in $dirs) {
    $f = Join-Path $d.FullName 'SKILL.md'
    $lines = @(Get-Content $f)
    $issues = @()
    $end = -1
    for ($i = 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -eq '---') { $end = $i; break } }
    if ($lines.Count -lt 3 -or $lines[0] -ne '---' -or $end -lt 2) { $issues += 'FAIL: frontmatter 结构不完整' }
    else {
        $fm = @($lines[1..($end - 1)])
        $fmRaw = ($lines[0..$end] -join "`n")
        if ($fmRaw.Length -gt 1024) { $issues += ('WARN: frontmatter ' + $fmRaw.Length + ' 字符超 1024') }
        $nameLine = @($fm | Where-Object { $_ -like 'name:*' }) | Select-Object -First 1
        if (-not $nameLine) { $issues += 'FAIL: 缺 name 字段' }
        elseif (($nameLine -replace '^name:\s*', '').Trim() -ne $d.Name) { $issues += ('FAIL: name 不等于目录名 (' + $nameLine + ')') }
        $descLine = @($fm | Where-Object { $_ -like 'description:*' }) | Select-Object -First 1
        if (-not $descLine) { $issues += 'FAIL: 缺 description 字段' }
        elseif ((($fm -join ' ') -replace '.*description:\s*', '') -notmatch 'Use when') { $issues += 'WARN: description 缺英文触发句 Use when...' }
        if ($descLine) {
            $descVal = ($descLine -replace '^description:\s*', '').Trim()
            $quoted = ($descVal.Length -ge 2) -and ((($descVal.StartsWith('"')) -and ($descVal.EndsWith('"'))) -or (($descVal.StartsWith("'")) -and ($descVal.EndsWith("'"))))
            if ((-not $quoted) -and ($descVal -match ': ')) {
                $issues += 'FAIL: description 未加引号却含 ASCII 冒号+空格（YAML 纯量标量陷阱，加载器会静默丢弃本技能）——用双引号包裹整个 description'
            }
        }
        $extra = @($fm | Where-Object { $_ -match '^[A-Za-z-]+:\s' -and $_ -notmatch '^(name|description):' })
        if ($extra.Count -gt 0) { $issues += ('WARN: frontmatter 多余字段: ' + ($extra -join ' | ')) }
    }
    if ($lines.Count -gt 200) { $issues += ('WARN: 正文 ' + $lines.Count + ' 行超 200 软上限') }
    if ($end -gt 0) {
        # 禁用词检查（frontmatter 之后的正文）
        $terms = @('Claude Code', 'Claude', 'superpowers', 'Superpowers', 'Matt Pocock', 'khazix', 'Khazix', '/compact', 'DSH')
        for ($i = $end + 1; $i -lt $lines.Count; $i++) {
            foreach ($t in $terms) {
                if ($lines[$i].IndexOf($t) -ge 0) { $issues += ('WARN: 禁用词 "' + $t + '" @L' + ($i + 1)) }
            }
        }
        # 交叉引用一致性
        $bodyText = ($lines[($end + 1)..($lines.Count - 1)] -join "`n")
        $refs = @()
        $m = Select-String -InputObject $bodyText -Pattern '(meta|dev|lang|write|ops)-[a-z][a-z0-9-]*[a-z0-9]' -AllMatches
        if ($m) { foreach ($x in $m.Matches) { $refs += $x.Value } }
        $refs = @($refs | Sort-Object -Unique)
        foreach ($r in $refs) {
            if ($future -contains $r) {
                if ($d.Name -ne 'meta-skill-router') { $issues += ('FAIL: 引用未上线技能 ' + $r) }
            }
            elseif ($names -notcontains $r) { $issues += ('FAIL: 引用不存在的技能 ' + $r) }
        }
    }
    $hasFail = $false; $hasWarn = $false
    foreach ($x in $issues) { if ($x.StartsWith('FAIL')) { $hasFail = $true } elseif ($x.StartsWith('WARN')) { $hasWarn = $true } }
    $tag = 'PASS'
    if ($hasFail) { $tag = 'FAIL'; $failed++ } elseif ($hasWarn) { $tag = 'WARN'; $warned++ } else { $pass++ }
    Write-Output ('[' + $tag + '] ' + $d.Name + ' (' + $lines.Count + ' 行)')
    foreach ($x in $issues) { Write-Output ('    ' + $x) }
}
Write-Output ('---- PASS ' + $pass + ' / WARN ' + $warned + ' / FAIL ' + $failed + '，共 ' + $names.Count + ' 个已建成技能 ----')
