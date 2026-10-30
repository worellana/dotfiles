# Set console & pipeline encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$global:lastRepository = $null

# Modules (Terminal-Icons requires PS 7+)
if ($PSVersionTable.PSVersion.Major -ge 7)
{
    Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue

    # PS 7.6 pinta los directorios con fondo azul (ESC[44;1m) en Get-ChildItem.
    # Como en Linux: azul en primer plano, sin fondo.
    $PSStyle.FileInfo.Directory = "$($PSStyle.Foreground.Blue)$($PSStyle.Bold)"

    # Errores: una sola línea SIEMPRE (incluso dentro de scripts y funciones).
    # CategoryView sacrifica la frase explicativa; `err` la muestra bajo demanda.
    $ErrorView = 'CategoryView'
    $PSStyle.Formatting.Error = $PSStyle.Foreground.FromRgb(0xf7768e)
    $PSStyle.Formatting.ErrorAccent = $PSStyle.Foreground.FromRgb(0xbb9af7)
    $PSStyle.Formatting.Warning = $PSStyle.Foreground.FromRgb(0xe0af68)
}
Import-Module -Name posh-git -ErrorAction SilentlyContinue

# Identity & Version
$curUser    = $env:USERNAME
$curComp    = $env:COMPUTERNAME
$psversion  = $PSVersionTable.PSVersion.ToString()
$identity   = "$curUser@$curComp".Trim()
$edition    = if ($PSVersionTable.PSEdition -eq 'Core')
{ "PowerShell" 
} else
{ "Windows PowerShell" 
}

# Window Title
if ($Host.UI.RawUI)
{
    $termName    = $edition
    $termVersion = $psversion

    # ALACRITTY_LOG solo existe si el shell corre dentro de Alacritty.
    # La versión se pregunta al binario para que siga siendo correcta tras
    # cada actualización (TOML no permite interpolar valores).
    if ($env:ALACRITTY_LOG -and (Get-Command alacritty -ErrorAction SilentlyContinue))
    {
        $raw = alacritty --version | Out-String
        if ($raw -match 'alacritty\s+v?(\d[\w.\-]*)')
        {
            $termName    = 'Alacritty'
            $termVersion = $Matches[1]
        }
    }

    $Host.UI.RawUI.WindowTitle = "$termName v.$termVersion"
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
function Check-DirectoryForNewRepository
{
    if (Get-Command git -ErrorAction SilentlyContinue)
    {
        $currentRepository = git rev-parse --show-toplevel 2>$null
        if ($currentRepository -and ($currentRepository -ne $global:lastRepository))
        {
            if (Get-Command onefetch -ErrorAction SilentlyContinue)
            {
                onefetch | Write-Host
            }
        }
        $global:lastRepository = $currentRepository
    }
}

function Set-Location
{
    try
    {
        Microsoft.PowerShell.Management\Set-Location @args -ErrorAction Stop
    }
    catch
    {
        # Una línea, estilo `cd` de Linux.
        $target = $_.CategoryInfo.TargetName
        $text = if ($_.CategoryInfo.Category -eq 'ObjectNotFound' -and $target)
        { "cd: no existe '$target'" }
        else
        { "cd: $($_.Exception.Message)" }

        Write-Host "$($PSStyle.Foreground.FromRgb(0xf7768e))$text$($PSStyle.Reset)"
        return
    }
    Check-DirectoryForNewRepository
}
Check-DirectoryForNewRepository

# Utility functions
function my_uptime
{
    $boot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    if ($boot)
    { (Get-Date) - $boot 
    }
}

function getMyIP
{
    try
    {
        (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 3).Content.Trim()
    } catch
    {
        Write-Warning "No se pudo obtener la IP pública."
    }
}

# y [ruta] : abre yazi y al salir cambia el directorio del shell al que dejaste.
# Sin argumentos empieza en el cwd; con argumento (y C:/, y ~/dev) empieza ahí.
function y
{
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$StartPath)

    $tmp = [System.IO.Path]::GetTempFileName()
    $where = if ($StartPath) { $StartPath } else { $PWD.Path }
    yazi $where --cwd-file="$tmp"
    if (Test-Path -LiteralPath $tmp)
    {
        $cwd = Get-Content -LiteralPath $tmp -Encoding UTF8 -Raw
        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
        if (-not [String]::IsNullOrWhiteSpace($cwd) -and $cwd.Trim() -ne $PWD.Path)
        {
            Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd.Trim()))
        }
    }
}
Set-Alias -Name yy -Value y -Option AllScope -ErrorAction SilentlyContinue

#setx ANDROID_SDK_ROOT "C:\tools\Android\Sdk"
#setx PATH "$env:PATH;C:\tools\Android\Sdk\cmdline-tools\latest\bin;C:\tools\Android\Sdk\platform-tools;C:\tools\Android\Sdk\emulator"

# Aliases & shortcuts
Set-Alias -Name uptime -Value my_uptime -Option AllScope -ErrorAction SilentlyContinue
Set-Alias -Name myip   -Value getMyIP   -Option AllScope -ErrorAction SilentlyContinue
if (Get-Command neovide -ErrorAction SilentlyContinue)
{
    Set-Alias -Name neo -Value neovide -Option AllScope -ErrorAction SilentlyContinue
    #    Set-Alias -Name nv -Value neovide -Option AllScope -ErrorAction SilentlyContinue
}

#-----------------------------------------------------
# ls estilo Linux (eza): corto por defecto, -l largo, iconos
#-----------------------------------------------------
if (Get-Command eza -ErrorAction SilentlyContinue)
{
    # El alias 'ls' del sistema tiene prioridad sobre una función: hay que quitarlo.
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

    function ls
    {
        $flags = @()
        $targets = @()
        $sawPath = $false

        foreach ($a in $args)
        {
            if ($a -is [string] -and $a.StartsWith('-'))
            {
                $flags += $a
            }
            elseif ($a -is [string] -and $a -match '[*?\[]')
            {
                # eza no expande globs; que los expanda PowerShell.
                # Rutas relativas para que la salida no muestre C:\... completos.
                $sawPath = $true
                foreach ($m in @(Get-Item -Path $a -ErrorAction SilentlyContinue))
                {
                    $targets += [System.IO.Path]::GetRelativePath($PWD.Path, $m.FullName)
                }
            }
            else
            {
                $sawPath = $true
                $targets += $a
            }
        }

        if ($targets.Count -eq 0)
        {
            # Glob sin coincidencias: no listar el cwd por accidente.
            if ($sawPath) { return }

            # eza sin argumentos no emite nada cuando stdout no es una consola;
            # con "." explícito funciona siempre.
            $targets = @('.')
        }

        eza --icons=auto --group-directories-first --color=auto @flags @targets
    }

    # ll = lista larga con archivos ocultos (como el alias de Linux)
    function ll
    {
        ls -lah @args
    }
}
# err [n]: frase completa del último error (o del n anterior). CategoryView
# solo muestra la categoría y el tipo de excepción.
function err
{
    param([int]$Index = 0)
    if ($Error.Count -le $Index) { return }
    Write-Host $Error[$Index].Exception.Message
}

function which
{ param($bin) Get-Command $bin -ErrorAction SilentlyContinue 
}

# Git shortcuts
function gco
{ git checkout @args 
}
function gts
{ git status @args 
}
function gtc
{ git commit @args 
}
function gta
{ git add . 
}
function gtp
{ git push @args 
}
function gtb
{ git branch @args 
}
function gtco
{ git checkout @args 
}
function gtl
{ git log --oneline --graph --decorate --all 
}

function Watch-Command
{
    [alias('watch')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$Command,
        [Parameter()]
        [int]$Delay = 2
    )
    while ($true)
    {
        Clear-Host
        Write-Host ("Every {1}s: {0} `n" -F $Command.ToString(), $Delay)
        & $Command
        Start-Sleep -Seconds $Delay
    }
}

# OSC 7 terminal directory reporting (WezTerm / Windows Terminal)
function Invoke-Starship-PreCommand
{
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem")
    {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
        $host.UI.Write($prompt)
    }
}

function omp4
{ omp --model ollama/qwen3-4b-16k --thinking off @args 
}

# Forzar predicciones si estamos dentro de psmux
if ($env:TMUX -or $env:PSMUX)
{
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
}

# fd [comando...] : abre Fedora WSL en el directorio actual de PowerShell.
# Sin argumentos inicia la shell por defecto; con argumentos los ejecuta allí.
# Nota: sombrea a fd.exe (fd-find); los handlers de abajo lo llaman explícito.
function fd
{
    if ($PWD.Provider.Name -ne 'FileSystem')
    {
        Write-Warning "fd: el directorio actual no es del sistema de archivos."
        return
    }

    if ($args.Count -gt 0)
    {
        wsl.exe -d FedoraLinux-44 --cd $PWD.ProviderPath -- @args
    }
    else
    {
        wsl.exe -d FedoraLinux-44 --cd $PWD.ProviderPath
    }
}

#-----------------------------------------------------
# NAVEGACIÓN: fzf + fd desde la línea de comandos
#-----------------------------------------------------
if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Command fd.exe -ErrorAction SilentlyContinue))
{
    # Ctrl+T: inserta en la línea las rutas de archivos elegidas (Tab = multiselección)
    Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
        $picked = fd.exe --hidden --exclude .git --type f 2>$null |
            fzf --height 60% --layout reverse --multi --prompt 'file> '
        if ($picked)
        {
            $quoted = foreach ($p in $picked) { "'" + ($p -replace "'", "''") + "'" }
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($quoted -join ' '))
        }
    }

    # Alt+C: salta a un directorio elegido con fzf (equivalente al Alt+C de bash/zsh)
    Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
        $dir = fd.exe --hidden --exclude .git --type d 2>$null |
            fzf --height 60% --layout reverse --prompt 'dir> '
        if ($dir)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cd '" + ($dir -replace "'", "''") + "'")
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
    }
}

# Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue)
{
    Invoke-Expression (& zoxide init powershell | Out-String)
}

# Starship
if (Get-Command starship -ErrorAction SilentlyContinue)
{
    Invoke-Expression (& starship init powershell)
    foreach ($fn in 'Get-Cwd', 'Invoke-Native')
    {
        if (Test-Path "Function:\$fn")
        {
            Set-Item "Function:\Global:$fn" (Get-Item "Function:\$fn").ScriptBlock
        }
    }
}
