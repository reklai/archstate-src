return {
	"nvim-mini/mini.indentscope",
	version = false,
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local indentscope = require("mini.indentscope")

		indentscope.setup({
			draw = {
				-- Instant: no per-cursor delay and no animation, so the scope
				-- line snaps into place immediately.
				delay = 0,
				animation = indentscope.gen_animation.none(),
			},
			options = {
				try_as_border = true,
			},
			symbol = "▎",
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "oil",
			callback = function()
				vim.b.miniindentscope_disable = true
			end,
		})
	end,
}
