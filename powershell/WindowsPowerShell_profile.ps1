#Import-Module -Name Terminal-Icons

$curUser    = (Get-ChildItem Env:\USERNAME).Value
$curComp    = (Get-ChildItem Env:\COMPUTERNAME).Value
$pvmaj      = $Host.Version.Major
$pvmin      = $Host.Version.Minor
$psversion  = "$pvmaj.$pvmin"
$identity   = "$curUser@$curComp"

#-----------------------------------------------------
# WINDOW TITLE
#-----------------------------------------------------
$Host.UI.RawUI.WindowTitle = "PowerShell v.$psversion"
#-----------------------------------------------------


#-----------------------------------------------------
# CONFIG
# Edit following to your convenience
#-----------------------------------------------------
#$line1      = "💻 Windows PowerShell"    # First line
#$line2      = "📦 Version $psversion"    # Second line
#$line3      = "👨 $identity"             # Third line
#$line4      = "🎉 Happy coding!"         # Fourth line

#$line1      = "Windows PowerShell"    # First line
#$line2      = "Version $psversion"    # Second line
#$line3      = "$identity"             # Third line
#$line4      = "Happy coding!"         # Fourth line

$line1color = "Cyan"                     # First line color
$line2color = "White"                    # Second line color
$line3color = "Yellow"                   # Third line color
$line4color = "Green"                    # Fourth line color

$bgColor    = ''                  # Background Color
$padding    = 2                          # Padding
#-----------------------------------------------------


# Calculate max length based on four lines above
#$lengths    = [array] $line1.tostring().Length, $line2.tostring().Length, $line3.tostring().Length, $line4.tostring().Length
#$size       = $lengths | measure -Maximum
#$max        = $size.Maximum


#-----------------------------------------------------
# WELCOME MESSAGE
#-----------------------------------------------------
#Write-Host ((" " * $padding), (" " * ($max[0]+1)), (" " * $padding)) ;
#Write-Host ((" " * $padding), ("$line1"), (" " * ($max[0]-($line1.Length))), (" " * $padding))  -ForegroundColor $line1color;
#Write-Host ((" " * $padding), ("$line2"), (" " * ($max[0]-($line2.Length))), (" " * $padding))  -ForegroundColor $line2color;
#Write-Host ((" " * $padding), ("$line3"), (" " * ($max[0]-($line3.Length))), (" " * $padding))  -ForegroundColor $line3color;
#Write-Host ((" " * $padding), ("$line4"), (" " * ($max[0]-($line4.Length))), (" " * $padding))  -ForegroundColor $line4color;
#Write-Host ((" " * $padding), (" " * ($max[0]+1)), (" " * $padding)) ;
#Write-Host " "


# Set-PoshPrompt -Theme microverse-power
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
Invoke-Expression (&starship init powershell)
