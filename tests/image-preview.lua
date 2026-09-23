local fixture = assert(vim.env.NIX_IMAGE_FIXTURE, "image fixture path is required")
local text_fixture = assert(vim.env.NIX_TEXT_FIXTURE, "text fixture path is required")

assert(vim.fn.filereadable(fixture) == 1, "image fixture is not readable")
assert(vim.fn.filereadable(text_fixture) == 1, "text fixture is not readable")
assert(Snacks.image.config.enabled == true, "Snacks image support is not enabled")
assert(Snacks.image.supports_file(fixture), "fixture is not a Snacks-supported image")

-- Picker preview regression: an image item must select Snacks' image previewer
-- before the generic text/binary previewer gets a chance to read its bytes.
local attached
local attach = Snacks.image.buf.attach
Snacks.image.buf.attach = function(_, opts)
  attached = opts.src
end
local preview = {
  scratch = function()
    return 0
  end,
  set_title = function() end,
}
Snacks.picker.preview.file({
  buf = 0,
  item = { file = fixture },
  prev = {},
  preview = preview,
  picker = { opts = { previewers = { file = {} } } },
})
Snacks.image.buf.attach = attach
assert(attached == fixture, "picker did not route the image to Snacks.image.buf.attach")

-- Direct opening regression: Snacks must replace the binary buffer with an
-- image buffer instead of leaving raw image bytes on screen.
vim.cmd.edit(vim.fn.fnameescape(fixture))
vim.wait(2500, function()
  return vim.bo.filetype == "image"
end, 50)
assert(vim.bo.filetype == "image", "direct image opening did not create an image buffer")
assert(vim.bo.modifiable == false, "image buffer remains modifiable")

-- Ordinary text files must continue to use Neovim's normal buffer behavior.
vim.cmd.edit(vim.fn.fnameescape(text_fixture))
assert(vim.bo.filetype ~= "image", "text file was incorrectly treated as an image")
assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "normal text remains normal")

print("image preview checks passed")
vim.cmd("qa!")
