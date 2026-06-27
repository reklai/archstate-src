local runtime = require("reklai.java.runtime")

local M = {}

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "Java" })
end

local function executable(path)
	return vim.fn.executable(path) == 1
end

local function exists(path)
	return vim.uv.fs_stat(path) ~= nil
end

local function has_file(root, name)
	return exists(root .. "/" .. name)
end

local function read_file(path)
	local fd = vim.uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end

	local stat = vim.uv.fs_fstat(fd)
	local data = stat and vim.uv.fs_read(fd, stat.size, 0) or nil
	vim.uv.fs_close(fd)
	return data
end

local function project_root()
	return runtime.project_root(0)
end

local function java_executable(root)
	local selected = runtime.project_runtime(root)
	return selected and (selected.path .. "/bin/java") or nil
end

local function project_files(root)
	local files = {}
	for _, name in ipairs({
		"pom.xml",
		"build.gradle",
		"build.gradle.kts",
		"settings.gradle",
		"settings.gradle.kts",
	}) do
		local text = read_file(root .. "/" .. name)
		if text then
			files[#files + 1] = text
		end
	end
	return table.concat(files, "\n")
end

local function is_spring_project(root)
	local text = project_files(root)
	return text:find("spring-boot", 1, true)
		or text:find("org.springframework.boot", 1, false)
		or text:find("SpringApplication", 1, false)
end

local function build_tools(root)
	local tools = {}

	if has_file(root, "pom.xml") or has_file(root, "mvnw") then
		tools[#tools + 1] = "maven"
	end

	if
		has_file(root, "build.gradle")
		or has_file(root, "build.gradle.kts")
		or has_file(root, "settings.gradle")
		or has_file(root, "settings.gradle.kts")
		or has_file(root, "gradlew")
	then
		tools[#tools + 1] = "gradle"
	end

	return tools
end

local function command_for(root, tool, goals)
	if tool == "maven" then
		local wrapper = root .. "/mvnw"
		if exists(wrapper) and executable(wrapper) then
			return wrapper, goals
		elseif exists(wrapper) then
			return "sh", vim.list_extend({ wrapper }, goals)
		end
		return "mvn", goals
	end

	local wrapper = root .. "/gradlew"
	if exists(wrapper) and executable(wrapper) then
		return wrapper, goals
	elseif exists(wrapper) then
		return "sh", vim.list_extend({ wrapper }, goals)
	end
	return "gradle", goals
end

local function task_specs(root)
	local specs = {}
	local spring = is_spring_project(root)

	for _, tool in ipairs(build_tools(root)) do
		if tool == "maven" then
			vim.list_extend(specs, {
				{ label = "Maven compile", tool = tool, goals = { "compile" } },
				{ label = "Maven test", tool = tool, goals = { "test" } },
				{ label = "Maven package", tool = tool, goals = { "package" } },
				{ label = "Maven clean package", tool = tool, goals = { "clean", "package" } },
			})
			if spring then
				specs[#specs + 1] = { label = "Maven Spring Boot run", tool = tool, goals = { "spring-boot:run" } }
			end
		elseif tool == "gradle" then
			vim.list_extend(specs, {
				{ label = "Gradle classes", tool = tool, goals = { "classes" } },
				{ label = "Gradle test", tool = tool, goals = { "test" } },
				{ label = "Gradle build", tool = tool, goals = { "build" } },
				{ label = "Gradle clean build", tool = tool, goals = { "clean", "build" } },
			})
			if spring then
				specs[#specs + 1] = { label = "Gradle Boot run", tool = tool, goals = { "bootRun" } }
			end
		end
	end

	return specs
end

local function open_overseer()
	local ok, overseer = pcall(require, "overseer")
	if ok then
		pcall(overseer.open, { enter = false, direction = "bottom" })
	end
end

local function run_task(spec)
	local ok, overseer = pcall(require, "overseer")
	if not ok then
		notify("overseer.nvim is not loaded yet.", vim.log.levels.ERROR)
		return
	end

	local root = spec.root or project_root()
	local cmd, args = command_for(root, spec.tool, vim.deepcopy(spec.goals))
	local task = overseer.new_task({
		name = spec.label,
		cmd = cmd,
		args = args,
		cwd = root,
		env = runtime.env(root),
		components = { "default" },
	})

	task:start()
	open_overseer()
end

function M.build_picker()
	local root = project_root()
	local specs = task_specs(root)
	if vim.tbl_isempty(specs) then
		notify("No Maven or Gradle project found.", vim.log.levels.WARN)
		return
	end

	vim.ui.select(specs, {
		prompt = "Java build task",
		format_item = function(spec)
			return spec.label
		end,
	}, function(spec)
		if spec then
			spec.root = root
			run_task(spec)
		end
	end)
end

local function first_boot_task(root)
	if not is_spring_project(root) then
		return nil
	end

	for _, spec in ipairs(task_specs(root)) do
		if spec.label:find("Boot run", 1, true) or spec.label:find("Spring Boot run", 1, true) then
			spec.root = root
			return spec
		end
	end
end

local function fetch_main_configs(callback)
	local ok, jdtls_dap = pcall(require, "jdtls.dap")
	if not ok then
		notify("nvim-jdtls DAP support is not loaded. Open a Java file first.", vim.log.levels.ERROR)
		return
	end

	local root = project_root()
	local env = runtime.env(root)
	jdtls_dap.fetch_main_configs({
		config_overrides = {
			cwd = root,
			env = env,
			javaExec = java_executable(root),
		},
	}, function(configs)
		configs = configs or {}
		if vim.tbl_isempty(configs) then
			notify("No Java main class found.", vim.log.levels.WARN)
			return
		end

		vim.ui.select(configs, {
			prompt = "Java main class",
			format_item = function(config)
				return config.name or config.mainClass or "Java application"
			end,
		}, function(config)
			if config then
				callback(config, root, env)
			end
		end)
	end)
end

local function run_main(no_debug)
	fetch_main_configs(function(config, root, env)
		local ok, dap = pcall(require, "dap")
		if not ok then
			notify("nvim-dap is not loaded.", vim.log.levels.ERROR)
			return
		end

		config.cwd = config.cwd or root
		config.env = vim.tbl_extend("force", config.env or {}, env)
		config.noDebug = no_debug
		dap.run(config)
	end)
end

function M.run_app()
	local root = project_root()
	local boot = first_boot_task(root)
	if boot then
		run_task(boot)
		return
	end

	run_main(true)
end

function M.debug_app()
	run_main(false)
end

local function test_with_jdtls(method, debug)
	local ok, jdtls_dap = pcall(require, "jdtls.dap")
	if not ok then
		notify("nvim-jdtls DAP support is not loaded. Open a Java file first.", vim.log.levels.ERROR)
		return
	end

	local root = project_root()
	local overrides = {
		cwd = root,
		env = runtime.env(root),
		javaExec = java_executable(root),
		noDebug = not debug,
	}

	local fn = jdtls_dap[method]
	if not fn then
		notify("Installed nvim-jdtls does not expose " .. method .. ".", vim.log.levels.ERROR)
		return
	end

	fn({ config_overrides = overrides })
end

function M.run_test_nearest()
	test_with_jdtls("test_nearest_method", false)
end

function M.run_test_class()
	test_with_jdtls("test_class", false)
end

function M.debug_test_nearest()
	test_with_jdtls("test_nearest_method", true)
end

function M.organize_imports()
	local ok, jdtls = pcall(require, "jdtls")
	if ok and jdtls.organize_imports then
		jdtls.organize_imports()
		return
	end

	vim.lsp.buf.code_action({
		context = { only = { "source.organizeImports" } },
		apply = true,
	})
end

function M.generate()
	vim.lsp.buf.code_action({
		context = { only = { "source.generate" } },
		apply = false,
	})
end

function M.refresh_project()
	local ok, jdtls = pcall(require, "jdtls")
	if not ok then
		notify("nvim-jdtls is not loaded. Open a Java file first.", vim.log.levels.ERROR)
		return
	end

	if jdtls.update_project_config then
		jdtls.update_project_config()
		notify("Reloaded Maven/Gradle project metadata.")
	elseif jdtls.update_projects_config then
		jdtls.update_projects_config()
		notify("Reloaded Maven/Gradle project metadata.")
	else
		notify("Installed nvim-jdtls does not expose project refresh.", vim.log.levels.ERROR)
	end
end

function M.switch_runtime()
	runtime.switch_runtime(project_root())
end

function M.setup_commands()
	local commands = {
		JavaBuild = M.build_picker,
		JavaRun = M.run_app,
		JavaDebug = M.debug_app,
		JavaTestNearest = M.run_test_nearest,
		JavaTestClass = M.run_test_class,
		JavaDebugTestNearest = M.debug_test_nearest,
		JavaOrganizeImports = M.organize_imports,
		JavaGenerate = M.generate,
		JavaRefresh = M.refresh_project,
		JavaSwitchRuntime = M.switch_runtime,
	}

	for name, fn in pairs(commands) do
		vim.api.nvim_create_user_command(name, fn, { force = true })
	end
end

return M
