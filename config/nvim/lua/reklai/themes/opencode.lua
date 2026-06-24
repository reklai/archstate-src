-- opencode -- extraction of the default `opencode` theme from
-- anomalyco/opencode v1.17.9 (packages/tui/src/theme/assets/opencode.json)
-- reskinned onto tokyonight.nvim, as a peer of themes/sitruuna.lua.
--
-- The semantic-color -> tree-sitter-scope mapping follows opencode's
-- getSyntaxRules() exactly (dark mode), including its distinctive rules:
--   * builtins (variable/type/function/module/constant.builtin) and
--     variable.super / @tag are colored with `error` red
--   * @keyword.function uses the function color, not the keyword color
--   * @keyword.type is bold + italic
--   * @keyword.import is non-italic (unlike generic keyword)
--   * comments and generic keywords are italic
--
-- Loaded by lazy/tokyonight.lua when vim.g.active_theme == "opencode".
-- Peer theme sitruuna lives in themes/sitruuna.lua; the neutral
-- tokyonight spec dispatches to whichever themes/*.lua matches
-- vim.g.active_theme.
--
-- Saturation: vim.g.theme_saturation (default 1.0) scales HSL saturation of
-- the chromatic tokens at opts() time. Greys are a mathematical no-op.
local palette = {
	-- Surfaces -- opencode's step-greys swapped for sitruuna's ramp so the
	-- two nvim themes share the same surface feel (bg, floats, statusline,
	-- cursorline, visual all read consistently).
	bg = "#181a1b", -- sitruuna bg
	panel = "#131515", -- sitruuna darker (bg_dark / sidebar)
	element = "#242629", -- sitruuna lighter_bg (floats / WinBar)
	higher = "#242629", -- alias for floating/menu surfaces
	cursorline_bg = "#1d2023", -- sitruuna light_bg (cursorline / colorcolumn)
	statusline_bg = "#242629", -- sitruuna lighter_bg (statusline)
	visual_bg = "#2D3032", -- sitruuna selection (visual)

	-- Text
	fg = "#eeeeee", -- darkStep12 (text)
	fg_alt = "#808080", -- darkStep11 (textMuted)
	comment = "#808080", -- darkStep11 (syntaxComment)

	-- Borders
	border_subtle = "#3c3c3c", -- darkStep6
	border = "#484848", -- darkStep7
	border_active = "#606060", -- darkStep8

	-- Roles (semantic colors from opencode's `theme` section, dark)
	primary = "#fab283", -- darkStep9 (primary)
	secondary = "#5c9cf5", -- darkSecondary (secondary)
	accent = "#9d7cd8", -- darkAccent (accent)
	error = "#e06c75", -- darkRed
	warning = "#f5a742", -- darkOrange
	success = "#7fd88f", -- darkGreen
	info = "#56b6c2", -- darkCyan

	-- Syntax roles (the bridge opencode uses to map to tree-sitter scopes)
	syn_keyword = "#9d7cd8", -- syntaxKeyword
	syn_function = "#fab283", -- syntaxFunction
	syn_variable = "#e06c75", -- syntaxVariable
	syn_string = "#7fd88f", -- syntaxString
	syn_number = "#f5a742", -- syntaxNumber
	syn_type = "#e5c07b", -- syntaxType
	syn_operator = "#56b6c2", -- syntaxOperator
	syn_punctuation = "#eeeeee", -- syntaxPunctuation
}

local function opts()
	local s = require("reklai.themes.desaturate").palette(palette, vim.g.theme_saturation or 1.0)
	local fg, fg_alt, bg = s.fg, s.fg_alt, s.bg
	local cmt = s.comment
	local kw = { fg = s.syn_keyword, italic = true }
	local kwt = { fg = s.syn_type, bold = true, italic = true }
	local transparent = vim.g.theme_transparent == true
	local opacity = vim.g.theme_opacity or 0.8
	local blend = require("reklai.themes.desaturate").blend
	-- Pre-compute float backgrounds: solid when opaque, blended toward black
	-- at the user's opacity when transparent. UI chrome stays solid.
	local float_bg = transparent and blend(s.element, "#000000", opacity) or s.element
	local menu_bg = transparent and blend(s.cursorline_bg, "#000000", opacity) or s.cursorline_bg
	return {
		style = "night",
		transparent = transparent,
		terminal_colors = true,
		styles = {
			comments = { italic = true },
			keywords = { italic = true },
			functions = {},
			variables = {},
			sidebars = transparent and "transparent" or "dark",
			floats = transparent and "transparent" or "dark",
		},
		-- Map tokyonight's palette onto opencode's so un-overridden UI/plugin
		-- groups harmonize, and the 16 terminal colors match the Ghostty config.
		on_colors = function(c)
			c.bg = s.bg
			c.bg_dark = s.panel
			c.bg_float = s.element
			c.bg_popup = s.bg
			c.bg_sidebar = s.bg
			c.bg_statusline = s.statusline_bg
			c.bg_highlight = s.cursorline_bg
			c.bg_visual = s.visual_bg
			c.fg = s.fg
			c.fg_dark = s.fg_alt
			c.fg_sidebar = s.fg_alt
			c.fg_gutter = cmt
			c.comment = cmt
			c.border = s.border
			c.blue = s.secondary
			c.cyan = s.info
			c.teal = s.success
			c.green = s.syn_function
			c.green1 = s.success
			c.green2 = s.success
			c.magenta = s.syn_keyword
			c.magenta2 = s.syn_keyword
			c.purple = s.syn_keyword
			c.yellow = s.syn_type
			c.orange = s.warning
			c.red = s.error
			c.red1 = s.error
			c.terminal_black = s.bg
		end,
		-- Reproduce opencode's exact role->color mapping across legacy syntax,
		-- Treesitter (@...) and LSP semantic tokens (@lsp.type.*).
		on_highlights = function(hl)
			-- Editor / UI. When transparent, main editor surfaces get bg=none
			-- (Ghostty's background-opacity shows through). UI chrome below
			-- (CursorLine, Visual, WinBar, StatusLine) stays solid.
			hl.Normal = { fg = fg, bg = transparent and "none" or bg }
			hl.NormalNC = { fg = fg, bg = transparent and "none" or bg }
			-- Floating windows use the pre-computed float_bg: solid when opaque,
			-- blended toward black at the user's opacity when transparent, so
			-- floats stay readable over the terminal's transparent backdrop.
			hl.NormalFloat = { fg = fg, bg = float_bg }
			hl.FloatBorder = { fg = s.info, bg = float_bg }
			hl.CursorLine = { bg = s.cursorline_bg }
			hl.CursorLineNr = { fg = s.warning, bg = s.cursorline_bg }
			hl.LineNr = { fg = cmt, bg = s.cursorline_bg }
			hl.SignColumn = { fg = s.border, bg = transparent and "none" or bg }
			hl.ColorColumn = { bg = s.cursorline_bg }
			hl.Visual = { bg = s.visual_bg }
			hl.LspReferenceText = { bg = s.visual_bg }
			hl.LspReferenceRead = { bg = s.visual_bg }
			hl.LspReferenceWrite = { bg = s.visual_bg, underline = true }
			hl.MatchParen = { fg = s.primary, bold = true }
			hl.WinBar = { fg = fg, bg = s.element }
			hl.WinBarNC = { fg = fg_alt, bg = s.cursorline_bg }
			hl.StatusLine = { fg = fg, bg = s.statusline_bg }
			hl.StatusLineNC = { fg = fg_alt, bg = s.statusline_bg }
			hl.Pmenu = { fg = fg, bg = menu_bg }
			hl.PmenuSel = { fg = bg, bg = s.primary }
			hl.WinSeparator = { fg = s.border, bg = transparent and "none" or bg }
			hl.Folded = { fg = fg_alt, bg = s.statusline_bg }
			hl.NonText = { fg = cmt }
			hl.Search = { fg = fg, bg = s.visual_bg }
			hl.IncSearch = { fg = bg, bg = s.primary }
			hl.CurSearch = { fg = bg, bg = s.primary }

			-- Active indent scope guide (opencode info cyan -- uniform across
			-- the block; SymbolOff matches so border lines aren't flagged).
			hl.MiniIndentscopeSymbol = { fg = s.info, nocombine = true }
			hl.MiniIndentscopeSymbolOff = { fg = s.info, nocombine = true }

			-- Legacy syntax groups
			hl.Comment = { fg = cmt, italic = true }
			hl.Constant = { fg = s.syn_number }
			hl.String = { fg = s.syn_string }
			hl.Character = { fg = s.syn_string }
			hl.Number = { fg = s.syn_number }
			hl.Boolean = { fg = s.syn_number }
			hl.Float = { fg = s.syn_number }
			hl.Identifier = { fg = s.syn_function }
			hl.Function = { fg = s.syn_function }
			hl.Operator = { fg = s.syn_operator }
			hl.Statement = kw
			hl.Conditional = kw
			hl.Repeat = kw
			hl.Label = kw
			hl.Keyword = kw
			hl.Exception = kw
			hl.StorageClass = kw
			hl.Structure = kw
			hl.Typedef = kwt
			hl.PreProc = { fg = s.syn_keyword }
			hl.Include = { fg = s.syn_keyword }
			hl.Define = { fg = s.syn_keyword }
			hl.Macro = { fg = s.syn_keyword }
			hl.PreCondit = { fg = s.syn_keyword }
			hl.Type = { fg = s.syn_type }
			hl.Special = { fg = s.primary }
			hl.SpecialChar = { fg = s.syn_keyword }
			hl.SpecialComment = { fg = s.primary }
			hl.Tag = { fg = s.error }
			hl.Delimiter = { fg = fg }
			hl.Debug = { fg = s.primary }
			hl.Title = { fg = s.accent, bold = true }
			hl.Directory = { fg = s.accent }
			hl.Error = { fg = s.error }
			hl.WarningMsg = { fg = s.warning }
			hl.MoreMsg = { fg = s.info }
			hl.ModeMsg = { fg = s.info }
			hl.Question = { fg = s.info }
			hl.Todo = { fg = bg, bg = s.success }
			hl.ErrorMsg = { fg = s.error }
			hl.Conceal = { fg = fg_alt }
			hl.SpellBad = { fg = s.error, underline = true }
			hl.SpellCap = { fg = s.warning, underline = true }
			hl.SpellLocal = { fg = s.info, underline = true }
			hl.SpellRare = { fg = s.accent, underline = true }

			-- Treesitter captures (legacy + nvim 0.10 renames)
			hl["@comment"] = { fg = cmt, italic = true }
			hl["@comment.documentation"] = { fg = cmt, italic = true }
			hl["@string"] = { fg = s.syn_string }
			hl["@string.escape"] = { fg = s.syn_keyword }
			hl["@string.special"] = { fg = s.syn_keyword }
			hl["@string.special.url"] = { fg = s.primary, underline = true }
			hl["@string.regexp"] = { fg = s.syn_keyword }
			hl["@character"] = { fg = s.syn_string }
			hl["@character.special"] = { fg = s.syn_string }
			hl["@number"] = { fg = s.syn_number }
			hl["@boolean"] = { fg = s.syn_number }
			hl["@float"] = { fg = s.syn_number }
			hl["@constant"] = { fg = s.syn_number }
			hl["@constant.builtin"] = { fg = s.error }
			hl["@constant.macro"] = { fg = s.syn_keyword }
			hl["@variable"] = { fg = s.syn_variable }
			hl["@variable.builtin"] = { fg = s.error }
			hl["@variable.parameter"] = { fg = s.syn_variable }
			hl["@variable.member"] = { fg = s.syn_function }
			hl["@variable.super"] = { fg = s.error }
			hl["@parameter"] = { fg = s.syn_variable }
			hl["@field"] = { fg = s.syn_variable }
			hl["@property"] = { fg = s.syn_variable }
			hl["@function"] = { fg = s.syn_function }
			hl["@function.call"] = { fg = s.syn_function }
			hl["@function.builtin"] = { fg = s.error }
			hl["@function.macro"] = { fg = s.syn_keyword }
			hl["@function.method"] = { fg = s.syn_function }
			hl["@function.method.call"] = { fg = s.syn_variable }
			hl["@method"] = { fg = s.syn_function }
			hl["@method.call"] = { fg = s.syn_function }
			hl["@constructor"] = { fg = s.syn_function }
			hl["@operator"] = { fg = s.syn_operator }
			hl["@keyword"] = kw
			hl["@keyword.function"] = { fg = s.syn_function }
			hl["@keyword.return"] = kw
			hl["@keyword.operator"] = { fg = s.syn_operator }
			hl["@keyword.conditional"] = kw
			hl["@keyword.conditional.ternary"] = { fg = s.syn_operator }
			hl["@keyword.repeat"] = kw
			hl["@keyword.exception"] = kw
			hl["@keyword.import"] = { fg = s.syn_keyword }
			hl["@keyword.directive"] = kw
			hl["@keyword.modifier"] = kw
			hl["@keyword.type"] = kwt
			hl["@keyword.export"] = { fg = s.syn_keyword }
			hl["@conditional"] = kw
			hl["@repeat"] = kw
			hl["@exception"] = kw
			hl["@label"] = kw
			hl["@include"] = { fg = s.syn_keyword }
			hl["@preproc"] = { fg = s.syn_keyword }
			hl["@define"] = { fg = s.syn_keyword }
			hl["@type"] = { fg = s.syn_type }
			hl["@type.builtin"] = { fg = s.error }
			hl["@type.definition"] = kwt
			hl["@storageclass"] = kw
			hl["@structure"] = kwt
			hl["@namespace"] = { fg = s.syn_type }
			hl["@module"] = { fg = s.syn_type }
			hl["@module.builtin"] = { fg = s.error }
			hl["@punctuation"] = { fg = s.syn_punctuation }
			hl["@punctuation.delimiter"] = { fg = s.syn_operator }
			hl["@punctuation.bracket"] = { fg = s.syn_punctuation }
			hl["@punctuation.special"] = { fg = s.syn_operator }
			hl["@tag"] = { fg = s.error }
			hl["@tag.attribute"] = { fg = s.syn_keyword }
			hl["@tag.delimiter"] = { fg = s.syn_operator }
			hl["@attribute"] = { fg = s.warning }
			hl["@annotation"] = { fg = s.warning }
			hl["@special"] = { fg = s.primary }
			hl["@text.title"] = { fg = s.accent, bold = true }
			hl["@text.uri"] = { fg = s.primary, underline = true }
			hl["@text.literal"] = { fg = s.syn_string }
			hl["@text.underline"] = { fg = fg, underline = true }
			hl["@text.strike"] = { fg = fg_alt }
			hl["@markup.heading"] = { fg = s.accent, bold = true }
			hl["@markup.heading.1"] = { fg = s.accent, bold = true, underline = true }
			hl["@markup.heading.2"] = { fg = s.accent, bold = true }
			hl["@markup.heading.3"] = { fg = s.accent, bold = true }
			hl["@markup.heading.4"] = { fg = s.accent, bold = true }
			hl["@markup.heading.5"] = { fg = s.accent, bold = true }
			hl["@markup.heading.6"] = { fg = s.accent, bold = true }
			hl["@markup.bold"] = { fg = s.warning, bold = true }
			hl["@markup.strong"] = { fg = s.warning, bold = true }
			hl["@markup.italic"] = { fg = s.syn_type, italic = true }
			hl["@markup.list"] = { fg = s.primary }
			hl["@markup.list.checked"] = { fg = s.success }
			hl["@markup.list.unchecked"] = { fg = fg_alt }
			hl["@markup.quote"] = { fg = s.syn_type, italic = true }
			hl["@markup.raw"] = { fg = s.success }
			hl["@markup.raw.block"] = { fg = s.success }
			hl["@markup.raw.inline"] = { fg = s.success, bg = bg }
			hl["@markup.link"] = { fg = s.primary, underline = true }
			hl["@markup.link.label"] = { fg = s.info, underline = true }
			hl["@markup.link.url"] = { fg = s.primary, underline = true }

			-- Diagnostics (opencode has no dedicated diagnostic group; map
			-- the standard ones to the role colors for consistency)
			hl.DiagnosticError = { fg = s.error }
			hl.DiagnosticWarn = { fg = s.warning }
			hl.DiagnosticInfo = { fg = s.info }
			hl.DiagnosticHint = { fg = s.secondary }
			hl.DiagnosticOk = { fg = s.success }
			hl["@diagnostic.error"] = { fg = s.error }
			hl["@diagnostic.warning"] = { fg = s.warning }
			hl["@diagnostic.info"] = { fg = s.info }
			hl["@diagnostic.hint"] = { fg = s.secondary }
			hl["@diagnostic.ok"] = { fg = s.success }

			-- LSP semantic tokens
			hl["@lsp.type.keyword"] = kw
			hl["@lsp.type.function"] = { fg = s.syn_function }
			hl["@lsp.type.method"] = { fg = s.syn_function }
			hl["@lsp.type.type"] = { fg = s.syn_type }
			hl["@lsp.type.class"] = { fg = s.syn_type }
			hl["@lsp.type.struct"] = { fg = s.syn_type }
			hl["@lsp.type.enum"] = { fg = s.syn_type }
			hl["@lsp.type.interface"] = { fg = s.syn_type }
			hl["@lsp.type.namespace"] = { fg = s.syn_type }
			hl["@lsp.type.typeParameter"] = { fg = s.syn_type }
			hl["@lsp.type.parameter"] = { fg = s.syn_variable }
			hl["@lsp.type.property"] = { fg = s.syn_variable }
			hl["@lsp.type.variable"] = { fg = s.syn_variable }
			hl["@lsp.type.enumMember"] = { fg = s.syn_number }
			hl["@lsp.type.string"] = { fg = s.syn_string }
			hl["@lsp.type.number"] = { fg = s.syn_number }
			hl["@lsp.type.comment"] = { fg = cmt, italic = true }
		end,
	}
end

return { opts = opts }
