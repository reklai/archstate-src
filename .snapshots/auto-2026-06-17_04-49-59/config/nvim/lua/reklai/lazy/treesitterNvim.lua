return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local treesitter = require("nvim-treesitter")
		local parsers = {
			"c",
			"cpp",
			"python",
			"lua",
			"go",
			"rust",
			"zig",
			"html",
			"css",
			"javascript",
			"typescript",
			"tsx",
			"hyprlang",
		}

		treesitter.setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})
		treesitter.install(parsers)

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("ReklaiTreesitter", { clear = true }),
			pattern = {
				"c",
				"cpp",
				"python",
				"lua",
				"go",
				"rust",
				"zig",
				"html",
				"css",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"tsx",
				"hyprlang",
			},
			callback = function(event)
				local max_filesize = 100 * 1024 -- 100 KB
				local ok, stats = pcall((vim.uv or vim.loop).fs_stat, vim.api.nvim_buf_get_name(event.buf))
				if ok and stats and stats.size > max_filesize then
					return
				end

				pcall(vim.treesitter.start, event.buf)
			end,
		})
	end,
}
