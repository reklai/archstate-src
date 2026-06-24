-- tokyonight.nvim -- the reskin vehicle for the sitruuna, opencode, and
-- darkplus themes. Each theme's palette + highlight mapping lives in its own
-- module under lua/reklai/themes/ (sitruuna.lua, opencode.lua, darkplus.lua);
-- this spec owns the plugin and dispatches to whichever is selected via
-- vim.g.active_theme.
return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	config = function(_, opts)
		local theme = vim.g.active_theme
		if theme == "sitruuna" or theme == "opencode" or theme == "darkplus" then
			opts = require("reklai.themes." .. theme).opts()
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")
		end
	end,
}
