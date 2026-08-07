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

-- Work (sohrab). The second output is DP-4, not DP-2 — DP-2 exists on no host
-- here, so this rule never matched and the 1440p panel was silently picking up
-- the empty-output fallback above instead. Check `hyprctl monitors` before
-- trusting a name; they are per-machine and not contiguous.
--
-- Deliberately different scales. DP-1 is a 27" 4K (U2718Q) and needs 1.5, which
-- makes it 2560x1440 logical — that is what puts DP-4 at x=2560 under
-- auto-right. DP-4 is a 24" 1440p (P2416D) and is already right at 1:1; 1.5
-- there would render it 1707x960. Scale 1 is spelled out rather than left to the
-- fallback so the pair is readable as a pair.
hl.monitor({ output = "DP-1", mode = "highres", position = "0x0", scale = 1.5 })
hl.monitor({ output = "DP-4", mode = "highres", position = "auto-right", scale = 1 })

-- Home Setup
-- hl.monitor({ output = "DP-1", mode = "highres", position = "auto-left", scale = 1 })
-- hl.monitor({ output = "DP-2", mode = "highres", position = "0x0", scale = 1 })
