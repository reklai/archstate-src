require("reklai.set")
require("reklai.remap")
require("reklai.cppdev").setup()
require("reklai.lazy_init")

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
local augroup = vim.api.nvim_create_augroup
local reklaiGroup = augroup("TheReklai", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

function R(name)
	require("plenary.reload").reload_module(name)
end

vim.filetype.add({
	extension = {
		gotmpl = "gotmpl",
		tmpl = "gotmpl",
		templ = "templ",
	},
	pattern = {
		[".*%.go%.tmpl"] = "gotmpl",
	},
})

autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})

autocmd({ "BufWritePre" }, {
	group = reklaiGroup,
	pattern = "*",
	callback = function(event)
		if not vim.bo[event.buf].modifiable or vim.bo[event.buf].buftype ~= "" then
			return
		end

		local view = vim.fn.winsaveview()
		vim.api.nvim_buf_call(event.buf, function()
			vim.cmd([[%s/\s\+$//e]])
		end)
		vim.fn.winrestview(view)
	end,
})

local function apply_theme_overrides()
	vim.api.nvim_set_hl(0, "Visual", { fg = "#EBCB8B", bold = true })
end

autocmd("ColorScheme", {
	group = reklaiGroup,
	callback = apply_theme_overrides,
})

apply_theme_overrides()

-- Browsing Remote Files
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
