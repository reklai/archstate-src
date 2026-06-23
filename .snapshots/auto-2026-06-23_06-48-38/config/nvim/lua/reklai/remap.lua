vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Quality of life to focus different panes using "vim" movement.
-- Use <Cmd>wincmd ...<CR> (not <C-w>...) so these work in insert mode too:
-- in insert mode <C-w> is the built-in delete-word, so a raw <C-w>h RHS would
-- delete a word and insert a literal "h" instead of switching windows.
vim.keymap.set({ "n", "i" }, "<C-h>", "<Cmd>wincmd h<CR>", { desc = "Move focus to the left pane" })
vim.keymap.set({ "n", "i" }, "<C-l>", "<Cmd>wincmd l<CR>", { desc = "Move focus to the right pane" })
vim.keymap.set({ "n", "i" }, "<C-j>", "<Cmd>wincmd j<CR>", { desc = "Move focus to the bottom pane" })
vim.keymap.set({ "n", "i" }, "<C-k>", "<Cmd>wincmd k<CR>", { desc = "Move focus to the top pane" })

-- Double check for information (future self)
-- I believe the use-case worth it for rebinding
vim.keymap.set({ "n", "i" }, "<C-c>", "<Cmd>wincmd q<CR>", { desc = "Kill / Quit current window" })
vim.keymap.set({ "n", "i" }, "<C-v>", "<Cmd>vsplit<CR>", { desc = "Split current window" })

-- Hover Information
vim.keymap.set({ "n", "i" }, "<C-q>", vim.lsp.buf.signature_help, { desc = "LSP signature help" })

-- Take highlight text and move it up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Take line below and put it in front of the current line
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor on same spot while going up/down pages
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Q = exmode and K = either lsp hover information or man pages (help docs)
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "K", "<nop>")

-- Delete without yanking into clipboard
vim.keymap.set({ "n", "x" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Replace selected text without overwriting clipboard
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yanking selection" })

-- lazy way to find and replace globally
-- vim.keymap.set(
-- 	"n",
-- 	"<leader>z",
-- 	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
-- 	{ desc = "Replace all of current word" }
-- )
-- chmod -> give file executable permission
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Chmod file -> Make an exeutable.sh" })
