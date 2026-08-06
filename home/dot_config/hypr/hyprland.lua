-- Hyprland's own config, in Lua. hyprlang (.conf) was deprecated in 0.55 and is
-- slated to be dropped a release or two later; hyprland.lua takes precedence
-- over hyprland.conf whenever both exist, so dropping this file in is the whole
-- switch, and renaming it is the whole rollback.
--
-- Upstream example:    /usr/share/hypr/hyprland.lua
-- Full API, LSP stub:  /usr/share/hypr/stubs/hl.meta.lua
-- Check before reload: Hyprland --verify-config -c <file>   (see bin/hypr-check.sh)
--
-- Only the compositor speaks Lua. hypridle, hyprlock, hyprpaper and hyprsunset
-- are separate programs and still read their own .conf files in this directory.

-- Sourced configs — the hyprlang `source =` lines. require() resolves relative
-- to this directory and takes the basename without the .lua.
require("env")
require("env_nvidia") -- chezmoi-rendered; comments only on non-nvidia hosts
require("monitor")
require("graphics")
require("input") -- input devices + gestures
require("bindings") -- keybinds, including the workspace binds
require("window_rules")

-- Scripts. Spelled out via $HOME rather than "~" because these strings are not
-- always shell-expanded.
local scripts = os.getenv("HOME") .. "/.config/hypr/scripts/"

-- Autostart. hyprlang's `exec-once` is a hyprland.start subscription now; the
-- event fires once, after the compositor is up.
hl.on("hyprland.start", function()
    -- Run fusuma for extra gestures
    -- hl.exec_cmd("ydotoold")
    -- hl.exec_cmd("fusuma")

    -- Authentication Agent Autostart
    -- hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- GTK Theme
    -- hl.exec_cmd(scripts .. "gtk.sh")

    -- Dynamic Borders Script
    -- https://github.com/devadathanmb/hyprland-smart-borders
    hl.exec_cmd(scripts .. "dynamic-borders.sh")

    -- Waybar
    hl.exec_cmd("waybar")

    -- Blue light reduction
    hl.exec_cmd("hyprsunset")

    -- Lock Screen + Idle Time
    hl.exec_cmd("hypridle")

    -- Elephant — walker's data backend. Walker is only a frontend and shows
    -- nothing at all unless this is already running, so it starts with the
    -- session rather than on first launch. It also owns the clipboard history
    -- now (the `:` prefix, bound to $mainMod+V), which is why the two
    -- `wl-paste --watch cliphist store` lines that used to live here are gone:
    -- cliphist and elephant-clipboard would each keep their own history and
    -- neither would see the other's entries.
    hl.exec_cmd("elephant")

    -- Walker in GApplication service mode. Walker is a GTK4 app, so launching
    -- the binary per keypress paid for GTK + theme init every time — visibly
    -- slow. In service mode that cost is paid once here, and the `walker` /
    -- `walker -m clipboard` binds just activate this instance, which shows up
    -- instantly. Two consequences: the config and theme CSS are read at
    -- startup, so `pkill walker; walker --gapplication-service` after editing
    -- either one; and `close_when_open = true` (walker's default) is what keeps
    -- the bind a toggle.
    hl.exec_cmd("walker --gapplication-service")

    -- Break Reminder
    -- hl.exec_cmd("ianny")

    -- Wallpaper. hyprpaper picks the first image and rotates on its own now
    -- (timeout/order in hyprpaper.conf), so wallpaper-reload.sh is no longer
    -- started here — it stays bound to Mod+Alt+R in bindings.lua for skipping
    -- manually.
    hl.exec_cmd("hyprpaper")
end)
