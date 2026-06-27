return {
	{
		"mfussenegger/nvim-jdtls",
		ft = "java",
		cmd = {
			"JavaBuild",
			"JavaRun",
			"JavaDebug",
			"JavaTestNearest",
			"JavaTestClass",
			"JavaDebugTestNearest",
			"JavaOrganizeImports",
			"JavaGenerate",
			"JavaRefresh",
			"JavaSwitchRuntime",
		},
		dependencies = {
			"mfussenegger/nvim-dap",
			"saghen/blink.cmp",
		},
		keys = {
			{
				"<leader>jr",
				function()
					require("reklai.java.tasks").run_app()
				end,
				desc = "Start app normally",
			},
			{
				"<leader>jd",
				function()
					require("reklai.java.tasks").debug_app()
				end,
				desc = "Start app with debugger",
			},
			{
				"<leader>jt",
				function()
					require("reklai.java.tasks").run_test_nearest()
				end,
				desc = "Run this test",
			},
			{
				"<leader>jT",
				function()
					require("reklai.java.tasks").run_test_class()
				end,
				desc = "Run all tests in file",
			},
			{
				"<leader>jD",
				function()
					require("reklai.java.tasks").debug_test_nearest()
				end,
				desc = "Debug this test",
			},
			{
				"<leader>jo",
				function()
					require("reklai.java.tasks").organize_imports()
				end,
				desc = "Clean up imports",
			},
			{
				"<leader>jg",
				function()
					require("reklai.java.tasks").generate()
				end,
				desc = "Generate getters/ctors/etc",
			},
			{
				"<leader>jp",
				function()
					require("reklai.java.tasks").refresh_project()
				end,
				desc = "Re-read pom/gradle files",
			},
			{
				"<leader>jv",
				function()
					require("reklai.java.tasks").switch_runtime()
				end,
				desc = "Choose Java version",
			},
		},
		config = function()
			require("reklai.java.tasks").setup_commands()
			local start_jdtls = function(bufnr)
				require("reklai.java.jdtls").start(bufnr)
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("reklai-java-jdtls", { clear = true }),
				pattern = "java",
				callback = function(args)
					start_jdtls(args.buf)
				end,
			})

			if vim.bo.filetype == "java" then
				start_jdtls(0)
			end
		end,
	},
	{
		"stevearc/overseer.nvim",
		cmd = {
			"OverseerBuild",
			"OverseerClearCache",
			"OverseerClose",
			"OverseerDeleteBundle",
			"OverseerInfo",
			"OverseerLoadBundle",
			"OverseerOpen",
			"OverseerQuickAction",
			"OverseerRun",
			"OverseerRunCmd",
			"OverseerSaveBundle",
			"OverseerTaskAction",
			"OverseerToggle",
		},
		keys = {
			{
				"<leader>jb",
				function()
					require("reklai.java.tasks").build_picker()
				end,
				desc = "Build/package/test tasks",
			},
		},
		opts = {
			task_list = {
				direction = "bottom",
				min_height = 12,
				max_height = 20,
				default_detail = 1,
			},
		},
	},
	{
		"mfussenegger/nvim-dap",
	},
	{
		"nvim-neotest/nvim-nio",
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		dependencies = { "mfussenegger/nvim-dap" },
		opts = {},
	},
}
