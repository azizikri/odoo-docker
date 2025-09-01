param(
  [Parameter(Position=0)]
  [ValidateSet('help','build','setup','up')]
  [string]$Target = 'help'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[winmake] $msg" -ForegroundColor Cyan }
function Write-Err($msg)  { Write-Host "[winmake] $msg" -ForegroundColor Red }

function Ensure-Docker {
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Err 'Docker not found. Install Docker Desktop and ensure docker is on PATH.'
    exit 1
  }
}

function Load-DotEnv {
  $dotenvPath = Join-Path $PSScriptRoot '.env'
  if (Test-Path $dotenvPath) {
    Write-Info 'Loading .env'
    Get-Content $dotenvPath | ForEach-Object {
      $line = $_.Trim()
      if ($line -eq '' -or $line.StartsWith('#')) { return }
      $kv = $line -split '=',2
      if ($kv.Count -eq 2) {
        $k = $kv[0].Trim()
        $v = $kv[1].Trim().Trim('"').Trim("'")
        if ($k) { Set-Item -Path Env:$k -Value $v }
      }
    }
  }

  if (-not $env:POSTGRES_DB)       { $env:POSTGRES_DB = 'odoo' }
  if (-not $env:POSTGRES_USER)     { $env:POSTGRES_USER = 'odoo' }
  if (-not $env:POSTGRES_PASSWORD) { $env:POSTGRES_PASSWORD = 'odoo' }
  if (-not $env:ODOO_VERSION)      { $env:ODOO_VERSION = '17.0' }
}

function Invoke-Compose([string[]]$args) {
  $psi = @('compose') + $args
  Write-Info ("docker " + ($psi -join ' '))
  docker @psi
  if ($LASTEXITCODE -ne 0) { throw "docker compose command failed ($($psi -join ' '))" }
}

function Target-Build {
  Ensure-Docker
  Load-DotEnv
  try {
    Invoke-Compose @('build','--pull')
  } catch {
    Write-Info 'Build failed, trying pull instead'
    Invoke-Compose @('pull')
  }
}

function Target-Setup {
  Target-Build
  Ensure-Docker
  Load-DotEnv
  Invoke-Compose @('run','--rm','odoo',
    '-i','base','--without-demo=all','--stop-after-init',
    '--db_host=db',
    "--db_user=$($env:POSTGRES_USER)",
    "--db_password=$($env:POSTGRES_PASSWORD)",
    '-d',"$($env:POSTGRES_DB)")
}

function Target-Up {
  Ensure-Docker
  Load-DotEnv
  Invoke-Compose @('up','-d')
}

switch ($Target) {
  'help'  { Write-Host @"
winmake targets:
  build  - Build/pull images
  setup  - Initialize DB (base, no demo)
  up     - Start services in background

Usage:
  .\winmake.ps1 setup
  .\winmake.ps1 up
  winmake setup   (via .cmd wrapper)
"@; break }
  'build' { Target-Build; break }
  'setup' { Target-Setup; break }
  'up'    { Target-Up; break }
}

