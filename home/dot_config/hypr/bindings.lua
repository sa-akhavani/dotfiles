-- Keybinds. See https://wiki.hypr.land/Configuring/Basics/Binds/
--
-- hl.bind(keys, dispatcher, opts?)
--
-- Two things the old `bind = MODS, key, dispatcher, params` form did not:
--   * every modifier needs its own "+" separator. "SUPER + SHIFT + r" parses,
--     "SUPER SHIFT + r" is rejected as an unknown keysym. Mistyped modifiers
--     are caught by --verify-config; a mistyped final key is not.
--   * the old flag letters are named options now:
--       bindm -> { mouse = true }        bindl  -> { locked = true }
--       binde -> { repeating = true }    bindel -> both
--
-- Was bindings.conf + workspaces.conf.

local mainMod = "SUPER"

local scripts = os.getenv("HOME") .. "/.config/hypr/scripts/"
local screenshots = os.getenv("HOME") .. "/Pictures/Screenshots"

-- Hyprland Reload
hl.bind(mainMod .. " + SHIFT + r", hl.dsp.exec_cmd("hyprctl reload"))

-- Waybar Reload
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(scripts .. "reload_waybar.sh"))

-- Clipboard history (walker's `:` provider, served by elephant-clipboard).
-- `-m` restricts walker to a single provider, so this opens straight into the
-- history instead of the app list.
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("walker -m clipboard"))

-- App Management
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("wezterm"))
-- herdr, in a deliberately tmux-FREE window. `wezterm start -- <prog>` bypasses
-- default_prog, which otherwise drops every new window into tmux — and herdr is
-- a multiplexer itself, so running it inside tmux means two prefix keys, two
-- status bars and both of them fighting over mouse events. Plain `wezterm`
-- above is still the tmux one; these two stay separate on purpose.
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd("wezterm start -- herdr"))
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nemo"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("walker"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("hyprpicker -a")) -- -z to disable zoom

-- Window Management
-- The old `fullscreen, 1` / `fullscreen, 0` params are named modes: 1 was
-- maximize, 0 was true fullscreen.
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
-- Was $mainMod+F (conflicted with fullscreen above). Moved to $mainMod+T.
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo({ action = "toggle" })) -- dwindle
-- togglesplit stopped being a direct dispatcher in 0.54 (it was `layoutmsg`
-- under hyprlang); in Lua it is hl.dsp.layout.
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle

-- For grouping (tabbed windows)
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + tab", hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.group.prev())

-- Workspace binds (SUPER+1..5, ALT+tab, SUPER+scroll) live in workspaces.lua
-- now — they go through split-monitor-workspaces so they act on the focused
-- monitor rather than on Hyprland's one global workspace list.

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Move windows only with keyboard
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "down" }))

-- Throw the focused window at the other monitor, following it over.
--
-- "+1" is the next monitor and it wraps, so one key covers both directions on a
-- two-monitor host and is a harmless no-op on giv, where it wraps to the monitor
-- the window is already on. No host branching needed, and nothing to update when
-- an output is renamed — unlike naming DP-4 here.
--
-- The window lands on the target monitor's *active* workspace, which is what
-- keeps this compatible with the per-monitor workspaces in workspaces.lua: the
-- window ends up inside that monitor's own range rather than dragging a
-- workspace across. `hl.dsp.workspace.swap_monitors` would exchange the two
-- monitors' entire active workspaces instead — a different thing, and it leaves
-- workspaces sitting outside the range split-monitor-workspaces mapped for them
-- (SUPER+SHIFT+G to reclaim the windows if you try it).
--
-- Add `follow = false` to send it without moving focus.
hl.bind(mainMod .. " + D", hl.dsp.window.move({ monitor = "+1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize windows with keyboard.
-- `relative = true` is what makes these deltas — without it the numbers are
-- read as an absolute target size.
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))

-- Lock screen
hl.bind(mainMod .. " + l", hl.dsp.exec_cmd(scripts .. "lockscreen.sh"))

-- Change Wallpaper
hl.bind(mainMod .. " + ALT + r", hl.dsp.exec_cmd(scripts .. "wallpaper-reload.sh"))

-- Screenshot a window
hl.bind(mainMod .. " + SHIFT + p", hl.dsp.exec_cmd("hyprshot -m window -o " .. screenshots))
-- Screenshot a monitor
hl.bind(mainMod .. " + CTRL + p", hl.dsp.exec_cmd("hyprshot -m output -o " .. screenshots))
-- Screenshot a region
hl.bind(mainMod .. " + ALT + p", hl.dsp.exec_cmd("hyprshot -m region -o " .. screenshots))

-- Game mode Toggle
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd(scripts .. "gamemode.sh"))

-- Brightness Controlls (requires brightnessctl)
-- hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "brightness.sh --dec"), { locked = true })
-- hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "brightness.sh --inc"), { locked = true })

-- Media and Audio Management
-- Works even when locked ({ locked = true }); requires wireplumber.
-- Note the use of "-l 1.0" after set-volume meaning that we don't want to allow
-- the wireplumber to increase the volume above 100%.
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
-- Requires playerctl
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })

-- Workspace switching moved to workspaces.lua, which routes it through
-- split-monitor-workspaces so each monitor has its own 1-5. The plain global
-- version this replaced, if the library ever needs backing out — dropping the
-- `require("workspaces")` from hyprland.lua and uncommenting this is the whole
-- rollback:
--
-- for i = 1, 5 do
--     hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
--     hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
--     hl.bind(mainMod .. " + CONTROL + " .. i, hl.dsp.window.move({ workspace = i }))
-- end

-- Minimize windows using special workspaces
-- ## Only works for one window...
-- hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special({ name = "magic" }))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Binding for laptop lid close/open.
-- Get the switch name using `hyprctl devices`.
-- hl.bind("switch:Lid Switch", hl.dsp.exec_cmd(scripts .. "lockscreen.sh"), { locked = true })
-- Disable laptop monitor when lid is closed
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1, disable\""), { locked = true })
-- Enable laptop monitor when lid is opened
-- hl.bind("switch:off:[5a9e18a3a780]", hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1, 1920x1080@60, 0x0, 1\""), { locked = true })
