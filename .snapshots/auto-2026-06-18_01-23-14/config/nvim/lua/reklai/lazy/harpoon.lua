local harpoon
return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2", -- Temp; Will be merged soonish 🔥
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		harpoon = require("harpoon"):setup() -- Notice we're storing to parent context 👆
		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end, { desc = "add to harpoon list" })
		vim.keymap.set({ "n", "i" }, "<leader>o", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "harpoon menu" })

		vim.keymap.set({ "n", "i" }, "<C-e>", function()
			harpoon:list():select(1)
		end)
		vim.keymap.set({ "n", "i" }, "<C-t>", function()
			harpoon:list():select(2)
		end)
		vim.keymap.set({ "n", "i" }, "<C-s>", function()
			harpoon:list():select(3)
		end)
		vim.keymap.set({ "n", "i" }, "<C-g>", function()
			harpoon:list():select(4)
		end)
	end,
}
