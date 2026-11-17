-- Runs inside the actual Home Manager Neovim wrapper with an isolated home.
local function run()
	local project = vim.env.NVIM_TEST_PROJECT
	assert(vim.v.errmsg == "", "startup error: " .. vim.v.errmsg)
	assert(vim.bo.filetype == "rust", "Rust filetype was not detected")
	assert(vim.env.NVIM_RUST_ANALYZER:match("^/nix/store/.*/bin/rust%-analyzer$"))
	assert(vim.lsp.config.rust_analyzer.cmd[1] == vim.env.NVIM_RUST_ANALYZER)
	assert(
		vim.wait(15000, function()
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" })) do
				if client.initialized then
					return true
				end
			end
		end, 50),
		"rust-analyzer did not initialize and attach"
	)

	vim.cmd.edit(vim.fn.fnameescape(project .. "/example.lua"))
	assert(vim.bo.filetype == "lua", "Lua filetype was not detected")
	assert(vim.api.nvim_get_current_line() == "local value = 42")
	assert(vim.v.errmsg == "", "file-opening error: " .. vim.v.errmsg)

	-- Use deterministic completion sources instead of requiring Copilot credentials.
	vim.cmd("Copilot disable")
	local cmp = require("cmp")
	for _, source in ipairs(cmp.get_registered_sources()) do
		if source.name == "copilot" then
			cmp.unregister_source(source.id)
		end
	end
	cmp.register_source("copilot", {
		complete = function(_, _, callback)
			callback({ items = { { label = "proposal", insertText = "proposal" } }, isIncomplete = false })
		end,
	})
	vim.cmd.enew()
	cmp.setup.buffer({ sources = { { name = "copilot" } }, completion = { autocomplete = false } })
	local accept_calls = 0
	require("copilot.suggestion").accept = function()
		accept_calls = accept_calls + 1
	end
	local function key(keycode)
		vim.api.nvim_input(keycode)
		coroutine.yield(200)
	end
	local function await(predicate, message)
		local deadline = vim.uv.now() + 5000
		while not predicate() do
			assert(vim.uv.now() < deadline, message)
			coroutine.yield(50)
		end
	end
	key("i")
	await(function()
		return vim.fn.mode() == "i"
	end, "insert mode not entered")
	key("<M-l>")
	await(function()
		return accept_calls == 1
	end, "inline accept not called")
	cmp.complete()
	await(cmp.visible, "completion menu did not open")
	cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
	await(function()
		return cmp.get_selected_entry() ~= nil
	end, "Copilot entry not selected")
	key("<M-l>")
	await(function()
		return not cmp.visible() and vim.api.nvim_get_current_line() == "proposal"
	end, "Alt+L did not confirm Copilot menu entry")
	assert(accept_calls == 1, "inline accept called while completion menu was open")

	cmp.register_source("other", {
		complete = function(_, _, callback)
			callback({ items = { { label = "other_result" } }, isIncomplete = false })
		end,
	})
	key("<Esc>")
	vim.cmd.enew({ bang = true })
	cmp.setup.buffer({ sources = { { name = "other" } }, completion = { autocomplete = false } })
	key("i")
	cmp.complete()
	await(cmp.visible, "other completion menu did not open")
	key("<M-l>")
	assert(cmp.visible() and accept_calls == 1, "Alt+L acted on an unselected menu")
	cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
	await(function()
		return cmp.get_selected_entry() ~= nil
	end, "other entry not selected")
	assert(cmp.get_selected_entry().source.name == "other")
	key("<M-l>")
	assert(cmp.visible() and accept_calls == 1, "Alt+L accepted a non-Copilot completion")
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local thread = coroutine.create(run)
		local function step()
			local ok, delay = coroutine.resume(thread)
			if not ok then
				io.stderr:write(debug.traceback(thread, delay) .. "\n")
				vim.cmd.cquit(1)
			elseif coroutine.status(thread) == "dead" then
				vim.cmd("qa!")
			else
				vim.defer_fn(step, delay)
			end
		end
		vim.schedule(step)
	end,
})
