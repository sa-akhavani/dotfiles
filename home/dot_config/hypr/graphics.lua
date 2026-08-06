-- Look and feel. See https://wiki.hypr.land/Configuring/Basics/Variables/
--
-- Every hyprlang section (general {}, decoration {}, misc {} …) is a key in the
-- table passed to hl.config. Unknown keys and wrong value types are hard errors
-- at parse time, which `Hyprland --verify-config` will show you.

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        -- gaps_in  = 2,
        -- gaps_out = 5,
        border_size = 1,

        col = {
            -- A multi-colour border is a gradient table; a single colour is
            -- just a string.
            active_border = { colors = { "rgba(0fc044ee)", "rgba(1793d1ee)" } },
            inactive_border = "rgba(595959aa)",
        },

        layout = "dwindle",
    },

    decoration = {
        rounding = 0,

        blur = {
            enabled = false,
            size = 3,
            passes = 1,
            new_optimizations = true,
        },

        -- shadow = {
        --     enabled      = false,
        --     range        = 4,
        --     render_power = 3,
        --     color        = "rgba(1a1a1aee)",
        -- },
    },

    animations = {
        enabled = true,
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
    -- NOTE: `pseudotile` was removed as a dwindle option in Hyprland 0.55.
    -- Pseudotiling is now per-window: use the `pseudo` dispatcher (bound to
    -- $mainMod + P in bindings.lua) or a window rule.
    dwindle = {
        preserve_split = true, -- you probably want this
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
    -- master = {
    --     new_status = "master",
    -- },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        -- `vfr` moved from misc -> debug in a recent Hyprland (now `debug.vfr`,
        -- default already true). Removed here; set it under `debug` if you ever
        -- need to force it.
        vrr = 2, -- Adaptive Sync for monitor, 0=off, 1=on, 2=fullscreen only
        -- mouse_move_enables_dpms = true, -- wake up when mouse moves
        -- enable_swallow = true,
        -- swallow_regex   = "^(kitty)$",
        font_family = "Noto Sans",
    },

    -- Electron apps don't really support Wayland so they fall back to using
    -- Xwayland. And Xwayland doesn't support scaling at all (in rootless mode
    -- at least, for now).
    xwayland = {
        force_zero_scaling = true,
    },
})

-- Animation curves, then the animations that use them.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
--
-- hyprlang's `animation = NAME, ONOFF, SPEED, CURVE, STYLE` is spelled out:
-- leaf/enabled/speed/bezier/style.
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
