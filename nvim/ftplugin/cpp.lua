local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.clangd.setup({
	capabilities = capabilities,
	cmd = { "clangd", "--inlay-hints" },
	on_attach = function(client, bufnr)
		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end
	end,
})
