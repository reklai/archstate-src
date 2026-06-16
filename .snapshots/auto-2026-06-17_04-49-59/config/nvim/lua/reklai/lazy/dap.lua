local function project_root()
	local name = vim.api.nvim_buf_get_name(0)
	local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
	return vim.fs.root(start, { "CMakeLists.txt", ".cppdev", ".git" }) or start
end

local function read_cppdev(root)
	local config = {
		std = "23",
		build_type = "Debug",
		target = "",
	}
	local path = root .. "/.cppdev"
	if vim.uv.fs_stat(path) == nil then
		return config
	end

	for _, line in ipairs(vim.fn.readfile(path)) do
		local key, value = line:match("^([A-Z_]+)=(.*)$")
		if key == "CXX_STANDARD" then
			config.std = value
		elseif key == "BUILD_TYPE" then
			config.build_type = value
		elseif key == "TARGET" then
			config.target = value
		end
	end

	return config
end

local function build_dir(root, config)
	return string.format("%s/build/cpp%s-%s", root, config.std, config.build_type:lower())
end

local function is_executable(path)
	return path and path ~= "" and vim.fn.executable(path) == 1
end

local function find_project_executable(root, config)
	local bdir = build_dir(root, config)
	if config.target ~= "" and is_executable(bdir .. "/" .. config.target) then
		return bdir .. "/" .. config.target
	end

	local command = table.concat({
		"find",
		vim.fn.shellescape(bdir),
		"-maxdepth 2 -type f -executable",
		"! -name '*.so'",
		"! -name '*.a'",
		"! -name '*.o'",
		"! -path '*/CMakeFiles/*'",
		"2>/dev/null | sort | head -n 1",
	}, " ")

	local found = vim.fn.systemlist(command)[1]
	if vim.v.shell_error == 0 and found and found ~= "" then
		return found
	end
	return nil
end

local function debug_program()
	local root = project_root()
	local config = read_cppdev(root)
	local detected = find_project_executable(root, config)
	local fallback = detected or build_dir(root, config) .. "/"
	return vim.fn.input("Executable: ", fallback, "file")
end

local function codelldb_command()
	local candidates = {
		vim.fn.stdpath("data") .. "/mason/bin/codelldb",
		vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
		vim.fn.exepath("codelldb"),
	}
	for _, candidate in ipairs(candidates) do
		if is_executable(candidate) then
			return candidate
		end
	end
	return nil
end

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"theHamsta/nvim-dap-virtual-text",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		dapui.setup()
		require("nvim-dap-virtual-text").setup({
			commented = true,
		})

		local adapter_name
		local codelldb = codelldb_command()
		if codelldb then
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = codelldb,
					args = { "--port", "${port}" },
				},
			}
			adapter_name = "codelldb"
		elseif vim.fn.executable("lldb-dap") == 1 then
			dap.adapters.lldb = {
				type = "executable",
				command = "lldb-dap",
				name = "lldb",
			}
			adapter_name = "lldb"
		end

		if adapter_name then
			local cpp_config = {
				name = "Debug executable",
				type = adapter_name,
				request = "launch",
				program = debug_program,
				cwd = project_root,
				stopOnEntry = false,
				args = {},
			}

			dap.configurations.cpp = { cpp_config }
			dap.configurations.c = { cpp_config }
			dap.configurations.rust = { cpp_config }
		else
			vim.notify(
				"No C++ debug adapter found. Install codelldb with :Mason or install lldb.",
				vim.log.levels.WARN,
				{ title = "nvim-dap" }
			)
		end

		dap.listeners.before.attach.dapui_config = dapui.open
		dap.listeners.before.launch.dapui_config = dapui.open
		dap.listeners.before.event_terminated.dapui_config = dapui.close
		dap.listeners.before.event_exited.dapui_config = dapui.close

		vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug continue/start" })
		vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "Debug breakpoint" })
		vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug step over" })
		vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug step into" })
		vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug step out" })

		vim.keymap.set("n", "<leader>cD", dap.continue, { desc = "C++ debug start/continue" })
		vim.keymap.set("n", "<leader>cB", dap.toggle_breakpoint, { desc = "C++ debug breakpoint" })
		vim.keymap.set("n", "<leader>cT", dap.terminate, { desc = "C++ debug terminate" })
		vim.keymap.set("n", "<leader>cU", dapui.toggle, { desc = "C++ debug UI" })
		vim.keymap.set("n", "<leader>cE", function()
			dapui.eval(nil, { enter = true })
		end, { desc = "C++ debug eval" })
		vim.keymap.set("n", "<leader>cL", dap.run_last, { desc = "C++ debug last" })

		vim.api.nvim_create_user_command("CppDebug", dap.continue, {})
		vim.api.nvim_create_user_command("CppDebugLast", dap.run_last, {})
		vim.api.nvim_create_user_command("CppDebugUi", dapui.toggle, {})
		vim.api.nvim_create_user_command("CppBreakpoint", dap.toggle_breakpoint, {})
	end,
}
