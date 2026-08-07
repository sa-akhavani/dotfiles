-- Per-monitor workspaces, via split-monitor-workspaces.
-- https://github.com/zjeffer/split-monitor-workspaces
--
-- Hyprland's workspaces are global: workspace 2 exists in exactly one place, so
-- SUPER+2 either does nothing useful or drags focus to whichever screen happens
-- to hold it. This library gives each monitor its own 1..N — SUPER+2 is always
-- "the second workspace of the monitor I am looking at", and focus never jumps
-- between screens.
--
-- It is a pure Lua library as of Hyprland 0.55 (there is still a C++ plugin in
-- the same repo, deprecated at 0.57), so there is no hyprpm, no ABI lock and
-- nothing to rebuild when Hyprland updates within a release series. chezmoi
-- clones it — see .chezmoiexternal.toml, which also holds the release-branch
-- pin that has to be bumped on a Hyprland *major* update.
--
-- Nothing here is host-specific and nothing needs to be: the library maps
-- whatever monitors Hyprland reports and re-maps on monitor.added/removed. giv,
-- with one screen, simply gets workspaces 1-5 on it; sohrab and rostam get 1-5
-- per screen. Under the hood the second monitor's workspaces are really 6-10,
-- which is what `hyprctl workspaces` and waybar report.

-- Hyprland resolves require() against the config directory only, so the library
-- has to be on package.path by absolute path. os.getenv rather than "~" because
-- this string is never shell-expanded.
local plugins = os.getenv("HOME") .. "/.config/hypr/plugins/"
package.path = package.path .. ";" .. plugins .. "split-monitor-workspaces/lua/?.lua"

local smw = require("split-monitor-workspaces")

smw.setup({
    -- Five per monitor, matching the SUPER+1..5 binds below.
    workspace_count = 5,

    -- Which monitor gets the low workspace IDs. Monitors that aren't listed are
    -- ranked in the order Hyprland reports them, so naming only the ones on
    -- sohrab is enough — giv's eDP-1 and anything on rostam fall through to
    -- that default instead of being mis-ranked. Note sohrab's second output is
    -- DP-4, not DP-2 (`hyprctl monitors`).
    monitor_priority = { "DP-1", "DP-4" },
})

local mainMod = "SUPER"

-- Same three actions the global workspace binds had: switch to it, send the
-- active window there without following, send it and follow.
for i = 1, smw.get_amount_of_workspaces() do
    local n = tostring(i)
    hl.bind(mainMod .. " + " .. n, smw.workspace(n))
    hl.bind(mainMod .. " + SHIFT + " .. n, smw.move_to_workspace_silent(n))
    hl.bind(mainMod .. " + CONTROL + " .. n, smw.move_to_workspace(n))
end

-- Cycling, previously hl.dsp.focus({ workspace = "e+1" }) and "m+1". Both of
-- those walk Hyprland's global list and would leave this monitor's range;
-- cycle_workspaces stays inside it and wraps.
hl.bind(mainMod .. " + mouse_down", smw.cycle_workspaces("next"))
hl.bind(mainMod .. " + mouse_up", smw.cycle_workspaces("prev"))
hl.bind("ALT + tab", smw.cycle_workspaces("next"))
hl.bind("ALT + SHIFT + tab", smw.cycle_workspaces("prev"))

-- Rescue windows stranded outside any mapped workspace — after unplugging a
-- monitor, or after changing workspace_count above.
hl.bind(mainMod .. " + SHIFT + G", smw.grab_rogue_windows())
