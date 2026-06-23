return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			columns = { "icon" },
			keymaps = {
				["<C-h>"] = false,
				["<C-l>"] = false,
				["<C-k>"] = false,
				["<C-j>"] = false,
				["<C-s>"] = false,
				["<C-t>"] = false,
				["<C-q>"] = false,
			},
			view_options = {
				show_hidden = true,
				is_always_hidden = function(name, _)
					local folder_skip = { "dev-tools.locks", "dune.lock", "_build" }
					return vim.tbl_contains(folder_skip, name)
				end,
			},
		})

		-- Open parent directory in current window
		vim.keymap.set("n", "<space>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
	end,
}
