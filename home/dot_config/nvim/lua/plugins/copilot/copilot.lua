-- Copilot is consumed as a blink.cmp source (see lua/plugins/blink.lua), so its
-- own inline suggestion and panel UIs are off: with suggestion.enabled the same
-- completion arrived twice, once as ghost text and once as a menu entry, each
-- with its own accept key.
--
-- copilot_node_command is gone with them — current copilot.lua talks to the
-- copilot-language-server binary it vendors and no longer shells out to Node.
return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		suggestion = { enabled = false },
		panel = { enabled = false },
		filetypes = {
			markdown = true,
			help = true,
			yaml = false,
			gitcommit = false,
			gitrebase = false,
			hgcommit = false,
			svn = false,
			cvs = false,
			["."] = false,
		},
	},
}
