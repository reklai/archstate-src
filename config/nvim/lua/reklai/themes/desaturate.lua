-- desaturate -- runtime saturation control for theme palettes.
--
-- Themes store their palettes at full strength. At opts() time they pass the
-- palette through `palette(tbl, scale)` to get a copy whose HSL saturation
-- has been multiplied by `scale`. Greys (S ~= 0) are a mathematical no-op
-- (`S * scale ~= 0`), so surfaces/text/borders pass through untouched; only
-- chromatic tokens shift.
--
-- Scale semantics:
--   1.0 = original colors (the default when vim.g.theme_saturation is unset)
--   0.7 = 30% weaker ("softer" / less abrasive)
--   0.0 = fully desaturated (grayscale, hue/lightness preserved)

local M = {}

-- Hex <-> RGB (0-1 floats)
local function hex2rgb(hex)
	hex = hex:gsub("^#", "")
	local r = tonumber(hex:sub(1, 2), 16) / 255
	local g = tonumber(hex:sub(3, 4), 16) / 255
	local b = tonumber(hex:sub(5, 6), 16) / 255
	return r, g, b
end

local function rgb2hex(r, g, b)
	local function clamp(v)
		return math.max(0, math.min(255, math.floor(v * 255 + 0.5)))
	end
	return string.format("#%02x%02x%02x", clamp(r), clamp(g), clamp(b))
end

-- RGB (0-1) <-> HSL (H: 0-1, S: 0-1, L: 0-1)
local function rgb2hsl(r, g, b)
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local l = (max + min) / 2
	if max == min then
		return 0, 0, l -- achromatic
	end
	local d = max - min
	local s
	if l > 0.5 then
		s = d / (2 - max - min)
	else
		s = d / (max + min)
	end
	local h
	if max == r then
		h = (g - b) / d
		if h < 0 then
			h = h + 6
		end
	elseif max == g then
		h = (b - r) / d + 2
	else
		h = (r - g) / d + 4
	end
	h = h / 6
	return h, s, l
end

local function hue2rgb(p, q, t)
	if t < 0 then
		t = t + 1
	end
	if t > 1 then
		t = t - 1
	end
	if t < 1 / 6 then
		return p + (q - p) * 6 * t
	end
	if t < 1 / 2 then
		return q
	end
	if t < 2 / 3 then
		return p + (q - p) * (2 / 3 - t) * 6
	end
	return p
end

local function hsl2rgb(h, s, l)
	if s == 0 then
		return l, l, l -- achromatic
	end
	local q
	if l < 0.5 then
		q = l * (1 + s)
	else
		q = l + s - l * s
	end
	local p = 2 * l - q
	return hue2rgb(p, q, h + 1 / 3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1 / 3)
end

-- Desaturate a single hex color by `scale` (HSL S *= scale).
-- Returns the same hex value if `scale` is nil or >= 1 (no work needed)
-- or if the input isn't a valid #rrggbb string.
local HEX_PATTERN = "^#%x%x%x%x%x%x$"

function M.desaturate(hex, scale)
	if type(hex) ~= "string" or not hex:match(HEX_PATTERN) then
		return hex
	end
	if scale == nil or scale >= 1 then
		return hex
	end
	if scale <= 0 then
		-- Fully desaturated: keep lightness, drop chroma.
		-- Easiest correct form: compute the luma-equivalent grey via HSL with s=0.
		local r, g, b = hex2rgb(hex)
		local _, _, l = rgb2hsl(r, g, b)
		return rgb2hex(l, l, l)
	end

	local r, g, b = hex2rgb(hex)
	local h, s, l = rgb2hsl(r, g, b)
	local s2 = s * scale
	local r2, g2, b2 = hsl2rgb(h, s2, l)
	return rgb2hex(r2, g2, b2)
end

-- Walk a palette table, return a new table with every hex value desaturated.
-- Non-hex values (strings, tables, etc.) pass through unchanged.
function M.palette(tbl, scale)
	if scale == nil or scale >= 1 then
		-- No work: either the default (1.0) or an explicit no-op.
		return tbl
	end
	local out = {}
	for k, v in pairs(tbl) do
		if type(v) == "string" then
			out[k] = M.desaturate(v, scale)
		else
			out[k] = v
		end
	end
	return out
end

-- Blend two hex colors by alpha. Result = fg*alpha + bg*(1-alpha).
-- Used for opacity-aware float backgrounds: blend a theme panel bg with
-- black at the user-chosen opacity so floats are semi-readable over the
-- terminal's transparent backdrop. Pass-through for invalid input.
function M.blend(fg_hex, bg_hex, alpha)
	if type(fg_hex) ~= "string" or not fg_hex:match(HEX_PATTERN) then
		return fg_hex
	end
	if type(bg_hex) ~= "string" or not bg_hex:match(HEX_PATTERN) then
		return fg_hex
	end
	if alpha == nil or alpha >= 1 then
		return fg_hex
	end
	if alpha <= 0 then
		return bg_hex
	end
	local fr, fg_, fb = hex2rgb(fg_hex)
	local br, bg_, bb = hex2rgb(bg_hex)
	return rgb2hex(fr * alpha + br * (1 - alpha), fg_ * alpha + bg_ * (1 - alpha), fb * alpha + bb * (1 - alpha))
end

return M
