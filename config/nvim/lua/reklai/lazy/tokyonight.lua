-- tokyonight.nvim -- the reskin vehicle for both the sitruuna and opencode
-- themes. Each theme's palette + highlight mapping lives in its own module
-- under lua/reklai/themes/ (sitruuna.lua, opencode.lua); this spec owns the
-- plugin and dispatches to whichever is selected via vim.g.active_theme.
--
-- The nordic theme is independent (separate plugin, separate spec at
-- lazy/nordic.lua) and is not touched here.
return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	config = function(_, opts)
		local theme = vim.g.active_theme
		if theme == "sitruuna" or theme == "opencode" then
			opts = require("reklai.themes." .. theme).opts()
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")
		end
	end,
}
