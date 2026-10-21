# dotfiles

Respaldo de configuraciones. **No** es la carpeta que usan las apps: es la copia que vive en git.
La fuente real sigue siendo tu entorno (`sync.ps1` copia de producción → aquí).

## Uso

```powershell
cd $HOME\dotfiles
.\sync.ps1            # copia y muestra cambios (no commitea)
.\sync.ps1 -Commit    # copia + commit
.\sync.ps1 -Push      # copia + commit + push
```

Si PowerShell bloquea el script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\sync.ps1 -Commit
```

## Mapa de rutas

| Carpeta aquí | Origen en producción |
|---|---|
| `nvim/` | `%LOCALAPPDATA%\nvim` (excluye `.git`, `.atl`) |
| `alacritty/alacritty.toml` | `%APPDATA%\alacritty\alacritty.toml` |
| `wezterm/wezterm.lua` | `%USERPROFILE%\.wezterm.lua` |
| `wezterm/config/` | `%USERPROFILE%\.config\wezterm` (excluye `.git`) |
| `omp/config.yml` | `%USERPROFILE%\.omp\agent\config.yml` |
| `omp/mcp.json` | `%USERPROFILE%\.omp\agent\mcp.json` |
| `omp/models.yml` | `%USERPROFILE%\.omp\agent\models.yml` |
| `omp/settings.json` | `%USERPROFILE%\.omp\agent\settings.json` |
| `powershell/PowerShell/Microsoft.PowerShell_profile.ps1` | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` (PS7) |
| `powershell/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` | `%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` (PS5.1) |
| `starship/starship.toml` | `%USERPROFILE%\.config\starship.toml` |
| `starship/starship-tokyo.toml` | `%USERPROFILE%\.config\starship-tokyo.toml` (tema alternativo) |

No se respaldan bases de datos ni cachés de omp (`agent.db`, `history.db`, `models.db`, `sessions/`, `blobs/`, `cache/`, `terminal-sessions/`), ni `%APPDATA%\wezterm\plugins` (se descargan solos).

## Restaurar en otra máquina

```powershell
git clone <url> $HOME\dotfiles
robocopy $HOME\dotfiles\nvim $env:LOCALAPPDATA\nvim /MIR
robocopy $HOME\dotfiles\wezterm\config $HOME\.config\wezterm /MIR
Copy-Item $HOME\dotfiles\wezterm\wezterm.lua $HOME\.wezterm.lua
robocopy $HOME\dotfiles\alacritty $env:APPDATA\alacritty /MIR
$o = "$HOME\.omp\agent"; New-Item -ItemType Directory -Force $o | Out-Null
Copy-Item $HOME\dotfiles\omp\* $o
Copy-Item $HOME\dotfiles\powershell\PowerShell\Microsoft.PowerShell_profile.ps1 "$HOME\Documents\PowerShell\" -Force
Copy-Item $HOME\dotfiles\powershell\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 "$HOME\Documents\WindowsPowerShell\" -Force
Copy-Item $HOME\dotfiles\starship\starship.toml $HOME\.config\ -Force
```

Neovim usa LazyVim: al abrirlo reinstala plugins según `nvim/lazy-lock.json`.
