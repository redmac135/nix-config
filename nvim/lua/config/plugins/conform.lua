local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		python = { "ruff_fix", "ruff_format", "black" },
		lua = { "stylua" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		html = { "prettier" },
		css = { "prettier" },
		yaml = { "prettier" },
		dockerfile = { "prettier" },
	},
})
