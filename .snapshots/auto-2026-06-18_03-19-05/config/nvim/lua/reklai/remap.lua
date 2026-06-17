-- Run `:Tutor` in Neovim to start the tutorial if you’re unfamiliar with Neovim basics.
-- Run and read `:help` for more information on Neovim’s built-in help system.
-- The keymap `<space>sh` is set to search the help documentation, which is useful when you're unsure of what you're looking for.
-- Throughout the `init.lua` configuration file, there are comments like `-- [help]`, which guide you to relevant help pages.

-- Troubleshooting:
-- If you encounter errors during installation, run `:checkhealth` to get more information.

-- Split Navigation Keymaps:
-- Use `CTRL+<hjkl>` to navigate between windows:
-- `<C-h>` moves focus to the left window.
-- `<C-l>` moves focus to the right window.
-- `<C-j>` moves focus to the lower window.
-- `<C-k>` moves focus to the upper window.

vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.mapleader, { desc = "Open diagnostic [Q]uickfix list" })
-- vim.keymap.set("n", "<leader>l", vim.diagnostic.setloclist, { desc = "Open diagnostic [L]ocation list" })

-- Remap Ctrl-^ means original edited file to Ctrl-q
vim.keymap.set("n", "<C-q>", "<C-^>")
vim.keymap.set("n", "<C-w>", function()
	vim.lsp.buf.hover({ border = "single", max_height = 25, max_width = 120 })
end, { desc = "Hover documentation" })
-- Move panes
vim.keymap.set({ "n", "i" }, "<C-v>", "<Cmd>vsplit<CR>", { desc = "Vertical split" })
vim.keymap.set({ "n", "i" }, "<C-c>", "<C-w><C-q>", { desc = "Close pane/window" })
vim.keymap.set({ "n", "i" }, "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left pane" })
vim.keymap.set({ "n", "i" }, "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right pane" })
-- Move windows
vim.keymap.set({ "n", "i" }, "<leader><leader>", "<C-w>w", { desc = "Toggle window focus" })
-- vim.keymap.set({ "n", "i" }, "<leader>h", "<C-w>h", { desc = "Move focus to the left window" })
-- vim.keymap.set({ "n", "i" }, "<leader>l", "<C-w>l", { desc = "Move focus to the right window" })
-- vim.keymap.set({ "n", "i" }, "<leader>k", "<C-w>k", { desc = "Move focus to the upper window" })
-- vim.keymap.set({ "n", "i" }, "<leader>j", "<C-w>j", { desc = "Move focus to the lower window" })

-- Jump prev / next diagnostic
vim.keymap.set("n", "<C-[>", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })

vim.keymap.set("n", "<C-]>", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

-- Take highlight text and move it up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Jump prev / next on quickfix list
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")

-- lazy way to find and replace globally
vim.keymap.set(
	"n",
	"<leader>z",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Replace all of current word" }
)
-- chmod -> give file executable permission
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Chmod file -> Make an exeutable.sh" })

-- Take line below and put it in front of the current line
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor on same spot while going up/down pages
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Q is no inop
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "K", "<nop>")

-- Delete to void register and paste current buffer
vim.keymap.set({ "n", "v" }, "<leader>d", [["_dP]])
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Copy to system clipboard not buffer register
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Tab similar to vs code
vim.keymap.set("v", "<Tab>", ">gv")
vim.keymap.set("v", "<S-Tab>", "<gv")

-- Golang Specific (spawn if err != nil syntax)
-- vim.keymap.set("n", "<leader>ee", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>")
