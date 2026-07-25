require('snacks').setup({
	lazygit = { enabled = true },
	picker = { enabled = true },
	explorer = { enabled = true, auto_close = true },
	rename = { enabled = true },
})

-- overwrite default vim.ui.select
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(...)
	return require('snacks.picker').select(...)
end

-- integrate with oil
vim.api.nvim_create_autocmd("User", {
	pattern = "OilActionsPost",
	callback = function(event)
		if event.data.actions.type == "move" then
			Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
		end
	end,
})
