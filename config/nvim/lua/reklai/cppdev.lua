local M = {}

local uv = vim.uv or vim.loop

local defaults = {
	std = "23",
	build_type = "Debug",
	target = "",
}

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "cppdev" })
end

local function shellescape(value)
	return vim.fn.shellescape(value)
end

local function exists(path)
	return uv.fs_stat(path) ~= nil
end

local function dirname(path)
	return vim.fs.dirname(path)
end

local function basename(path)
	return vim.fs.basename(path)
end

local function current_dir()
	local name = vim.api.nvim_buf_get_name(0)
	if name ~= "" then
		return dirname(name)
	end
	return vim.fn.getcwd()
end

local function project_root(start)
	local dir = start or current_dir()
	while dir and dir ~= "/" do
		if exists(dir .. "/CMakeLists.txt") or exists(dir .. "/.cppdev") or exists(dir .. "/.git") then
			return dir
		end
		dir = dirname(dir)
	end
	return start or vim.fn.getcwd()
end

local function read_lines(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return {}
	end
	return lines
end

local function write_file(path, text, force)
	if exists(path) and not force then
		return
	end
	vim.fn.mkdir(dirname(path), "p")
	vim.fn.writefile(vim.split(text:gsub("\n$", ""), "\n"), path)
end

local function load_config(root)
	local config = vim.deepcopy(defaults)
	local path = root .. "/.cppdev"
	if not exists(path) then
		return config
	end

	for _, line in ipairs(read_lines(path)) do
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

local function save_config(root, config)
	vim.fn.writefile({
		"CXX_STANDARD=" .. config.std,
		"BUILD_TYPE=" .. config.build_type,
		"TARGET=" .. (config.target or ""),
	}, root .. "/.cppdev")
end

local function normalize_std(value, fallback)
	value = tostring(value or fallback or defaults.std)
	value = value:gsub("^c%+%+", "")
	local supported = { ["11"] = true, ["14"] = true, ["17"] = true, ["20"] = true, ["23"] = true, ["26"] = true }
	if not supported[value] then
		notify("unsupported C++ standard: " .. value .. " (use 17, 20, 23, or 26)", vim.log.levels.ERROR)
		return nil
	end
	return value
end

local function normalize_build_type(value, fallback)
	value = tostring(value or fallback or defaults.build_type)
	local lower = value:lower()
	if lower == "debug" then
		return "Debug"
	elseif lower == "release" then
		return "Release"
	elseif lower == "relwithdebinfo" then
		return "RelWithDebInfo"
	elseif lower == "minsizerel" then
		return "MinSizeRel"
	end
	notify("unsupported build type: " .. value, vim.log.levels.ERROR)
	return nil
end

local function build_dir(root, std, build_type)
	return string.format("%s/build/cpp%s-%s", root, std, build_type:lower())
end

local function run_terminal(command, cwd)
	vim.cmd("botright 14split")
	vim.cmd("terminal cd " .. shellescape(cwd) .. " && " .. command)
	vim.cmd("startinsert")
end

local function generator_args()
	if vim.fn.executable("ninja") == 1 then
		return "-G Ninja"
	end
	return "-G " .. shellescape("Unix Makefiles")
end

local function configure_command(root, std, build_type)
	local bdir = build_dir(root, std, build_type)
	return table.concat({
		"cmake",
		"-S " .. shellescape(root),
		"-B " .. shellescape(bdir),
		generator_args(),
		"-DCMAKE_BUILD_TYPE=" .. shellescape(build_type),
		"-DCMAKE_CXX_STANDARD=" .. shellescape(std),
		"-DCMAKE_CXX_STANDARD_REQUIRED=ON",
		"-DCMAKE_CXX_EXTENSIONS=OFF",
		"-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
		"&& ln -sfn " .. shellescape(bdir .. "/compile_commands.json") .. " " .. shellescape(
			root .. "/compile_commands.json"
		),
	}, " ")
end

local function require_cmake()
	if vim.fn.executable("cmake") == 1 then
		return true
	end
	notify("cmake is missing. Install: sudo pacman -S --needed cmake ninja", vim.log.levels.ERROR)
	return false
end

local function project_context()
	local root = project_root()
	local config = load_config(root)
	config.std = normalize_std(config.std, defaults.std) or defaults.std
	config.build_type = normalize_build_type(config.build_type, defaults.build_type) or defaults.build_type
	return root, config
end

local function sanitize_target(name)
	local target = name:gsub("[^A-Za-z0-9_]", "_")
	if target == "" then
		return "app"
	end
	return target
end

local function update_clangd_standard(root, std)
	local path = root .. "/.clangd"
	if not exists(path) then
		return
	end
	local lines = read_lines(path)
	for i, line in ipairs(lines) do
		lines[i] = line:gsub("%-std=c%+%+%d+", "-std=c++" .. std)
	end
	vim.fn.writefile(lines, path)
end

local function update_cmake_standard(root, std)
	local path = root .. "/CMakeLists.txt"
	if not exists(path) then
		return
	end
	local lines = read_lines(path)
	for i, line in ipairs(lines) do
		if line:match("^%s*set%(%s*CMAKE_CXX_STANDARD%s+") then
			lines[i] = "set(CMAKE_CXX_STANDARD " .. std .. ' CACHE STRING "C++ language standard")'
		end
	end
	vim.fn.writefile(lines, path)
end

local templates = {}

templates.main = [[
#include <iostream>

int main() {
    std::cout << "Hello, C++\n";
    return 0;
}
]]

templates.cmake = [[
cmake_minimum_required(VERSION 3.20)

project(%s LANGUAGES CXX)

set(CMAKE_CXX_STANDARD %s CACHE STRING "C++ language standard")
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(%s
    src/main.cpp
)

target_include_directories(%s
    PRIVATE
        ${PROJECT_SOURCE_DIR}/include
)

target_compile_options(%s
    PRIVATE
        -Wall
        -Wextra
        -Wpedantic
)
]]

templates.clang_format = [[
BasedOnStyle: LLVM
IndentWidth: 4
ColumnLimit: 100
AllowShortFunctionsOnASingleLine: Empty
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false
BreakBeforeBraces: Attach
PointerAlignment: Left
ReferenceAlignment: Left
SortIncludes: CaseSensitive
]]

templates.clang_tidy = [[
Checks: >
  clang-analyzer-*,
  bugprone-*,
  performance-*,
  portability-*,
  modernize-*,
  readability-*,
  cppcoreguidelines-*,
  -modernize-use-trailing-return-type,
  -readability-magic-numbers,
  -cppcoreguidelines-avoid-magic-numbers,
  -cppcoreguidelines-pro-bounds-pointer-arithmetic,
  -cppcoreguidelines-pro-type-vararg
WarningsAsErrors: ''
HeaderFilterRegex: '.*'
FormatStyle: file
]]

templates.clangd = [[
CompileFlags:
  Add:
    - -std=c++%s
    - -Wall
    - -Wextra
    - -Wpedantic
Diagnostics:
  ClangTidy:
    Add:
      - clang-analyzer-*
      - bugprone-*
      - performance-*
      - portability-*
      - modernize-*
Index:
  Background: Build
]]

function M.init_project()
	vim.ui.input({ prompt = "C++ project name (. for current dir): ", default = "." }, function(name)
		if not name or name == "" then
			return
		end
		vim.ui.input({ prompt = "C++ standard (17/20/23/26): ", default = defaults.std }, function(input_std)
			local std = normalize_std(input_std, defaults.std)
			if not std then
				return
			end

			local root = name == "." and vim.fn.getcwd() or (vim.fn.getcwd() .. "/" .. name)
			vim.fn.mkdir(root .. "/src", "p")
			vim.fn.mkdir(root .. "/include", "p")

			local target = sanitize_target(basename(root))
			write_file(root .. "/src/main.cpp", templates.main, false)
			write_file(
				root .. "/CMakeLists.txt",
				string.format(templates.cmake, target, std, target, target, target),
				false
			)
			write_file(root .. "/.clang-format", templates.clang_format, false)
			write_file(root .. "/.clang-tidy", templates.clang_tidy, false)
			write_file(root .. "/.clangd", string.format(templates.clangd, std), false)
			save_config(root, { std = std, build_type = defaults.build_type, target = target })

			notify("created C++ project: " .. root)
			vim.cmd("edit " .. vim.fn.fnameescape(root .. "/src/main.cpp"))
			if vim.fn.executable("cmake") == 1 then
				M.configure({ root = root, std = std, build_type = defaults.build_type })
			end
		end)
	end)
end

function M.configure(opts)
	opts = opts or {}
	local root, config = opts.root, nil
	if root then
		config = load_config(root)
	else
		root, config = project_context()
	end
	local std = normalize_std(opts.std, config.std)
	local build_type = normalize_build_type(opts.build_type, config.build_type)
	if not std or not build_type or not require_cmake() then
		return
	end
	if not exists(root .. "/CMakeLists.txt") then
		notify("no CMakeLists.txt found. Use <leader>ci to create a project.", vim.log.levels.ERROR)
		return
	end

	config.std = std
	config.build_type = build_type
	save_config(root, config)
	run_terminal(configure_command(root, std, build_type), root)
end

function M.build(opts)
	opts = opts or {}
	local root, config = project_context()
	local std = normalize_std(opts.std, config.std)
	local build_type = normalize_build_type(opts.build_type, config.build_type)
	if not std or not build_type or not require_cmake() then
		return
	end

	local bdir = build_dir(root, std, build_type)
	local command = ""
	if not exists(bdir) then
		command = configure_command(root, std, build_type) .. " && "
	end
	command = command .. "cmake --build " .. shellescape(bdir)
	run_terminal(command, root)
end

function M.run(opts)
	opts = opts or {}
	local root, config = project_context()
	local std = normalize_std(opts.std, config.std)
	local build_type = normalize_build_type(opts.build_type, config.build_type)
	if not std or not build_type or not require_cmake() then
		return
	end

	local bdir = build_dir(root, std, build_type)
	local command = ""
	if not exists(bdir) then
		command = configure_command(root, std, build_type) .. " && "
	end

	local target = config.target or ""
	command = command
		.. "cmake --build "
		.. shellescape(bdir)
		.. " && exe=''; "
		.. "if [ -n "
		.. shellescape(target)
		.. " ] && [ -x "
		.. shellescape(bdir .. "/" .. target)
		.. " ]; then exe="
		.. shellescape(bdir .. "/" .. target)
		.. "; else exe=$(find "
		.. shellescape(bdir)
		.. " -maxdepth 2 -type f -executable ! -name '*.so' ! -name '*.a' ! -name '*.o' ! -path '*/CMakeFiles/*' | sort | head -n 1); fi; "
		.. "[ -n \"$exe\" ] || { echo 'built successfully, but no executable target was found'; exit 1; }; "
		.. '"$exe"'

	run_terminal(command, root)
end

function M.set_standard(value)
	local root, config = project_context()
	local apply = function(input)
		local std = normalize_std(input, config.std)
		if not std then
			return
		end

		config.std = std
		save_config(root, config)
		update_clangd_standard(root, std)
		update_cmake_standard(root, std)
		notify("C++ standard set to c++" .. std)
	end

	if value and value ~= "" then
		apply(value)
		return
	end

	vim.ui.input({ prompt = "C++ standard (17/20/23/26): ", default = config.std }, apply)
end

function M.clean()
	local root = project_root()
	vim.fn.delete(root .. "/build", "rf")
	vim.fn.delete(root .. "/compile_commands.json")
	notify("removed build output")
end

function M.doctor()
	local tools = {
		"gcc",
		"g++",
		"clang",
		"clang++",
		"clangd",
		"clang-format",
		"clang-tidy",
		"cmake",
		"ninja",
		"make",
		"gdb",
		"lldb",
		"bear",
	}
	local lines = {}
	for _, tool in ipairs(tools) do
		local path = vim.fn.exepath(tool)
		if path == "" then
			table.insert(lines, string.format("%-14s missing", tool))
		else
			table.insert(lines, string.format("%-14s %s", tool, path))
		end
	end

	vim.cmd("botright 14new")
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.api.nvim_buf_set_name(0, "cppdev://doctor")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.bo.modifiable = false
end

function M.setup()
	vim.keymap.set("n", "<leader>ci", M.init_project, { desc = "C++ init project" })
	vim.keymap.set("n", "<leader>cc", M.configure, { desc = "C++ configure" })
	vim.keymap.set("n", "<leader>cb", M.build, { desc = "C++ build" })
	vim.keymap.set("n", "<leader>cr", M.run, { desc = "C++ run" })
	vim.keymap.set("n", "<leader>cs", function()
		M.set_standard()
	end, { desc = "C++ standard" })
	vim.keymap.set("n", "<leader>cx", M.clean, { desc = "C++ clean" })
	vim.keymap.set("n", "<leader>cd", M.doctor, { desc = "C++ doctor" })

	vim.api.nvim_create_user_command("CppInit", M.init_project, {})
	vim.api.nvim_create_user_command("CppConfigure", M.configure, {})
	vim.api.nvim_create_user_command("CppBuild", M.build, {})
	vim.api.nvim_create_user_command("CppRun", M.run, {})
	vim.api.nvim_create_user_command("CppClean", M.clean, {})
	vim.api.nvim_create_user_command("CppDoctor", M.doctor, {})
	vim.api.nvim_create_user_command("CppStd", function(command)
		M.set_standard(command.args)
	end, { nargs = "?" })
end

return M
