-- Windows-only helpers to focus the Godot game window when a DAP session
-- starts, and to give the focus back to the editor when it ends.
local M = {}

M.saved = nil
M.game = nil

local is_windows = vim.fn.has("win32") == 1

local ps = { "powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command" }

-- Small user32 wrapper, loaded once per PowerShell process.
local win32_api = [[
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class NVimWinFocus {
  public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
}
'@
]]

local function run(script, opts)
  if not is_windows then return end
  vim.system(vim.list_extend({ unpack(ps) }, { script }), opts or {}, function() end)
end

--- Focus the newest visible Godot game window whose title contains `match`
--- (empty = any Godot window except the editor). Remembers the window that
--- had the focus before, so M.restore() can give it back.
function M.focus_game(match)
  if not is_windows then return end
  local safe = (match or ""):gsub("'", "''")
  local script = win32_api
    .. string.format(
      [[
$match = '%s'
$fg = [NVimWinFocus]::GetForegroundWindow()
Write-Output ("FG=" + $fg.ToInt64())
$deadline = (Get-Date).AddSeconds(20)
$found = [IntPtr]::Zero
while ((Get-Date) -lt $deadline -and $found -eq [IntPtr]::Zero) {
  $script:top = [IntPtr]::Zero
  $script:any = [IntPtr]::Zero
  $cb = [NVimWinFocus+EnumProc]{
    param($h, $l)
    if (-not [NVimWinFocus]::IsWindowVisible($h)) { return $true }
    $c = New-Object System.Text.StringBuilder 64
    [void][NVimWinFocus]::GetClassName($h, $c, 64)
    if ($c.ToString() -ne 'Engine') { return $true }
    $t = New-Object System.Text.StringBuilder 512
    [void][NVimWinFocus]::GetWindowText($h, $t, 512)
    $title = $t.ToString()
    if (-not $title -or $title -match 'Godot Engine') { return $true }
    if ($match -ne '' -and $title -notlike "*$match*") { return $true }
    $script:any = $h
    if ([NVimWinFocus]::GetWindow($h, 4) -eq [IntPtr]::Zero) { $script:top = $h }
    return $true
  }
  [void][NVimWinFocus]::EnumWindows($cb, [IntPtr]::Zero)
  if ($script:top -ne [IntPtr]::Zero) { $found = $script:top }
  elseif ($script:any -ne [IntPtr]::Zero) { $found = $script:any }
  if ($found -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 200 }
}
if ($found -ne [IntPtr]::Zero) {
  [void][NVimWinFocus]::ShowWindow($found, 9)
  [void][NVimWinFocus]::SetForegroundWindow($found)
  Write-Output ("GAME=" + $found.ToInt64())
} else {
  Write-Output "GAME=0"
}
]],
      safe
    )

  local acc = {}
  run(script, {
    stdout = function(_, data)
      if not data then return end
      acc[#acc + 1] = data
      local out = table.concat(acc)
      local fg = out:match("FG=(%d+)")
      if fg then M.saved = tonumber(fg) end
      local game = out:match("GAME=(%d+)")
      if game then M.game = tonumber(game) end
    end,
  })
end

--- Give the focus back to the window that had it before the game started.
function M.restore()
  if not is_windows or not M.saved then return end
  local script = win32_api
    .. string.format(
      [[
$h = [IntPtr]%d
if ($h -ne [IntPtr]::Zero) {
  [void][NVimWinFocus]::ShowWindow($h, 9)
  [void][NVimWinFocus]::SetForegroundWindow($h)
}
]],
      M.saved
    )
  run(script)
end

return M
