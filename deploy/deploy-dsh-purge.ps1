<#
  dsh-purge deployer for a fresh Windows machine.

  What it does (idempotent):
    1. checks Node >= 18
    2. locates the real DSH_HOME (the one with profiles/)
    3. clones / fast-forwards the plugin into  $DSH_HOME\plugins\dsh-purge
    4. appends dsh-purge to the target profile package.json (deps + bundles), with backup
    5. runs  bin\dsh-purge.js --apply   (the "break-the-shell" patch pass)
    6. prints status and tells you to restart the host

  Examples:
    powershell -ExecutionPolicy Bypass -File deploy-dsh-purge.ps1
    powershell -ExecutionPolicy Bypass -File deploy-dsh-purge.ps1 -Profile both
    powershell -ExecutionPolicy Bypass -File deploy-dsh-purge.ps1 -NoApply
    powershell -ExecutionPolicy Bypass -File deploy-dsh-purge.ps1 -DshHome C:\Users\me\.dsh

  Private repo note: cloning needs credentials. Run
      gh auth login
      gh auth setup-git
  once per machine, or set GITHUB_TOKEN before running.
#>
[CmdletBinding()]
param(
	[ValidateSet('auto', 'desktop', 'web', 'both')]
	[string]$Profile = 'auto',
	[string]$RepoUrl = 'https://github.com/yqcai97/local-kit.git',
	[string]$DshHome = '',
	[switch]$NoApply,
	[switch]$Force
)

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "[*] $m" }
function Ok($m) { Write-Host "[+] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "[-] $m" -ForegroundColor Red; exit 1 }

# ---------- 1. node ----------
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
	Fail 'node not found. Install Node.js >= 18 (>= 22 preferred on Windows: no console flash).'
}
$nodeVer = (& node -v).Trim()
$nodeMajor = [int](($nodeVer.TrimStart('v') -split '\.')[0])
Info "node $nodeVer"
if ($nodeMajor -lt 18) { Fail "Node $nodeVer is too old, need >= 18." }

# ---------- 2. DSH_HOME ----------
function Get-Candidates {
	$c = @()
	if ($DshHome) { $c += $DshHome }
	if ($env:DSH_HOME) { $c += $env:DSH_HOME }
	$c += (Join-Path $env:USERPROFILE '.dsh')
	$dsh = Get-Command dsh -ErrorAction SilentlyContinue
	if ($dsh) {
		$dir = Split-Path $dsh.Source
		$c += @(
			(Join-Path $dir '.dsh'),
			(Join-Path (Split-Path $dir) '.dsh'),
			(Join-Path (Split-Path (Split-Path $dir)) '.dsh')
		)
	}
	if ($env:APPDATA) { $c += (Join-Path $env:APPDATA 'DeepSeek Harness\dsh-home') }
	if ($env:LOCALAPPDATA) {
		$c += (Join-Path $env:LOCALAPPDATA 'DeepSeek Harness\dsh-home')
		$c += (Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\.dsh')
	}
	return $c | Where-Object { $_ } | Select-Object -Unique
}

# JSON helper: always decode with node so PowerShell 5.1 ANSI decoding never mangles UTF-8.
function Get-JsonField([string]$path, [string]$expr) {
	$out = & node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8').replace(/^\uFEFF/,''));console.log($expr)" $path 2>$null
	if ($LASTEXITCODE -ne 0) { return $null }
	return ([string]$out).Trim()
}

function Test-Home([string]$path) {
	if (-not $path) { return $false }
	$prof = Join-Path $path 'profiles'
	if (-not (Test-Path $prof)) { return $false }
	$any = Get-ChildItem $prof -Directory -ErrorAction SilentlyContinue |
		Where-Object { Test-Path (Join-Path $_.FullName 'package.json') }
	return [bool]$any
}

$homes = @()
if ($DshHome) {
	if (-not (Test-Home $DshHome)) { Fail "-DshHome '$DshHome' is not a DSH home (no profiles\*\package.json)." }
	$homes = @((Resolve-Path $DshHome).Path)
} else {
	foreach ($cand in Get-Candidates) {
		if (Test-Home $cand) { $homes += (Resolve-Path $cand).Path }
	}
	if (-not $homes) {
		Fail 'no DSH_HOME found (need a directory containing profiles\<name>\package.json). Pass -DshHome <path>.'
	}
	$homes = @($homes | Select-Object -Unique)
}
$home2 = $homes[0]
if ($homes.Count -gt 1) {
	Warn "multiple DSH_HOME candidates found:"
	$homes | ForEach-Object { Write-Host "      $_" }
	Warn "using the first one: $home2   (override with -DshHome)"
}
Ok "DSH_HOME = $home2"

# ---------- 3. which profiles ----------
$map = @{ 'dsh-profile-desktop' = 'desktop'; 'dsh-profile-web' = 'web' }
$found = @{}
foreach ($dir in Get-ChildItem (Join-Path $home2 'profiles') -Directory) {
	$pkgPath = Join-Path $dir.FullName 'package.json'
	if (-not (Test-Path $pkgPath)) { continue }
	$profName = Get-JsonField $pkgPath 'j.name'
	if ($profName -and $map.ContainsKey($profName)) { $found[$map[$profName]] = $dir.FullName }
}
if (-not $found.Count) { Fail 'no dsh-profile-desktop / dsh-profile-web profile found.' }

$targets = @()
switch ($Profile) {
	'auto' { if ($found.ContainsKey('desktop')) { $targets += 'desktop' } elseif ($found.ContainsKey('web')) { $targets += 'web' } }
	'both' { $targets = @($found.Keys) }
	default { if ($found.ContainsKey($Profile)) { $targets = @($Profile) } }
}
if (-not $targets.Count) {
	Warn "profile '$Profile' not present here. Available: $($found.Keys -join ', ')"
	Fail 'nothing to do.'
}
Info ("targets: " + ($targets -join ', '))

# ---------- 4. plugin checkout ----------
$pluginsDir = Join-Path $home2 'plugins'
$pluginDir = Join-Path $pluginsDir 'dsh-purge'
New-Item -ItemType Directory -Force -Path $pluginsDir | Out-Null

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) { Fail 'git not found. Install Git for Windows, or copy the repo to ' + $pluginDir + ' manually.' }

if (Test-Path (Join-Path $pluginDir '.git')) {
	if ($Force) {
		Warn "removing existing checkout $pluginDir"
		Remove-Item $pluginDir -Recurse -Force
	}
}
if (Test-Path (Join-Path $pluginDir '.git')) {
	Info "updating existing checkout"
	& git -C $pluginDir remote set-url origin $RepoUrl
	& git -C $pluginDir fetch --depth 1 origin
	if ($LASTEXITCODE -ne 0) {
		Fail 'git fetch failed. For the private repo make sure you ran: gh auth login && gh auth setup-git (or set GITHUB_TOKEN).'
	}
	& git -C $pluginDir reset --hard origin/master
	& git -C $pluginDir clean -fdx -e node_modules
} else {
	if (Test-Path $pluginDir) {
		Warn "directory exists but is not a git checkout: $pluginDir"
		if (-not $Force) { Fail 're-run with -Force to replace it.' }
		Remove-Item $pluginDir -Recurse -Force
	}
	Info "cloning $RepoUrl"
	& git clone --depth 1 $RepoUrl $pluginDir
	if ($LASTEXITCODE -ne 0) {
		Fail 'git clone failed. For the private repo make sure you ran: gh auth login && gh auth setup-git (or set GITHUB_TOKEN).'
	}
}

$plugPkgPath = Join-Path $pluginDir 'package.json'
if (-not (Test-Path $plugPkgPath)) { Fail "plugin package.json missing at $plugPkgPath" }
$plugName = Get-JsonField $plugPkgPath 'j.name'
$plugVer = Get-JsonField $plugPkgPath 'j.version'
if ($plugName -ne 'dsh-purge') { Fail "plugin package.json name must be dsh-purge (got '$plugName')" }
Ok "plugin $plugVer at $pluginDir"

# ---------- 5. profile package.json ----------
$patcher = Join-Path $pluginDir 'deploy\patch-profile.mjs'
if (-not (Test-Path $patcher)) { Fail "missing $patcher (old checkout?)" }

foreach ($name in $targets) {
	$profDir = $found[$name]
	$pkgPath = Join-Path $profDir 'package.json'
	$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
	Copy-Item $pkgPath "$pkgPath.bak-$stamp" -Force
	& node $patcher $pkgPath
	if ($LASTEXITCODE -ne 0) { Fail "failed to patch $pkgPath" }
	Ok "profile '$name' patched (backup: package.json.bak-$stamp)"
}

# ---------- 6. apply ----------
if ($NoApply) {
	Warn 'skipped --apply (-NoApply). Run it later:'
	Write-Host "      `$env:DSH_HOME='$home2'; node `"$pluginDir\bin\dsh-purge.js`" --apply"
} else {
	$env:DSH_HOME = $home2
	Info 'running bin\dsh-purge.js --apply'
	& node (Join-Path $pluginDir 'bin\dsh-purge.js') --apply
	if ($LASTEXITCODE -ne 0) { Fail 'apply failed (see output above).' }
	Ok 'apply finished'
}

# ---------- 7. status ----------
$env:DSH_HOME = $home2
& node (Join-Path $pluginDir 'bin\dsh-purge.js') --status

Write-Host ''
Ok 'Done. Now FULLY QUIT the host and start it again:'
Write-Host '      desktop : tray icon -> quit, then relaunch DeepSeek Harness'
Write-Host '      web     : stop `dsh web`, start it again'
Write-Host '    After restart, `/purge status` inside a session should list the patches'
Write-Host '    and prompt-inject.md should be seeded (~25 KB, Little Code Sauce persona).'
