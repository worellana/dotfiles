# Mis Dotfiles

Este repositorio contiene mis archivos de configuración personal para varias herramientas que utilizo en mi entorno de desarrollo.

## Contenido

*   **Wezterm:** Archivos de configuración para el emulador de terminal Wezterm.
*   **Starship:** Configuración para el prompt de shell personalizable Starship.
*   **PowerShell:** Perfiles de configuración para PowerShell.

## Uso

Para usar estos dotfiles en un nuevo sistema, puedes clonar este repositorio:

```bash
git clone https://github.com/worellana/dotfiles.git ~/.dotfiles
```

Luego, puedes copiar o enlazar simbólicamente los archivos a sus ubicaciones respectivas. Por ejemplo:

*   **Wezterm:**
    ```bash
    cp ~/.dotfiles/wezterm/.wezterm.lua ~/.wezterm.lua
    cp ~/.dotfiles/wezterm/keys.lua ~/.wezterm/keys.lua
    # ... y así sucesivamente para los demás archivos de Wezterm
    ```
*   **Starship:**
    ```bash
    cp ~/.dotfiles/starship/starship.toml ~/.config/starship.toml
    ```
*   **PowerShell:**
    ```bash
    cp ~/.dotfiles/powershell/Microsoft.PowerShell_profile.ps1 ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
    cp ~/.dotfiles/powershell/WindowsPowerShell_profile.ps1 ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
    ```

**Nota:** Asegúrate de que los directorios de destino existan antes de copiar los archivos (por ejemplo, `~/.config` para Starship).

---
