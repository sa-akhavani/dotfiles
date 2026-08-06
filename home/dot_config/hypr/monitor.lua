-- https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- hyprctl monitors all
--
-- The hyprlang form was: monitor = output, resolution@fps, position, scale
-- Positions accept negative values, "auto", "auto-left", "auto-right".
--
-- Rotating
-- hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 1, transform = 1 })
-- Mirroring
-- hl.monitor({ output = "DP-3", mode = "1920x1080@60", position = "0x0", scale = 1, mirror = "DP-2" })
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, mirror = "DP-1" })

-- fallback rule — an empty output matches every monitor not named below
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- laptop
-- hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
-- hl.monitor({ output = "eDP-1", disabled = true })

-- AW
-- hl.monitor({ output = "DP-1", mode = "1920x1080@240", position = "1920x0", scale = 1 })
-- hl.monitor({ output = "DP-1", mode = "1920x1080@240", position = "auto-right", scale = 1 })
-- hl.monitor({ output = "DP-1", disabled = true })

-- Work
hl.monitor({ output = "DP-1", mode = "highres", position = "0x0", scale = 1.5 })
hl.monitor({ output = "DP-2", mode = "highres", position = "auto-right", scale = 1.5 })

-- Home Setup
-- hl.monitor({ output = "DP-1", mode = "highres", position = "auto-left", scale = 1 })
-- hl.monitor({ output = "DP-2", mode = "highres", position = "0x0", scale = 1 })
