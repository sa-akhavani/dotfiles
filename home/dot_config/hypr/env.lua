-- Environment Variables
hl.env("XCURSOR_SIZE", "30")

-- XDG Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkit Backend
hl.env("GDK_BACKEND", "wayland,x11") -- use x11 when Wayland not available
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- Qt
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- FF
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Change default hyprshot dir (screenshot binds also pass -o explicitly).
-- Built from $HOME here because hl.env does no shell expansion of its own.
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")
