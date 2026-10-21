# Set console & pipeline encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$global:lastRepository = $null

# Modules (Terminal-Icons requires PS 7+)
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
}
Import-Module -Name posh-git -ErrorAction SilentlyContinue

# Identity & Version
$curUser    = $env:USERNAME
$curComp    = $env:COMPUTERNAME
$psversion  = $PSVersionTable.PSVersion.ToString()
$identity   = "$curUser@$curComp".Trim()
$edition    = if ($PSVersionTable.PSEdition -eq 'Core') { "PowerShell" } else { "Windows PowerShell" }

# Window Title
if ($Host.UI.RawUI) {
    $Host.UI.RawUI.WindowTitle = "$edition v.$psversion"
}

#-----------------------------------------------------
# CONFIG
#-----------------------------------------------------
$line1      = "💻 $edition"              # First line
$line2      = "📦 Version $psversion"    # Second line
$line3      = "👻 $identity"             # Third line
$line4      = "🎉 Happy scripting! 🚀"   # Fourth line

$line1color = "Cyan"
$line2color = "White"
$line3color = "Yellow"
$line4color = "Green"

$padding    = 2

# Max length based on lines above
$lengths    = $line1.Length, $line2.Length, $line3.Length, $line4.Length
$max        = ($lengths | Measure-Object -Maximum).Maximum

#-----------------------------------------------------
# WELCOME MESSAGE
#-----------------------------------------------------
Write-Host ((" " * $padding), (" " * ($max + 1)), (" " * $padding))
Write-Host ((" " * $padding), $line1, (" " * ($max - $line1.Length)), (" " * $padding)) -ForegroundColor $line1color
Write-Host ((" " * $padding), $line2, (" " * ($max - $line2.Length)), (" " * $padding)) -ForegroundColor $line2color
Write-Host ((" " * $padding), $line3, (" " * ($max - $line3.Length)), (" " * $padding)) -ForegroundColor $line3color
Write-Host ((" " * $padding), $line4, (" " * ($max - $line4.Length)), (" " * $padding)) -ForegroundColor $line4color
Write-Host ((" " * $padding), (" " * ($max + 1)), (" " * $padding))
Write-Host ""

# Git repository greeter
function Check-DirectoryForNewRepository {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $currentRepository = git rev-parse --show-toplevel 2>$null
        if ($currentRepository -and ($currentRepository -ne $global:lastRepository)) {
            if (Get-Command onefetch -ErrorAction SilentlyContinue) {
                onefetch | Write-Host
            }
        }
        $global:lastRepository = $currentRepository
    }
}

function Set-Location {
    Microsoft.PowerShell.Management\Set-Location @args
    Check-DirectoryForNewRepository
}
Check-DirectoryForNewRepository

# Utility functions
function my_uptime {
    $boot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    if ($boot) { (Get-Date) - $boot }
}

function getMyIP {
    try {
        (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 3).Content.Trim()
    } catch {
        Write-Warning "No se pudo obtener la IP pública."
    }
}

function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    if (Test-Path -LiteralPath $tmp) {
        $cwd = Get-Content -LiteralPath $tmp -Encoding UTF8 -Raw
        if (-not [String]::IsNullOrEmpty($cwd) -and $cwd.Trim() -ne $PWD.Path) {
            Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd.Trim()))
        }
        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
    }
}

function op {
    pwsh.exe -NoProfile -Command "opencode"
}

# Aliases & shortcuts
Set-Alias -Name uptime -Value my_uptime -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name myip   -Value getMyIP   -Option AllScope -ErrorAction SilentlyContinue
if (Get-Command neovide -ErrorAction SilentlyContinue) {
    Set-Alias -Name neo -Value neovide -Option AllScope -ErrorAction SilentlyContinue
}

function ll    { Get-ChildItem -Force @args }
function which { param($bin) Get-Command $bin -ErrorAction SilentlyContinue }

# Git shortcuts
function gco   { git checkout @args }
function gts   { git status @args }
function gtc   { git commit @args }
function gta   { git add . }
function gtp   { git push @args }
function gtb   { git branch @args }
function gtco  { git checkout @args }
function gtl   { git log --oneline --graph --decorate --all }

function Watch-Command {
    [alias('watch')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$Command,
        [Parameter()]
        [int]$Delay = 2
    )
    while ($true) {
        Clear-Host
        Write-Host ("Every {1}s: {0} `n" -F $Command.ToString(), $Delay)
        & $Command
        Start-Sleep -Seconds $Delay
    }
}

# OSC 7 terminal directory reporting (WezTerm / Windows Terminal)
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
        $host.UI.Write($prompt)
    }
}

# Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& zoxide init powershell | Out-String)
}

# Starship
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
    foreach ($fn in 'Get-Cwd', 'Invoke-Native') {
        if (Test-Path "Function:\$fn") {
            Set-Item "Function:\Global:$fn" (Get-Item "Function:\$fn").ScriptBlock
        }
    }
}
