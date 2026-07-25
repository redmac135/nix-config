local lspconfig = require("lspconfig")
local util = require("lspconfig.util")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local deno_root = util.root_pattern("deno.json", "deno.jsonc")
local ts_root = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")

-- TypeScript / JS Server (ts_ls replaces deprecated tsserver)
lspconfig.ts_ls.setup({
	capabilities = capabilities,
	cmd = { "typescript-language-server", "--stdio" },
	root_dir = function(bufnr, on_dir)
		local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))

		if deno_root(dir) then
			return
		end

		if ts_root(dir) then
			on_dir(ts_root(dir))
			return
		end

		on_dir(dir)
	end,
})

-- Deno Server
lspconfig.denols.setup({
	capabilities = capabilities,
	root_dir = function(bufnr, on_dir)
		local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))

		if deno_root(dir) then
			on_dir(deno_root(dir))
			return
		end
	end,
	init_options = {
		lint = true,
		unstable = true,
	},
})
