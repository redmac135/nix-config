-- VIM KEYMAPS --

-- Format
local conform = require("conform")
vim.keymap.set("n", "<leader>fm", function()
	conform.format({ lsp_fallback = true })
end, { desc = "Format Document", noremap = true, silent = true })

-- Clear search highlight
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR><Esc>", { desc = "Clear search highlight", noremap = true, silent = true })

-- Show code actions
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action", noremap = true })

-- Show line diagnostics in a popup
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics", noremap = true })

-- Go to definition
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to Definition", noremap = true })

-- Find references
vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, { desc = "Find References", noremap = true })

-- Jump to type definition
vim.keymap.set("n", "<leader>gt", vim.lsp.buf.type_definition, { desc = "Type Definition", noremap = true })

-- Rename symbol
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Symbol", noremap = true })

-- OIL KEYMAPS --
vim.keymap.set("n", "<C-N>", ":Oil<CR>") -- Open Oil

-- MINI KEYMAPS --
local comment = require("mini.comment")

-- Normal mode: toggle current line
vim.keymap.set("n", "<leader>/", function()
	comment.toggle_lines(vim.fn.line("."), vim.fn.line("."))
end, { desc = "Toggle comment (line)" })

-- Visual mode: toggle selection
vim.keymap.set("x", "<leader>/", function()
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	-- Ensure start <= end
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	comment.toggle_lines(start_line, end_line)
end, { desc = "Toggle comment (selection)" })

-- CMP KEYMAPS --
-- (Handled in cmp.lua)

-- COPILOT KEYMAPS --
local copilot_suggestion = require("copilot.suggestion")
vim.keymap.set("i", "<M-l>", copilot_suggestion.accept, { desc = "Accept Copilot suggestion" })
vim.keymap.set("i", "<M-]>", copilot_suggestion.next, { desc = "Next Copilot suggestion" })
vim.keymap.set("i", "<M-[>", copilot_suggestion.prev, { desc = "Previous Copilot suggestion" })
vim.keymap.set("i", "<C-]>", copilot_suggestion.dismiss, { desc = "Dismiss Copilot suggestion" })

-- SNACKS LAZYGIT KEYMAPS --
vim.keymap.set("n", "<leader>lg", function()
	Snacks.lazygit.open()
end, { desc = "Open Lazygit", noremap = true, silent = true })

-- SNACKS PICKER KEYMAPS --
vim.keymap.set("n", "<leader>ff", function()
	Snacks.picker.files()
end, { desc = "Pick Find Files" })
vim.keymap.set("n", "<leader>fh", function()
	Snacks.picker.help()
end, { desc = "Pick Help Tags" })
vim.keymap.set("n", "<leader>fw", function()
	Snacks.picker.grep()
end, { desc = "Pick Live Grep" })
vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Pick Buffers" })
vim.keymap.set("n", "<leader>fd", function()
	Snacks.picker.diagnostics()
end, { desc = "Pick Diagnostics" })
vim.keymap.set("n", "<leader>fc", function()
	Snacks.picker.commands()
end, { desc = "Pick Commands" })
vim.keymap.set("n", "<leader>fo", function()
	Snacks.picker.recent()
end, { desc = "Pick Recent Files" })
vim.keymap.set("n", "<leader>gs", function()
	Snacks.picker.git_status()
end, { desc = "Pick Git Status" })

-- SNACKS EXPLORER KEYMAPS --
vim.keymap.set("n", "<leader>e", function()
	Snacks.explorer.open()
end, { desc = "Open Snacks Explorer", noremap = true, silent = true })

-- IMAGE PREVIEW KEYMAPS --
local function image_under_cursor()
	if vim.bo.filetype == "oil" then
		local oil = require("oil")
		local entry = oil.get_cursor_entry()
		local directory = oil.get_current_dir()
		if entry and entry.type == "file" and directory then
			return vim.fs.joinpath(directory, entry.name)
		end
		return nil
	end

	local file = vim.api.nvim_buf_get_name(0)
	return file ~= "" and file or nil
end

vim.keymap.set("n", "<leader>iv", function()
	local file = image_under_cursor()
	if not file or vim.fn.filereadable(file) ~= 1 then
		vim.notify("No image file under cursor", vim.log.levels.WARN)
		return
	end
	if vim.fn.executable("chafa") ~= 1 then
		vim.notify("chafa is not installed; rebuild the Home Manager configuration", vim.log.levels.ERROR)
		return
	end

	Snacks.terminal.open({
		"chafa",
		"--format=symbols",
		"--colors=full",
		"--animate=off",
		"--size=80x40",
		file,
	}, {
		interactive = false,
		auto_close = false,
		win = {
			position = "float",
			width = 0.9,
			height = 0.8,
			border = "rounded",
			title = " Image Preview ",
			title_pos = "center",
		},
	})
end, { desc = "Preview image under cursor", noremap = true, silent = true })
