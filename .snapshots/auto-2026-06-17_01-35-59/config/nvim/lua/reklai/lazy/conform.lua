return { -- Autoformat
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			return {
				timeout_ms = 1000,
				lsp_format = "fallback",
			}
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "goimports", "gofumpt" },
			zig = { "zigfmt" },
			rust = { "rustfmt" },
			c = { "clang_format" },
			cpp = { "clang_format" },
			javascript = { "prettierd", "eslint_d" },
			javascriptreact = { "prettierd", "eslint_d" },
			typescript = { "prettierd", "eslint_d" },
			typescriptreact = { "prettierd", "eslint_d" },
			json = { "prettierd" },
			jsonc = { "prettierd" },
			python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
			-- Conform can also run multiple formatters sequentially
			-- python = { "isort", "black" },
			--
			-- You can use 'stop_after_first' to run the first available formatter from the list
			-- javascript = { "prettierd", "prettier", stop_after_first = true },
		},
	},
}
