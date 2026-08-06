-- Input devices and gestures.
-- For all categories, see https://wiki.hypr.land/Configuring/Basics/Variables/
--
-- Was input.conf + gestures.conf; a one-line gesture file stopped earning its
-- own require().

hl.config({
    input = {
        kb_layout = "us, ir",
        kb_variant = ", pes_keypad",
        kb_options = "grp:alt_shift_toggle", -- change keyboard layout

        follow_mouse = 2, -- 1 to change focus on hover, 2 to click, 0 to disable

        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            scroll_factor = 0.55, -- 1 default
            clickfinger_behavior = true,
            drag_lock = true,
            -- hyprlang spelled this one with dashes; Lua keys are underscored
            tap_and_drag = true,
        },

        sensitivity = -0.1, -- -1.0 - 1.0, 0 means no modification.
    },
})

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
