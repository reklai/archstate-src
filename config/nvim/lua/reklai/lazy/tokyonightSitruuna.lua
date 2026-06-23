-- Theme: tokyonight.nvim, reskinned to closely resemble sitruuna.
--
-- Why tokyonight instead of the original sitruuna.vim: tokyonight is an actively
-- maintained Lua theme with first-class Treesitter + LSP semantic-token support
-- and built-in integrations for the plugins used here (telescope, which-key,
-- mini.indentscope, noice, trouble, blink.cmp). We keep sitruuna's identity by
-- remapping the palette (on_colors) and the syntax/Treesitter/LSP groups
-- (on_highlights) to sitruuna's exact colors.
--
-- The colorscheme is applied below in this spec's own config, only when
-- vim.g.active_theme == "tokyo" (set in lua/reklai/init.lua).
local s = {
	fg = "#d1d1d1",
	fg_alt = "#a1a1a1",
	comment = "#5c6366",
	lemon = "#FAC03B", -- keywords / statements (bold)
	special = "#ffb354", -- special / tags
	preproc = "#a29bfe", -- preproc / include / macro
	func = "#a3db81", -- functions / identifiers / operators
	string = "#37ad82", -- strings
	type = "#7398dd", -- types
	constant = "#ca70d6", -- constants / numbers / booleans
	error = "#c15959",
	bg = "#181a1b",
	darker = "#131515",
	light_bg = "#1d2023", -- cursorline / colorcolumn
	lighter_bg = "#242629", -- winbar / statusline / float border
	selection = "#2D3032", -- visual
	statusline = "#34373a",
}

return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		style = "night", -- darkest base, closest to sitruuna's near-black bg
		transparent = false,
		terminal_colors = true,
		styles = {
			comments = { italic = false }, -- sitruuna comments are plain
			keywords = { italic = false },
			functions = {},
			variables = {},
			sidebars = "dark",
			floats = "dark",
		},
		-- Map tokyonight's palette onto sitruuna's so un-overridden UI/plugin
		-- groups harmonize, and terminal colors match.
		on_colors = function(c)
			c.bg = s.bg
			c.bg_dark = s.darker
			c.bg_float = s.lighter_bg
			c.bg_popup = s.bg
			c.bg_sidebar = s.bg
			c.bg_statusline = s.lighter_bg
			c.bg_highlight = s.light_bg
			c.bg_visual = s.selection
			c.fg = s.fg
			c.fg_dark = s.fg_alt
			c.fg_sidebar = s.fg_alt
			c.fg_gutter = s.comment
			c.comment = s.comment
			c.border = s.lighter_bg
			c.blue = s.type
			c.cyan = s.string
			c.teal = s.string
			c.green = s.func
			c.green1 = s.string
			c.green2 = s.string
			c.magenta = s.constant
			c.magenta2 = s.constant
			c.purple = s.preproc
			c.yellow = s.lemon
			c.orange = s.special
			c.red = s.error
			c.red1 = s.error
			c.terminal_black = s.darker
		end,
		-- Reproduce sitruuna's exact role->color mapping across legacy syntax,
		-- Treesitter (@...) and LSP semantic tokens (@lsp.type.*).
		on_highlights = function(hl)
			local kw = { fg = s.lemon, bold = true }
			-- Editor / UI
			hl.Normal = { fg = s.fg, bg = s.bg }
			hl.NormalNC = { fg = s.fg, bg = s.bg }
			-- Floating windows (LSP hover / signature / diagnostics): a lighter
			-- surface than the editor bg + a visible blue border so the float
			-- doesn't blend into the background.
			hl.NormalFloat = { fg = s.fg, bg = s.lighter_bg }
			hl.FloatBorder = { fg = s.type, bg = s.lighter_bg }
			hl.CursorLine = { bg = s.light_bg }
			hl.CursorLineNr = { fg = s.special, bg = s.light_bg }
			hl.LineNr = { fg = s.comment, bg = s.light_bg }
			hl.SignColumn = { fg = s.lighter_bg, bg = s.darker }
			hl.ColorColumn = { bg = s.light_bg }
			hl.Visual = { bg = s.selection }
			hl.MatchParen = { fg = s.special, bold = true }
			hl.WinBar = { fg = s.fg, bg = s.lighter_bg }
			hl.WinBarNC = { fg = s.fg_alt, bg = s.light_bg }
			hl.StatusLine = { fg = s.fg, bg = s.lighter_bg }
			hl.StatusLineNC = { fg = s.fg_alt, bg = s.light_bg }
			hl.Pmenu = { fg = s.fg, bg = s.light_bg }
			hl.PmenuSel = { fg = s.bg, bg = s.lemon }
			hl.WinSeparator = { fg = s.lighter_bg, bg = s.bg }
			hl.Folded = { fg = s.fg_alt, bg = s.statusline }
			hl.NonText = { fg = s.comment }

			-- Active indent scope guide (blue, matching the theme's type color)
			hl.MiniIndentscopeSymbol = { fg = s.type, nocombine = true }
			hl.MiniIndentscopeSymbolOff = { fg = s.error, nocombine = true }

			-- Legacy syntax groups
			hl.Comment = { fg = s.comment }
			hl.Constant = { fg = s.constant }
			hl.String = { fg = s.string }
			hl.Character = { fg = s.constant }
			hl.Number = { fg = s.constant }
			hl.Boolean = { fg = s.constant }
			hl.Float = { fg = s.constant }
			hl.Identifier = { fg = s.func }
			hl.Function = { fg = s.func }
			hl.Operator = { fg = s.func }
			hl.Statement = kw
			hl.Conditional = kw
			hl.Repeat = kw
			hl.Label = kw
			hl.Keyword = kw
			hl.Exception = kw
			hl.StorageClass = kw
			hl.Structure = kw
			hl.Typedef = kw
			hl.PreProc = { fg = s.preproc }
			hl.Include = { fg = s.preproc }
			hl.Define = { fg = s.preproc }
			hl.Macro = { fg = s.preproc }
			hl.PreCondit = { fg = s.preproc }
			hl.Type = { fg = s.type }
			hl.Special = { fg = s.special }
			hl.SpecialChar = { fg = s.special }
			hl.SpecialComment = { fg = s.special }
			hl.Tag = { fg = s.special }
			hl.Debug = { fg = s.special }
			hl.Delimiter = { fg = s.fg }
			hl.Title = { fg = s.lemon, bold = true }
			hl.Directory = { fg = s.lemon }
			hl.Error = { fg = s.error }
			hl.Todo = { fg = s.bg, bg = s.string }

			-- Treesitter captures (legacy + nvim 0.10 renames)
			hl["@comment"] = { fg = s.comment }
			hl["@string"] = { fg = s.string }
			hl["@string.escape"] = { fg = s.special }
			hl["@string.special.url"] = { fg = s.special, underline = true }
			hl["@character"] = { fg = s.constant }
			hl["@number"] = { fg = s.constant }
			hl["@boolean"] = { fg = s.constant }
			hl["@float"] = { fg = s.constant }
			hl["@constant"] = { fg = s.constant }
			hl["@constant.builtin"] = { fg = s.constant }
			hl["@constant.macro"] = { fg = s.preproc }
			hl["@variable"] = { fg = s.fg }
			hl["@variable.builtin"] = { fg = s.constant }
			hl["@variable.parameter"] = { fg = s.fg_alt }
			hl["@variable.member"] = { fg = s.fg }
			hl["@parameter"] = { fg = s.fg_alt }
			hl["@field"] = { fg = s.fg }
			hl["@property"] = { fg = s.fg }
			hl["@function"] = { fg = s.func }
			hl["@function.call"] = { fg = s.func }
			hl["@function.builtin"] = { fg = s.func }
			hl["@function.macro"] = { fg = s.preproc }
			hl["@method"] = { fg = s.func }
			hl["@method.call"] = { fg = s.func }
			hl["@constructor"] = { fg = s.type }
			hl["@operator"] = { fg = s.func }
			hl["@keyword"] = kw
			hl["@keyword.function"] = kw
			hl["@keyword.return"] = kw
			hl["@keyword.operator"] = kw
			hl["@keyword.conditional"] = kw
			hl["@keyword.repeat"] = kw
			hl["@keyword.exception"] = kw
			hl["@keyword.import"] = { fg = s.preproc }
			hl["@keyword.directive"] = { fg = s.preproc }
			hl["@conditional"] = kw
			hl["@repeat"] = kw
			hl["@exception"] = kw
			hl["@label"] = kw
			hl["@include"] = { fg = s.preproc }
			hl["@preproc"] = { fg = s.preproc }
			hl["@define"] = { fg = s.preproc }
			hl["@type"] = { fg = s.type }
			hl["@type.builtin"] = { fg = s.type }
			hl["@type.definition"] = kw
			hl["@storageclass"] = kw
			hl["@structure"] = kw
			hl["@namespace"] = { fg = s.type }
			hl["@module"] = { fg = s.type }
			hl["@punctuation"] = { fg = s.fg }
			hl["@punctuation.delimiter"] = { fg = s.fg }
			hl["@punctuation.bracket"] = { fg = s.fg }
			hl["@punctuation.special"] = { fg = s.special }
			hl["@tag"] = kw
			hl["@tag.attribute"] = { fg = s.func }
			hl["@tag.delimiter"] = { fg = s.fg }
			hl["@special"] = { fg = s.special }
			hl["@text.title"] = { fg = s.lemon, bold = true }
			hl["@text.uri"] = { fg = s.special, underline = true }
			hl["@markup.heading"] = { fg = s.lemon, bold = true }
			hl["@markup.link.url"] = { fg = s.special, underline = true }

			-- LSP semantic tokens
			hl["@lsp.type.keyword"] = kw
			hl["@lsp.type.function"] = { fg = s.func }
			hl["@lsp.type.method"] = { fg = s.func }
			hl["@lsp.type.type"] = { fg = s.type }
			hl["@lsp.type.class"] = { fg = s.type }
			hl["@lsp.type.struct"] = { fg = s.type }
			hl["@lsp.type.enum"] = { fg = s.type }
			hl["@lsp.type.interface"] = { fg = s.type }
			hl["@lsp.type.namespace"] = { fg = s.type }
			hl["@lsp.type.typeParameter"] = { fg = s.type }
			hl["@lsp.type.parameter"] = { fg = s.fg_alt }
			hl["@lsp.type.property"] = { fg = s.fg }
			hl["@lsp.type.variable"] = { fg = s.fg }
			hl["@lsp.type.enumMember"] = { fg = s.constant }
			hl["@lsp.type.string"] = { fg = s.string }
			hl["@lsp.type.number"] = { fg = s.constant }
			hl["@lsp.type.comment"] = { fg = s.comment }
		end,
	},
	config = function(_, opts)
		-- Only build tokyonight's highlight tables and apply it when this theme
		-- is selected; otherwise the spec loads but does no work (mirrors nordic.lua).
		if vim.g.active_theme == "tokyo" then
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")
		end
	end,
}
