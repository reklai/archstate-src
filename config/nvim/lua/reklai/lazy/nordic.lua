-- nordic.nvim -- the Nord palette with default settings, except the surface is
-- recolored to match sitruuna: background #181a1b, cursorline #1d2023,
-- statusline/winbar #242629, visual #2D3032. Only backgrounds change; the Nord
-- syntax colors are left untouched.
--
-- Applied only when vim.g.active_theme == "nordic" (set in lua/reklai/init.lua).
-- The other choices, "sitruuna" and "opencode", live in themes/ and are
-- applied by lazy/tokyonight.lua (which reskins tokyonight.nvim).
return {
	"AlexvZyl/nordic.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		if vim.g.active_theme == "nordic" then
			local transparent = vim.g.theme_transparent == true
			local opacity = vim.g.theme_opacity or 0.8
			local blend = require("reklai.themes.desaturate").blend
			-- Float bg: solid normally, blended toward black at the user's
			-- opacity when transparent so floats stay readable over the
			-- terminal's transparent backdrop.
			local float_bg = transparent and blend("#242629", "#000000", opacity) or "#242629"
			require("nordic").setup({
				-- Editor background transparency: main bg goes to none when
				-- transparent=true (Ghostty's background-opacity shows through).
				-- float=false so we can override the float bg with our blend
				-- in on_highlight rather than letting nordic set it to none.
				transparent = {
					bg = transparent,
					float = false,
				},
				-- gray0 is nordic's `bg`; changing it before derivation cascades
				-- to Normal/sidebar/border.
				on_palette = function(palette)
					palette.gray0 = "#181a1b"
				end,
				-- Override the derived cursorline/statusline backgrounds with
				-- sitruuna's light_bg / lighter_bg.
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
					-- mini.indentscope line in Nord's pink (sitruuna uses blue,
					-- set in themes/sitruuna.lua). Uniform across the block;
					-- SymbolOff matches so border lines aren't flagged.
					highlights.MiniIndentscopeSymbol = { fg = "#B48EAD", nocombine = true }
					highlights.MiniIndentscopeSymbolOff = { fg = "#B48EAD", nocombine = true }
					-- Override nordic's float bg with our opacity-aware version.
					highlights.NormalFloat = { bg = float_bg }
				end,
			})
			require("nordic").load()
		end
	end,
}
