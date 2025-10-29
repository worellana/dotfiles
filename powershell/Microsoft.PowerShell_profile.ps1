# Set the console output encoding to UTF-8, so that special characters are displayed correctly when piping to Write-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$global:lastRepository = $null

Import-Module -Name Terminal-Icons
Import-Module posh-git

$curUser    = (Get-ChildItem Env:\USERNAME).Value
$curComp    = (Get-ChildItem Env:\COMPUTERNAME).Value
$pvmaj      = $Host.Version.Major
$pvmin      = $Host.Version.Minor
$pvrev      = $Host.Version.Build
$psversion  = "$pvmaj.$pvmin.$pvrev"
$identity   = "$curUser@$curComp".Trim()

#$win = " "#(Get-WmiObject Win32_OperatingSystem).caption
#$osversion = " "#(Get-CimInstance Win32_OperatingSystem).Version
#$bit = " "#(Get-WmiObject Win32_OperatingSystem).OSArchitecture

#-----------------------------------------------------
# WINDOW TITLE
#-----------------------------------------------------
$Host.UI.RawUI.WindowTitle = "PowerShell v.$psversion"
#-----------------------------------------------------


#-----------------------------------------------------
# CONFIG
# Edit following to your convenience
#-----------------------------------------------------
$line1      = "💻 Windows PowerShell"    # First line
$line2      = "📦 Version $psversion"    # Second line
$line3      = "👻 $identity"             # Third line
$line4      = "🎉 Happy scripting! 🚀"         # Fourth line

$line1color = "Cyan"                     # First line color
$line2color = "White"                    # Second line color
$line3color = "Yellow"                   # Third line color
$line4color = "Green"                    # Fourth line color

$bgColor    = ''                  # Background Color
$padding    = 2                          # Padding
#-----------------------------------------------------


# Calculate max length based on four lines above
$lengths    = [array] $line1.tostring().Length, $line2.tostring().Length, $line3.tostring().Length, $line4.tostring().Length
$size       = $lengths | measure -Maximum
$max        = $size.Maximum


#-----------------------------------------------------
# WELCOME MESSAGE
#-----------------------------------------------------
Write-Host ((" " * $padding), (" " * ($max[0]+1)), (" " * $padding)) ;
Write-Host ((" " * $padding), ("$line1"), (" " * ($max[0]-($line1.Length))), (" " * $padding))  -ForegroundColor $line1color;
Write-Host ((" " * $padding), ("$line2"), (" " * ($max[0]-($line2.Length))), (" " * $padding))  -ForegroundColor $line2color;
Write-Host ((" " * $padding), ("$line3"), (" " * ($max[0]-($line3.Length))), (" " * $padding))  -ForegroundColor $line3color;
Write-Host ((" " * $padding), ("$line4"), (" " * ($max[0]-($line4.Length))), (" " * $padding))  -ForegroundColor $line4color;
Write-Host ((" " * $padding), (" " * ($max[0]+1)), (" " * $padding)) ;
Write-Host " "

# git repository greeter

function Check-DirectoryForNewRepository {
    $currentRepository = git rev-parse --show-toplevel 2>$null
    if ($currentRepository -and ($currentRepository -ne $global:lastRepository)) {
        onefetch | Write-Host
    }
    $global:lastRepository = $currentRepository
}

function Set-Location {
    Microsoft.PowerShell.Management\Set-Location @args
    Check-DirectoryForNewRepository
} # Optional: Check the repository also when opening a shell directly in a repository directory # Uncomment the following line if desired
Check-DirectoryForNewRepository

function my_uptime {
    $bootuptime = Get-CimInstance -ClassName Win32_OperatingSystem  | Select LastBootUpTime
    $uptime = $bootuptime
    return $uptime
}

function getMyIP {
    $ip = (Invoke-WebRequest ifconfig.me/ip).Content
    return $ip
}

function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
      }
    Remove-Item -Path $tmp
  }

Set-Alias -Name uptime -Value my_uptime
Set-Alias -Name myip -Value getMyIP

# A shortcut I used in unix regularly
function ll { Get-ChildItem -Force $args }

# Still allow me to use gco alias
function Get-GitCheckout {
  [alias("gco")]
  param()
  git checkout $args
}
# Regularly used in unix, but now for Windows
function which { param($bin) Get-Command $bin }
# Another unix regular that I wanted to replicate for Windows
function Watch-Command {
  [alias('watch')]
  [CmdletBinding()]
  param (
    [Parameter()]
    [ScriptBLock]
    $Command,
    [Parameter()]
    [int]
    $Delay = 2
  )
  while ($true) {
    Clear-Host
    Write-Host ("Every {1}s: {0} `n" -F $Command.toString(), $Delay)
    $Command.Invoke()
    Start-Sleep -Seconds $Delay
  }
}

$prompt = ""

function prompt {
    $currentPath = Get-Location | Select-Object -ExpandProperty Path
    $hostName = ([System.Net.Dns]::GetHostName())
    # Envía la secuencia OSC 7
    Write-Host "`e]7;file://$hostName$currentPath`e\" -NoNewline
    # Asegúrate de incluir tu prompt normal de Starship aquí, si lo usas
    # Si usas Starship, este prompt es generalmente override por `starship init powershell`
    # Lo mejor es que la línea `Write-Host` vaya *antes* de la línea de Starship.
    # Si Starship se carga después de que has definido tu prompt, es probable que tengas que
    # encontrar cómo Starship permite ganchos de pre-prompt.

    # Una mejor integración con Starship en PowerShell es un poco más compleja,
    # ya que Starship sobrescribe el prompt.
    # Puedes intentar poner la línea `Write-Host` en tu `profile.ps1` *antes*
    # de la línea `Invoke-Expression (&starship init powershell --print-full-init)`
    # o similar, si Starship permite esto.

    # Otra opción (más compatible con Starship) es hacer que Starship envíe el OSC 7.
    # En tu `starship.toml` (o similar), en la sección `format`,
    # puedes añadir algo como:
    # prompt_order = [
    #   "custom.wezterm_osc7", # Añade esto
    #   "directory",
    #   # ... el resto de tu prompt Starship ...
    # ]
    #
    # [custom.wezterm_osc7]
    # command = "printf '\\033]7;file://%s%s\\033\\' \"$(hostname)\" \"$(pwd)\""
    # shell = ["bash", "--noprofile", "--norc"] # Si ejecutas Starship en WSL/Git Bash
    # Si usas PowerShell como shell para Starship, la "command" sería diferente:
    # command = "Write-Host \"`e]7;file://$((hostname))$(Get-Location | Select-Object -ExpandProperty Path)`e`\\\" -NoNewline"
    #
    # Sin embargo, la forma más sencilla en PowerShell (si no estás overrideando `prompt`) es el primer método.
    # Si Starship está overrideando tu `prompt` en PowerShell, es posible que tengas que
    # buscar ganchos en la documentación de Starship para PowerShell para inyectar este comando.
    # Una forma de forzarlo ANTES de Starship es esto en tu profile.ps1:
    Write-Host "`e]7;file://$((hostname))$(Get-Location | Select-Object -ExpandProperty Path)`e\" -NoNewline
    # Y LUEGO, la línea de Starship.
    # Invoke-Expression (&starship init powershell --print-full-init)
}

function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}

function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}

# Set-PoshPrompt -Theme microverse-power
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
