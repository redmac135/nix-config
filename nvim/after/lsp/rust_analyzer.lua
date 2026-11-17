-- The Nix wrapper pins the server independently of rustup and mise shims.
local rust_analyzer = vim.env.NVIM_RUST_ANALYZER
if rust_analyzer and rust_analyzer ~= "" then
	return { cmd = { rust_analyzer } }
end
return {}
