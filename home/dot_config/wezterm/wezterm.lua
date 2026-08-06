-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Enable this on Windows only
-- config.default_domain = 'WSL:Ubuntu-18.04'

-- Start inside tmux. `attach` with no target picks the most recently used
-- session, so opening a terminal lands back where you left off (including
-- whatever continuum restored after a reboot); `new-session` covers the
-- first window after a fresh boot.
--
-- The trailing `exec zsh` is the escape hatch, and it is deliberately the ONLY
-- `exec` here: in zsh a failing `exec` kills the shell outright, so writing
-- `exec tmux attach || ...` would make the fallback unreachable and a wezterm
-- window would just vanish if tmux ever failed to start, with no way to read
-- the error. Without the leading exec the rest of the chain actually runs.
--
-- The separator before it is `;`, NOT `||`: a clean detach (prefix + d) exits
-- 0, so with `||` the fallback was skipped, this `zsh -lc` had nothing left to
-- run, and the whole wezterm window closed — leaving nowhere to type
-- `tmux new -s <name>`. `;` runs it either way, so detaching drops you at a
-- plain shell in the same window and a failed tmux still shows its error.
--
-- For a deliberately tmux-free window: `wezterm start -- zsh`.
config.default_prog = {
	"/usr/bin/zsh",
	"-lc",
	"tmux attach || tmux new-session; exec /usr/bin/zsh",
}

-- This is where you actually apply your config choices
local fonts = {
	"FiraCode Nerd Font",
	"Vazirmatn",
	-- "Mono",
}
local emoji_fonts = { "Apple Color Emoji" }
config.font = wezterm.font_with_fallback({ fonts[1], emoji_fonts[1] })
config.font_size = 14
config.harfbuzz_features = {
	"zero",
	"cv02",
	"cv06",
	"cv29",
	"ss01",
	"ss03",
	"ss05",
	"ss06",
	-- some ligature features:
	"ss02",
	-- disable ligatures:
	-- "calt=0",
	-- "cliga=0",
	-- "liga=0",
}

config.enable_tab_bar = false

-- config.front_end = "WebGpu" -- this caused wezterm to crash on a specific monitor on hyprland
config.front_end = "OpenGL"

config.enable_scroll_bar = true
config.scrollback_lines = 10240
config.automatically_reload_config = true
config.default_cursor_style = "BlinkingBar"
config.initial_cols = 80
config.initial_rows = 25

config.window_padding = {
	left = 4,
	right = 10,
	top = 0,
	bottom = 0,
}

-- config.background = {
-- 	source = { File = { path = "/home/ali/Downloads/Backgrounds/spaceship_bg_1.png" } },
-- }
-- config.window_background_image = "/home/ali/Downloads/Alien_Ship_bg_vert_images/Backgrounds/spaceship_bg_1.png"

-- config.color_scheme = 'AdventureTime'
config.color_scheme = "OneDark"
config.window_background_opacity = 0.96
config.color_schemes = {
	["OneDark"] = {
		foreground = "#f0f6fc",
		-- background = "#1e1e1e",
		-- background = "#21262d",
		-- background = "#1e1e2e",
		background = "#1a1b26",
		-- cursor_bg = "#b1cad8",
		cursor_bg = "#FFE08C",
		cursor_fg = "#21262d",
		cursor_border = "#CF7277",
		selection_fg = "#21262d",
		-- selection_bg = "#2A4668",
		selection_bg = "#2A4668",
		-- scrollbar_thumb = "#30363d",
		scrollbar_thumb = "8b949e",
		split = "#6e7681",

		ansi = {
			"#8b949e",
			"#ff7b72",
			"#aff5b4",
			"#FFE08C",
			"#79c0ff",
			"#d2a8ff",
			"#a5d6ff",
			"#c9d1d9",
		},
		brights = {
			"#8b949e",
			"#ff7b72",
			"#aff5b4",
			"#FFE08C",
			"#79c0ff",
			"#d2a8ff",
			"#a5d6ff",
			"#c9d1d9",
		},
	},
}

-- and finally, return the configuration to wezterm
return config
