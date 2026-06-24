-- darkplus -- VS Code Dark+ (the default modern dark theme, extracted from
-- microsoft/vscode extensions/theme-defaults/themes/dark_plus.json and its
-- included base dark_vs.json) reskinned onto tokyonight.nvim, as a peer of
-- themes/sitruuna.lua and themes/opencode.lua.
--
-- The semantic-color -> tree-sitter-scope mapping follows Dark+'s resolved
-- tokenColors (dark_plus overrides dark_vs; the two JSONs are merged with
-- the more-specific scope winning). Distinctive Dark+ rules:
--   * Comments are a muted blue-grey (#5c6366, from sitruuna's ramp), plain
--   * keyword.control (if/for/return/import/exception) is purple (#C586C0),
--     while storage/keyword/general keywords are blue (#569CD6)
--   * Variables are light blue (#9CDCFE), variable.builtin (this/self) blue
--   * Constants (variable.other.constant, enummember) are bright blue (#4FC1FF)
--   * Types/classes/namespaces are teal (#4EC9B0)
--   * Numbers are light green (#B5CEA8)
--
-- Surfaces reuse sitruuna's near-black ramp for visual consistency across
-- themes (bg #181a1b, panels, floats, statusline); only selection (#264F78)
-- and cursorline (#2A2D2E) are Dark+'s known default chrome values.
--
-- Loaded by lazy/tokyonight.lua when vim.g.active_theme == "darkplus".
-- Peer themes sitruuna and opencode live in the same themes/ directory.
--
-- Saturation: vim.g.theme_saturation (default 1.0) scales HSL saturation of
-- the chromatic tokens at opts() time. Greys are a mathematical no-op.
local palette = {
	-- Surfaces -- sitruuna ramp (shared with sitruuna/opencode for consistency)
	bg = "#181a1b",
	darker = "#131515",
	light_bg = "#1d2023",
	lighter_bg = "#242629",
	selection = "#264F78",       -- Dark+ editor.selectionBackground (Q3)
	cursorline = "#2A2D2E",      -- Dark+ editor.lineHighlightBackground (Q3)
	statusline = "#242629",

	-- Text
	fg = "#D4D4D4",              -- editor.foreground
	fg_alt = "#858585",          -- muted (line numbers, inactive text)
	comment = "#5c6366",          -- sitruuna blue-grey (deviates from Dark+'s green)

	-- Borders
	border = "#242629",          -- sitruuna lighter_bg
	border_active = "#007ACC",   -- Dark+ accent (activityBarBadge etc.)
	indent_active = "#707070",   -- active indent guide (dark_vs)
	indent_inactive = "#404040", -- inactive indent guide (dark_vs)

	-- Roles (semantic colors from dark_plus.json over dark_vs.json)
	accent = "#007ACC",          -- activityBarBadge.background / focus borders
	keyword_blue = "#569CD6",    -- storage / keyword / tag / preprocessor / constant.language / boolean
	keyword_purple = "#C586C0",  -- keyword.control (if/for/return/import/exception)
	function_yellow = "#DCDCAA",-- functions
	variable_blue = "#9CDCFE",   -- variables / parameters / fields / tag attributes
	constant_blue = "#4FC1FF",   -- variable.other.constant / enummember
	type_teal = "#4EC9B0",       -- types / classes / namespaces / constructors
	string_orange = "#CE9178",   -- strings
	number_green = "#B5CEA8",    -- numbers / enum members (TextMate numeric)
	escape_gold = "#D7BA7D",     -- string escape / regexp quantifier
	regexp_red = "#D16969",      -- regexp string
	tag_delimiter = "#808080",   -- punctuation.definition.tag (XML/HTML brackets)
	label_grey = "#C8C8C8",      -- entity.name.label
	error_red = "#F44747",       -- invalid / error
}

local function opts()
	local s = require("reklai.themes.desaturate").palette(palette, vim.g.theme_saturation or 1.0)
	local fg, fg_alt, bg = s.fg, s.fg_alt, s.bg
	local cmt = s.comment
	local kw = { fg = s.keyword_blue }                    -- keyword / storage (plain)
	local kwc = { fg = s.keyword_purple }                 -- control flow: if/for/return/import
	local transparent = vim.g.theme_transparent == true
	local opacity = vim.g.theme_opacity or 0.8
	local blend = require("reklai.themes.desaturate").blend
	local float_bg = transparent and blend(s.lighter_bg, "#000000", opacity) or s.lighter_bg
	local menu_bg = transparent and blend(s.cursorline, "#000000", opacity) or s.cursorline
	return {
		style = "night",
		transparent = transparent,
		terminal_colors = true,
		styles = {
			comments = {},   -- Dark+ is plain, no italics
			keywords = {},
			functions = {},
			variables = {},
			sidebars = transparent and "transparent" or "dark",
			floats = transparent and "transparent" or "dark",
		},
		-- Map tokyonight's palette onto Dark+'s so un-overridden UI/plugin
		-- groups harmonize, and the 16 terminal colors match the Ghostty config.
		on_colors = function(c)
			c.bg = s.bg
			c.bg_dark = s.darker
			c.bg_float = s.lighter_bg
			c.bg_popup = s.bg
			c.bg_sidebar = s.bg
			c.bg_statusline = s.statusline
			c.bg_highlight = s.cursorline
			c.bg_visual = s.selection
			c.fg = s.fg
			c.fg_dark = s.fg_alt
			c.fg_sidebar = s.fg_alt
			c.fg_gutter = cmt
			c.comment = cmt
			c.border = s.border
			c.blue = s.keyword_blue
			c.cyan = s.type_teal
			c.teal = s.number_green
			c.green = s.function_yellow
			c.green1 = s.number_green
			c.green2 = s.number_green
			c.magenta = s.keyword_purple
			c.magenta2 = s.keyword_purple
			c.purple = s.keyword_purple
			c.yellow = s.function_yellow
			c.orange = s.escape_gold
			c.red = s.error_red
			c.red1 = s.error_red
			c.terminal_black = s.bg
		end,
		-- Reproduce Dark+'s exact role->color mapping across legacy syntax,
		-- Treesitter (@...) and LSP semantic tokens (@lsp.type.*).
		on_highlights = function(hl)
			-- Editor / UI. When transparent, main editor surfaces get bg=none
			-- (Ghostty's background-opacity shows through). UI chrome below
			-- (CursorLine, Visual, WinBar, StatusLine) stays solid.
			hl.Normal = { fg = fg, bg = transparent and "none" or bg }
			hl.NormalNC = { fg = fg, bg = transparent and "none" or bg }
			hl.NormalFloat = { fg = fg, bg = float_bg }
			hl.FloatBorder = { fg = s.accent, bg = float_bg }
			hl.CursorLine = { bg = s.cursorline }
			hl.CursorLineNr = { fg = s.escape_gold, bg = s.cursorline }
			hl.LineNr = { fg = s.fg_alt, bg = s.cursorline }
			hl.SignColumn = { fg = s.border, bg = transparent and "none" or bg }
			hl.ColorColumn = { bg = s.cursorline }
			hl.Visual = { bg = s.selection }
			hl.LspReferenceText = { bg = s.selection }
			hl.LspReferenceRead = { bg = s.selection }
			hl.LspReferenceWrite = { bg = s.selection, underline = true }
			hl.MatchParen = { fg = s.accent, bold = true }
			hl.WinBar = { fg = fg, bg = s.lighter_bg }
			hl.WinBarNC = { fg = fg_alt, bg = s.cursorline }
			hl.StatusLine = { fg = fg, bg = s.statusline }
			hl.StatusLineNC = { fg = fg_alt, bg = s.statusline }
			hl.Pmenu = { fg = fg, bg = menu_bg }
			hl.PmenuSel = { fg = bg, bg = s.accent }
			hl.WinSeparator = { fg = s.border, bg = transparent and "none" or bg }
			hl.Folded = { fg = fg_alt, bg = s.statusline }
			hl.NonText = { fg = cmt }
			hl.Search = { fg = fg, bg = s.selection }
			hl.IncSearch = { fg = bg, bg = s.accent }
			hl.CurSearch = { fg = bg, bg = s.accent }

			-- Active indent scope guide (VS Code dark active indent -- uniform
			-- across the block; SymbolOff matches so border lines aren't flagged).
			hl.MiniIndentscopeSymbol = { fg = s.indent_active, nocombine = true }
			hl.MiniIndentscopeSymbolOff = { fg = s.indent_active, nocombine = true }

			-- Legacy syntax groups
			hl.Comment = { fg = cmt }
			hl.Constant = { fg = s.constant_blue }
			hl.String = { fg = s.string_orange }
			hl.Character = { fg = s.keyword_blue }
			hl.Number = { fg = s.number_green }
			hl.Boolean = { fg = s.keyword_blue }
			hl.Float = { fg = s.number_green }
			hl.Identifier = { fg = s.function_yellow }
			hl.Function = { fg = s.function_yellow }
			hl.Operator = { fg = fg }
			hl.Statement = kw
			hl.Conditional = kwc
			hl.Repeat = kwc
			hl.Label = { fg = s.label_grey }
			hl.Keyword = kw
			hl.Exception = kwc
			hl.StorageClass = kw
			hl.Structure = kw
			hl.Typedef = { fg = s.type_teal }
			hl.PreProc = { fg = s.keyword_blue }
			hl.Include = { fg = s.keyword_purple }
			hl.Define = { fg = s.keyword_blue }
			hl.Macro = { fg = s.keyword_blue }
			hl.PreCondit = { fg = s.keyword_blue }
			hl.Type = { fg = s.type_teal }
			hl.Special = { fg = s.function_yellow }
			hl.SpecialChar = { fg = s.escape_gold }
			hl.SpecialComment = { fg = s.function_yellow }
			hl.Tag = { fg = s.keyword_blue }
			hl.Delimiter = { fg = fg }
			hl.Debug = { fg = s.function_yellow }
			hl.Title = { fg = s.keyword_blue, bold = true }
			hl.Directory = { fg = s.keyword_blue }
			hl.Error = { fg = s.error_red }
			hl.WarningMsg = { fg = s.escape_gold }
			hl.MoreMsg = { fg = s.type_teal }
			hl.ModeMsg = { fg = s.type_teal }
			hl.Question = { fg = s.type_teal }
			hl.Todo = { fg = bg, bg = s.number_green }
			hl.ErrorMsg = { fg = s.error_red }
			hl.Conceal = { fg = fg_alt }
			hl.SpellBad = { fg = s.error_red, underline = true }
			hl.SpellCap = { fg = s.escape_gold, underline = true }
			hl.SpellLocal = { fg = s.type_teal, underline = true }
			hl.SpellRare = { fg = s.keyword_purple, underline = true }

			-- Treesitter captures (legacy + nvim 0.10 renames)
			hl["@comment"] = { fg = cmt }
			hl["@comment.documentation"] = { fg = cmt }
			hl["@string"] = { fg = s.string_orange }
			hl["@string.escape"] = { fg = s.escape_gold }
			hl["@string.special"] = { fg = s.keyword_blue }
			hl["@string.special.url"] = { fg = s.keyword_blue, underline = true }
			hl["@string.regexp"] = { fg = s.regexp_red }
			hl["@character"] = { fg = s.keyword_blue }
			hl["@character.special"] = { fg = s.escape_gold }
			hl["@number"] = { fg = s.number_green }
			hl["@boolean"] = { fg = s.keyword_blue }
			hl["@float"] = { fg = s.number_green }
			hl["@constant"] = { fg = s.constant_blue }
			hl["@constant.builtin"] = { fg = s.constant_blue }
			hl["@constant.macro"] = { fg = s.keyword_blue }
			hl["@variable"] = { fg = s.variable_blue }
			hl["@variable.builtin"] = { fg = s.keyword_blue }
			hl["@variable.parameter"] = { fg = s.variable_blue }
			hl["@variable.member"] = { fg = fg }
			hl["@variable.super"] = { fg = s.keyword_blue }
			hl["@parameter"] = { fg = s.variable_blue }
			hl["@field"] = { fg = s.variable_blue }
			hl["@property"] = { fg = s.variable_blue }
			hl["@function"] = { fg = s.function_yellow }
			hl["@function.call"] = { fg = s.function_yellow }
			hl["@function.builtin"] = { fg = s.function_yellow }
			hl["@function.macro"] = { fg = s.keyword_blue }
			hl["@function.method"] = { fg = s.function_yellow }
			hl["@function.method.call"] = { fg = s.function_yellow }
			hl["@method"] = { fg = s.function_yellow }
			hl["@method.call"] = { fg = s.function_yellow }
			hl["@constructor"] = { fg = s.type_teal }
			hl["@operator"] = { fg = fg }
			hl["@keyword"] = kw
			hl["@keyword.function"] = kw
			hl["@keyword.return"] = kwc
			hl["@keyword.operator"] = { fg = fg }
			hl["@keyword.conditional"] = kwc
			hl["@keyword.conditional.ternary"] = { fg = fg }
			hl["@keyword.repeat"] = kwc
			hl["@keyword.exception"] = kwc
			hl["@keyword.import"] = kwc
			hl["@keyword.directive"] = kwc
			hl["@keyword.modifier"] = kw
			hl["@keyword.type"] = kw
			hl["@keyword.export"] = kwc
			hl["@conditional"] = kwc
			hl["@repeat"] = kwc
			hl["@exception"] = kwc
			hl["@label"] = { fg = s.label_grey }
			hl["@include"] = { fg = s.keyword_purple }
			hl["@preproc"] = { fg = s.keyword_blue }
			hl["@define"] = { fg = s.keyword_blue }
			hl["@type"] = { fg = s.type_teal }
			hl["@type.builtin"] = { fg = s.type_teal }
			hl["@type.definition"] = { fg = s.type_teal }
			hl["@storageclass"] = kw
			hl["@structure"] = kw
			hl["@namespace"] = { fg = s.type_teal }
			hl["@module"] = { fg = s.type_teal }
			hl["@module.builtin"] = { fg = s.type_teal }
			hl["@punctuation"] = { fg = fg }
			hl["@punctuation.delimiter"] = { fg = fg }
			hl["@punctuation.bracket"] = { fg = s.tag_delimiter }
			hl["@punctuation.special"] = { fg = fg }
			hl["@tag"] = { fg = s.keyword_blue }
			hl["@tag.attribute"] = { fg = s.variable_blue }
			hl["@tag.delimiter"] = { fg = s.tag_delimiter }
			hl["@attribute"] = { fg = s.function_yellow }
			hl["@annotation"] = { fg = s.function_yellow }
			hl["@special"] = { fg = s.function_yellow }
			hl["@text.title"] = { fg = s.keyword_blue, bold = true }
			hl["@text.uri"] = { fg = s.keyword_blue, underline = true }
			hl["@text.literal"] = { fg = s.string_orange }
			hl["@text.underline"] = { fg = fg, underline = true }
			hl["@text.strike"] = { fg = fg_alt }
			hl["@markup.heading"] = { fg = s.keyword_blue, bold = true }
			hl["@markup.heading.1"] = { fg = s.keyword_blue, bold = true, underline = true }
			hl["@markup.heading.2"] = { fg = s.keyword_blue, bold = true }
			hl["@markup.heading.3"] = { fg = s.keyword_blue, bold = true }
			hl["@markup.heading.4"] = { fg = s.keyword_blue, bold = true }
			hl["@markup.heading.5"] = { fg = s.keyword_blue, bold = true }
			hl["@markup.heading.6"] = { fg = s.keyword_blue, bold = true }
			hl["@markup.bold"] = { fg = s.keyword_blue, bold = true }
			hl["@markup.strong"] = { fg = s.keyword_blue, bold = true }
			hl["@markup.italic"] = { fg = s.keyword_purple, italic = true }
			hl["@markup.list"] = { fg = s.keyword_blue }
			hl["@markup.list.checked"] = { fg = s.number_green }
			hl["@markup.list.unchecked"] = { fg = fg_alt }
			hl["@markup.quote"] = { fg = s.string_orange }
			hl["@markup.raw"] = { fg = s.string_orange }
			hl["@markup.raw.block"] = { fg = s.string_orange }
			hl["@markup.raw.inline"] = { fg = s.string_orange, bg = bg }
			hl["@markup.link"] = { fg = s.keyword_blue, underline = true }
			hl["@markup.link.label"] = { fg = s.variable_blue, underline = true }
			hl["@markup.link.url"] = { fg = s.keyword_blue, underline = true }

			-- Diagnostics
			hl.DiagnosticError = { fg = s.error_red }
			hl.DiagnosticWarn = { fg = s.escape_gold }
			hl.DiagnosticInfo = { fg = s.type_teal }
			hl.DiagnosticHint = { fg = s.number_green }
			hl.DiagnosticOk = { fg = s.number_green }
			hl["@diagnostic.error"] = { fg = s.error_red }
			hl["@diagnostic.warning"] = { fg = s.escape_gold }
			hl["@diagnostic.info"] = { fg = s.type_teal }
			hl["@diagnostic.hint"] = { fg = s.number_green }
			hl["@diagnostic.ok"] = { fg = s.number_green }

			-- LSP semantic tokens
			hl["@lsp.type.keyword"] = kw
			hl["@lsp.type.function"] = { fg = s.function_yellow }
			hl["@lsp.type.method"] = { fg = s.function_yellow }
			hl["@lsp.type.type"] = { fg = s.type_teal }
			hl["@lsp.type.class"] = { fg = s.type_teal }
			hl["@lsp.type.struct"] = { fg = s.type_teal }
			hl["@lsp.type.enum"] = { fg = s.type_teal }
			hl["@lsp.type.interface"] = { fg = s.type_teal }
			hl["@lsp.type.namespace"] = { fg = s.type_teal }
			hl["@lsp.type.typeParameter"] = { fg = s.type_teal }
			hl["@lsp.type.parameter"] = { fg = s.variable_blue }
			hl["@lsp.type.property"] = { fg = s.variable_blue }
			hl["@lsp.type.variable"] = { fg = s.variable_blue }
			hl["@lsp.type.enumMember"] = { fg = s.constant_blue }
			hl["@lsp.type.string"] = { fg = s.string_orange }
			hl["@lsp.type.number"] = { fg = s.number_green }
			hl["@lsp.type.comment"] = { fg = cmt }
		end,
	}
end

return { opts = opts }
