require("copilot").setup({
	server = {
		type = "binary",
		custom_server_filepath = "copilot-language-server",
	},
	panel = {
		enabled = false,
	},
	suggestion = {
		enabled = true,
		auto_trigger = true,
		hide_during_completion = true,
		keymap = {
			accept = false,
			accept_word = false,
			accept_line = false,
			next = false,
			prev = false,
			dismiss = false,
			toggle_auto_trigger = false,
		},
	},
})
