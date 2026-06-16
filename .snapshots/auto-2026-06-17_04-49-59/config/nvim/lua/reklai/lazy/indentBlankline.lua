return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local hooks = require("ibl.hooks")

		hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
			local ok, colors = pcall(require, "nordic.colors")
			local indent = ok and colors.gray2 or "#3B4252"
			local scope = ok and colors.gray5 or "#60728A"

			vim.api.nvim_set_hl(0, "IblIndent", { fg = indent, nocombine = true })
			vim.api.nvim_set_hl(0, "IblScope", { fg = scope, nocombine = true })
		end)

		require("ibl").setup({
			scope = {
				show_exact_scope = true,
			},
			exclude = {
				filetypes = { "oil" },
			},
		})
	end,
}
