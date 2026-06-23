return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup()

		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end, { desc = "Harpoon add file" })

		vim.keymap.set("n", "<leader>o", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Harpoon menu" })

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
