-- nordic.nvim -- the Nord palette with default settings, except the surface is
-- recolored to match tokyoSitruuna: background #181a1b, cursorline #1d2023,
-- statusline/winbar #242629, visual #2D3032. Only backgrounds change; the Nord
-- syntax colors are left untouched.
--
-- Applied only when vim.g.active_theme == "nordic" (set in lua/reklai/init.lua).
-- The other choice, "tokyo", lives in tokyonightSitruuna.lua.
return {
	"AlexvZyl/nordic.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		if vim.g.active_theme == "nordic" then
			require("nordic").setup({
				-- gray0 is nordic's `bg`; changing it before derivation cascades
				-- to Normal/sidebar/border.
				on_palette = function(palette)
					palette.gray0 = "#181a1b"
				end,
				-- Override the derived cursorline/statusline backgrounds with
				-- tokyoSitruuna's light_bg / lighter_bg.
				after_palette = function(palette)
					palette.bg_cursorline = "#1d2023"
					palette.bg_statusline = "#242629"
					palette.bg_visual = "#2D3032"
				end,
				-- WinBar is the visible top bar here (laststatus = 0) and uses a
				-- different field (bg_dark), so match it to the statusline color.
				on_highlight = function(highlights, palette)
					highlights.WinBar = { fg = palette.gray5, bg = "#242629" }
					highlights.WinBarNC = { fg = palette.gray4, bg = "#1d2023" }
					-- mini.indentscope line in Nord's pink (tokyoSitruuna uses blue,
					-- set in tokyonightSitruuna.lua).
					highlights.MiniIndentscopeSymbol = { fg = "#B48EAD", nocombine = true }
				end,
			})
			require("nordic").load()
		end
	end,
}
