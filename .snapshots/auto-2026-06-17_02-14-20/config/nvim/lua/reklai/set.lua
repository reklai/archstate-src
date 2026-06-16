--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false -- Set to `true` if you have a Nerd Font installed and want to use it.
vim.opt.foldenable = false -- Disable folding of code by default.
vim.wo.foldlevel = 99

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true -- Show absolute line numbers by default.

-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.opt.relativenumber = true  -- Uncomment to enable relative line numbers for easier navigation.

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a" -- Enable mouse support for all modes (normal, insert, etc.).

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false -- Disable showing the mode in the command line.

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus" -- Sync Neovim's clipboard with the system clipboard.
end)

-- Enable break indent
vim.opt.breakindent = true -- Automatically indent wrapped lines to align with the previous line's indent.

-- Save undo history
vim.opt.undofile = true -- Enable saving undo history to a file, so undo is persistent across sessions.

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true -- Makes searches case-insensitive by default.
vim.opt.smartcase = true -- When search contains capital letters, case-sensitive search is used.

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300 -- Set the time (in milliseconds) Neovim waits for a mapped key sequence.

-- Configure how new splits should be opened
vim.opt.splitright = true -- New vertical splits will open to the right.
vim.opt.splitbelow = true -- New horizontal splits will open below the current window.

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true -- Enable the display of whitespace characters (e.g., spaces, tabs).
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- Customize the symbols for tab, trailing spaces, and non-breaking spaces.

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split" -- Show a preview of substitutions in a split window as you type.

-- Show which line your cursor is on
vim.opt.cursorline = true -- Highlight the line where the cursor is located.

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.opt.confirm = true -- Ask for confirmation when closing a file with unsaved changes.

vim.opt.nu = true -- Enable line numbers.
vim.opt.relativenumber = true -- Enable relative line numbers (useful for jumping to specific lines).
vim.opt.tabstop = 4 -- Set the width of a tab character (number of spaces it represents).
vim.opt.softtabstop = 4 -- Number of spaces a tab character behaves like in insert mode.
vim.opt.shiftwidth = 4 -- Number of spaces to use for each indentation level.
vim.opt.expandtab = true -- Use spaces instead of tabs for indentation.

vim.opt.smartindent = true -- Enable smart indentation, adjusting indent levels based on syntax.

vim.opt.wrap = false -- Disable line wrapping; long lines will scroll horizontally.

vim.opt.swapfile = false -- Disable swap files to prevent creating backup files.
vim.opt.backup = false -- Disable backup files (e.g., `file~` files).
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir" -- Set the directory to store undo history files.
vim.opt.undofile = true -- Enable undo files so that undo history persists between sessions.

vim.opt.hlsearch = false -- Disable highlighting of search matches.
vim.opt.incsearch = true -- Enable incremental search, highlighting matches as you type.

vim.opt.termguicolors = true -- Enable true color support in the terminal.

vim.opt.scrolloff = 10 -- Keep at least 10 lines above and below the cursor when scrolling.

vim.opt.signcolumn = "yes" -- Always show the sign column (for things like diagnostics and git status).

vim.opt.isfname:append("@-@") -- Add `@-@` to `isfname` to allow special characters like `-` in file names.

vim.opt.updatetime = 50 -- Set the time (in milliseconds) for Neovim to wait before updating the display (e.g., after typing).

vim.opt.colorcolumn = "80" -- Highlight column 80 to indicate line length limit (useful for code formatting).
