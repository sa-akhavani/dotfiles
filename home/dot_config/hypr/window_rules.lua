-- Window Rules — https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- TIP: to know the values for "class", you can use "hyprctl clients" when the
-- desired application is running and inspect its output by looking for the
-- "class:" part.
--
-- The old `windowrule = PROPERTY, MATCHER` one-liner is now a table: everything
-- being matched on goes in `match`, everything being applied sits next to it.
-- `name` is optional but makes the rule addressable — hl.window_rule returns a
-- handle with :set_enabled(), so a named rule can be toggled at runtime.
--
-- Nothing here is active; all of it was already commented out under hyprlang.

-- hl.window_rule({
--     name  = "fullscreen-border",
--     match = { fullscreen = true },
--     border_color = "rgb(040303)",
-- })

-- hl.window_rule({
--     name  = "thunar-opacity",
--     match = { class = "^([Tt]hunar)$" },
--     opacity = "0.92 0.9", -- active + inactive; two values need the string form
-- })

-- hl.window_rule({
--     name  = "spotify-workspace",
--     match = { class = "^(Spotify)$" },
--     workspace = "9 silent",
-- })

-- hl.window_rule({
--     name  = "telegram-workspace",
--     match = { class = "^(org.telegram.desktop)$" },
--     workspace = "6 silent",
-- })

-- hl.window_rule({
--     name  = "kitty-opacity",
--     match = { class = "^(kitty)$" },
--     opacity = "0.95 0.95",
-- })

-- Common modals to be set as floating
-- hl.window_rule({
--     name  = "float-polkit",
--     match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-nmtui",     -- nmtui fly
--     match = { class = "floating" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-kdeconnect",
--     match = { class = "^(org.kde.kdeconnect.*)$" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-file-dialogs",
--     match = { title = "^(Confirm to replace files)" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-file-progress",
--     match = { title = "^(File Operation Progress)" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-extract",
--     match = { title = "^(Extract archive)" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-compress",
--     match = { title = "^(Compress)" },
--     float = true,
-- })

-- Apps that are opened in floating mode
-- hl.window_rule({
--     name  = "float-telegram",
--     match = { class = "^(org.telegram.desktop)$" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-signal",
--     match = { class = "^(Signal)$" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-blueman",
--     match = { class = "^(blueman-manager)$" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-iwgtk",
--     match = { class = "^(org.twosheds.iwgtk)$" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-clight-gui",
--     match = { class = "^(clight-gui)$" },
--     float = true,
-- })

-- hl.window_rule({
--     name  = "float-pip",
--     match = { title = "^(Picture-in-Picture)$" },
--     float = true,
-- })
