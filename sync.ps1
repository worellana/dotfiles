#Requires -Version 5.1
<#
.SYNOPSIS
  Copia las configs "de producción" (nvim, alacritty, wezterm, omp) a este repo.

.DESCRIPTION
  Solo copia, sin tocar tu entorno. El repo es la única fuente de verdad para git.
  Rutas de origen:
    nvim       %LOCALAPPDATA%\nvim                  -> nvim\windows
               WSL /home/<usuario>/.config/nvim    -> nvim\linux
    alacritty  %APPDATA%\alacritty\alacritty.toml
    wezterm    %USERPROFILE%\.wezterm.lua  y  %USERPROFILE%\.config\wezterm
    omp        %USERPROFILE%\.omp\agent\{config.yml,mcp.json,models.yml,settings.json}
    starship   %USERPROFILE%\.config\starship{,-tokyo}.toml  y
               WSL Fedora: /home/<usuario>/.config/starship.toml

.EXAMPLE
  .\sync.ps1            # copia y muestra cambios
  .\sync.ps1 -Commit    # copia y hace commit
  .\sync.ps1 -Push      # copia, commit y push
#>
[CmdletBinding()]
param(
  [switch]$Commit,
  [switch]$Push
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# WSL: se resuelve una sola vez; nvim y starship de Linux viven en ese home.
# Se accede por \\wsl.localhost para que la copia sea binaria (glifos intactos).
$wslDistro = 'FedoraLinux-44'
$linuxHome = ((& wsl -d $wslDistro -- sh -lc 'printf %s "$HOME"' 2>$null) -join '').Trim()
$wslHome = if ($linuxHome) {
  '\\wsl.localhost\{0}{1}' -f $wslDistro, $linuxHome.Replace('/', '\')
}
if (-not $wslHome) {
  Write-Warning "WSL '$wslDistro' no disponible; se omiten nvim y starship de Linux"
}

function Sync-Dir {
  param([string]$Src, [string]$Dst, [string[]]$ExcludeDirs = @())
  if (-not (Test-Path -LiteralPath $Src)) {
    Write-Warning "No existe: $Src"
    return
  }
  New-Item -ItemType Directory -Force -Path $Dst | Out-Null
  $rcArgs = @($Src, $Dst, '/MIR', '/NFL', '/NDL', '/NJH', '/NJS', '/NP')
  if ($ExcludeDirs.Count -gt 0) {
    $rcArgs += '/XD'
    $rcArgs += $ExcludeDirs
  }
  robocopy @rcArgs | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy falló ($LASTEXITCODE): $Src -> $Dst" }
  Write-Host "  OK  $Src" -ForegroundColor DarkGray
}

function Sync-File {
  param([string]$Src, [string]$Dst)
  if (-not (Test-Path -LiteralPath $Src)) {
    Write-Warning "No existe: $Src"
    return
  }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dst) | Out-Null
  Copy-Item -LiteralPath $Src -Destination $Dst -Force
  Write-Host "  OK  $Src" -ForegroundColor DarkGray
}

Write-Host 'Sincronizando configs...'
# nvim: separado por SO; linux/ es el config de la distro WSL
Sync-Dir "$env:LOCALAPPDATA\nvim" (Join-Path $root 'nvim\windows') @('.git', '.atl')
if ($wslHome) {
  Sync-Dir (Join-Path $wslHome '.config\nvim') (Join-Path $root 'nvim\linux') @('.git', '.atl')
}
Sync-File (Join-Path $env:APPDATA 'alacritty\alacritty.toml') (Join-Path $root 'alacritty\alacritty.toml')
Sync-File (Join-Path $env:USERPROFILE '.wezterm.lua') (Join-Path $root 'wezterm\wezterm.lua')
Sync-Dir (Join-Path $env:USERPROFILE '.config\wezterm') (Join-Path $root 'wezterm\config') @('.git')
foreach ($f in 'config.yml', 'mcp.json', 'models.yml', 'settings.json') {
  Sync-File (Join-Path $env:USERPROFILE ".omp\agent\$f") (Join-Path $root "omp\$f")
}

# PowerShell: PS7 usa Documents\PowerShell, PS5 usa Documents\WindowsPowerShell
foreach ($edition in 'PowerShell', 'WindowsPowerShell') {
  Sync-File (Join-Path $env:USERPROFILE "Documents\$edition\Microsoft.PowerShell_profile.ps1") `
    (Join-Path $root "powershell\$edition\Microsoft.PowerShell_profile.ps1")
}

# Starship (el tema activo y la variante tokyo)
Sync-File (Join-Path $env:USERPROFILE '.config\starship.toml') (Join-Path $root 'starship\starship.toml')
Sync-File (Join-Path $env:USERPROFILE '.config\starship-tokyo.toml') (Join-Path $root 'starship\starship-tokyo.toml')

# Starship dentro de WSL Fedora: allí se usa otro archivo (el de Windows no aplica).
if ($wslHome) {
  Sync-File (Join-Path $wslHome '.config\starship.toml') (Join-Path $root 'starship\starship-fedora.toml')
}

Push-Location $root
try {
  if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    git init | Out-Null
    Write-Host 'Repositorio git inicializado.'
  }
  $changes = git status --porcelain
  if ($changes) {
    Write-Host "`nCambios:"
    $changes | ForEach-Object { Write-Host "  $_" }
  }
  else {
    Write-Host 'Sin cambios.'
  }

  if ($Commit -or $Push) {
    if ($changes) {
      git add -A
      git commit -m "chore: sync configs $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-Host
    }
    if ($Push) { git push -u origin HEAD | Out-Host }
  }
  elseif ($changes) {
    Write-Host "`nRevisa y ejecuta: .\sync.ps1 -Commit   (o -Push)"
  }
}
finally {
  Pop-Location
}
