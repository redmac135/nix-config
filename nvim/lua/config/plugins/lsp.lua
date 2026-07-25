-- Diagnostic Float
vim.diagnostic.config({
	virtual_text = {
		prefix = '●',
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

-- Root dir detection for ts projects
local util = require("lspconfig.util")

local deno_root = util.root_pattern("deno.json", "deno.jsonc")
local ts_root = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")

-- Configs
local lsps = {
	{ "rust_analyzer" },
	{ "clangd",
		{
			cmd = { "clangd", "--inlay-hints" },
			on_attach = function(client, bufnr)
				-- Enable inlay hints
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end
			end,
		},
	},
	{ "cmake" },
	{ "lua_ls",
		{
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
				},
			},
		},
	},
	{ "bashls" },
	{ "tsserver",
		{
			cmd = { "typescript-language-server", "--stdio" },
			filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
			root_dir = function(bufnr, on_dir)
				local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))

				-- do not start tsserver if in a deno project
				if deno_root(dir) then
					return
				end

				-- start tsserver if its in a ts project
				if ts_root(dir) then
					on_dir(ts_root(dir))
					return
				end

				-- fallback to single file support
				on_dir(dir)
			end,
		},
	},
	{ "denols",
		{
			root_dir = function(bufnr, on_dir)
				local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))

				-- only start denols if in a deno project
				if deno_root(dir) then
					on_dir(deno_root(dir))
					return
				end
			end,
			init_options = {
				lint = true,
				unstable = true,
			}
		},
	},
	{ "gopls" },
	{ "html" },
	{ "cssls" },
	{ "dockerls" },
	{ "yamlls" },
	{ "svelte" },
	{ "pyright",
		{
			single_file_support = true,
		}
	},
}

-- Default capabilities
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Enable all LSP servers
for _, lsp in pairs(lsps) do
	local name, config = lsp[1], lsp[2]

	config = vim.tbl_extend("force", {
		capabilities = capabilities,
	}, config or {})

	vim.lsp.config(name, config)

	vim.lsp.enable(name)
end
