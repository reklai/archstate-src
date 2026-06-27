local M = {}

local state_path = vim.fn.stdpath("data") .. "/reklai-java-runtimes.json"

local root_markers = {
	"pom.xml",
	"mvnw",
	"build.gradle",
	"build.gradle.kts",
	"gradlew",
	"settings.gradle",
	"settings.gradle.kts",
	".git",
}

local runtime_name_by_major = {
	[8] = "JavaSE-1.8",
	[9] = "JavaSE-9",
	[10] = "JavaSE-10",
	[11] = "JavaSE-11",
	[12] = "JavaSE-12",
	[13] = "JavaSE-13",
	[14] = "JavaSE-14",
	[15] = "JavaSE-15",
	[16] = "JavaSE-16",
	[17] = "JavaSE-17",
	[18] = "JavaSE-18",
	[19] = "JavaSE-19",
	[20] = "JavaSE-20",
	[21] = "JavaSE-21",
	[22] = "JavaSE-22",
	[23] = "JavaSE-23",
	[24] = "JavaSE-24",
	[25] = "JavaSE-25",
}

local function path_join(...)
	return table.concat(vim.iter({ ... }):flatten():totable(), "/")
end

local function exists(path)
	return path and path ~= "" and vim.uv.fs_stat(path) ~= nil
end

local function is_executable(path)
	return path and vim.fn.executable(path) == 1
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

local function normalize_home(path)
	if not path or path == "" then
		return nil
	end
	if path:sub(1, 1) == "~" then
		return vim.fn.expand(path)
	end
	return path
end

local function parse_major(value)
	if not value or value == "" then
		return nil
	end

	value = tostring(value)
	local major = value:match("1%.([8])") or value:match("(%d+)")
	return major and tonumber(major) or nil
end

local function runtime_name(major)
	return runtime_name_by_major[major] or ("JavaSE-" .. tostring(major))
end

local function runtime_from_path(path)
	path = normalize_home(path)
	if not path then
		return nil
	end
	path = vim.uv.fs_realpath(path) or path

	local java = path_join(path, "bin", "java")
	local release = path_join(path, "release")
	if not is_executable(java) or not exists(release) then
		return nil
	end

	local release_text = read_file(release) or ""
	local version = release_text:match('JAVA_VERSION="([^"]+)"')
	local implementor = release_text:match('IMPLEMENTOR="([^"]+)"')
	local major = parse_major(version or path)
	if not major then
		return nil
	end

	return {
		name = runtime_name(major),
		path = vim.fs.normalize(path),
		major = major,
		version = version or tostring(major),
		label = string.format("Java %s - %s", version or major, vim.fs.basename(path)),
		implementor = implementor,
	}
end

local function scan_dir(parent, runtimes)
	parent = normalize_home(parent)
	if not parent or not exists(parent) then
		return
	end

	local handle = vim.uv.fs_scandir(parent)
	if not handle then
		return
	end

	while true do
		local name, type = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if type == "directory" or type == "link" then
			local runtime = runtime_from_path(path_join(parent, name))
			if runtime then
				runtimes[runtime.path] = runtime
			end
		end
	end
end

local function load_state()
	local data = read_file(state_path)
	if not data or data == "" then
		return {}
	end

	local ok, decoded = pcall(vim.json.decode, data)
	if not ok or type(decoded) ~= "table" then
		return {}
	end
	return decoded
end

local function save_state(state)
	vim.fn.mkdir(vim.fn.fnamemodify(state_path, ":h"), "p")
	vim.fn.writefile({ vim.json.encode(state) }, state_path)
end

function M.project_root(bufnr)
	bufnr = bufnr or 0
	return vim.fs.root(bufnr, root_markers) or vim.uv.cwd()
end

function M.scan_runtimes()
	local runtimes_by_path = {}

	scan_dir("/usr/lib/jvm", runtimes_by_path)
	scan_dir("~/.jdks", runtimes_by_path)
	scan_dir("~/.sdkman/candidates/java", runtimes_by_path)
	scan_dir("~/.asdf/installs/java", runtimes_by_path)
	scan_dir("~/.local/share/mise/installs/java", runtimes_by_path)

	if vim.env.JAVA_HOME then
		local runtime = runtime_from_path(vim.env.JAVA_HOME)
		if runtime then
			runtimes_by_path[runtime.path] = runtime
		end
	end

	local runtimes = vim.tbl_values(runtimes_by_path)
	table.sort(runtimes, function(a, b)
		if a.major == b.major then
			return a.path < b.path
		end
		return a.major < b.major
	end)

	return runtimes
end

local function first_line(path)
	local text = read_file(path)
	if not text then
		return nil
	end
	return vim.trim((text:match("([^\r\n]+)") or ""))
end

local function version_from_file(root, filename)
	local line = first_line(path_join(root, filename))
	return parse_major(line)
end

local function version_from_sdkman(root)
	local text = read_file(path_join(root, ".sdkmanrc"))
	return parse_major(text and text:match("java%s*=%s*([^\r\n]+)"))
end

local function version_from_tool_versions(root)
	local text = read_file(path_join(root, ".tool-versions"))
	return parse_major(text and text:match("[\r\n]?java%s+([^\r\n]+)"))
end

local function version_from_mise(root)
	local text = read_file(path_join(root, ".mise.toml"))
	return parse_major(text and text:match('java%s*=%s*"?([^"\r\n%]]+)'))
end

local function version_from_gradle(root)
	local candidates = {
		path_join(root, "build.gradle"),
		path_join(root, "build.gradle.kts"),
		path_join(root, "gradle.properties"),
	}

	for _, path in ipairs(candidates) do
		local text = read_file(path)
		if text then
			local major = parse_major(
				text:match("JavaLanguageVersion%.of%((%d+)%)")
					or text:match("VERSION_1_([8])")
					or text:match("VERSION_(%d+)")
					or text:match("sourceCompatibility%s*=%s*['\"]?([^'\"\r\n]+)")
					or text:match("targetCompatibility%s*=%s*['\"]?([^'\"\r\n]+)")
					or text:match("org%.gradle%.java%.home%s*=%s*([^\r\n]+)")
			)
			if major then
				return major
			end
		end
	end
end

local function version_from_maven(root)
	local text = read_file(path_join(root, "pom.xml"))
	if not text then
		return nil
	end

	return parse_major(
		text:match("<maven%.compiler%.release>(.-)</maven%.compiler%.release>")
			or text:match("<maven%.compiler%.source>(.-)</maven%.compiler%.source>")
			or text:match("<maven%.compiler%.target>(.-)</maven%.compiler%.target>")
			or text:match("<release>(.-)</release>")
			or text:match("<source>(.-)</source>")
			or text:match("<target>(.-)</target>")
	)
end

function M.detect_project_major(root)
	root = root or M.project_root()
	return version_from_file(root, ".java-version")
		or version_from_sdkman(root)
		or version_from_tool_versions(root)
		or version_from_mise(root)
		or version_from_gradle(root)
		or version_from_maven(root)
end

local function runtime_by_path(path)
	if not path then
		return nil
	end
	path = vim.fs.normalize(path)
	for _, runtime in ipairs(M.scan_runtimes()) do
		if runtime.path == path then
			return runtime
		end
	end
end

function M.default_jdtls_runtime()
	local best
	for _, runtime in ipairs(M.scan_runtimes()) do
		if runtime.major >= 21 and (not best or runtime.major < best.major) then
			best = runtime
		end
	end
	return best
end

function M.project_runtime(root)
	root = root or M.project_root()
	local state = load_state()
	local selected = runtime_by_path(state[root])
	if selected then
		return selected
	end

	local major = M.detect_project_major(root)
	if major then
		for _, runtime in ipairs(M.scan_runtimes()) do
			if runtime.major == major then
				return runtime
			end
		end
	end

	if vim.env.JAVA_HOME then
		local runtime = runtime_by_path(vim.env.JAVA_HOME)
		if runtime then
			return runtime
		end
	end

	return M.default_jdtls_runtime() or M.scan_runtimes()[1]
end

function M.jdtls_runtimes(root)
	root = root or M.project_root()
	local selected = M.project_runtime(root)

	return vim.tbl_map(function(runtime)
		return {
			name = runtime.name,
			path = runtime.path,
			default = selected and selected.path == runtime.path or nil,
		}
	end, M.scan_runtimes())
end

function M.env(root)
	local runtime = M.project_runtime(root)
	if not runtime then
		return {}
	end

	return {
		JAVA_HOME = runtime.path,
		PATH = runtime.path .. "/bin:" .. vim.env.PATH,
	}
end

function M.switch_runtime(root)
	root = root or M.project_root()
	local runtimes = M.scan_runtimes()
	if vim.tbl_isempty(runtimes) then
		vim.notify(
			"No JDKs found. Install one under /usr/lib/jvm, ~/.jdks, sdkman, asdf, or mise.",
			vim.log.levels.WARN
		)
		return
	end

	vim.ui.select(runtimes, {
		prompt = "Choose Java version for this project",
		format_item = function(runtime)
			local suffix = runtime.path
			if runtime.implementor then
				suffix = runtime.implementor .. " - " .. suffix
			end
			return string.format("%s (%s)", runtime.label, suffix)
		end,
	}, function(runtime)
		if not runtime then
			return
		end

		local state = load_state()
		state[root] = runtime.path
		save_state(state)

		local ok, jdtls = pcall(require, "jdtls")
		if ok then
			pcall(jdtls.set_runtime, runtime.name)
			pcall(jdtls.update_project_config)
		end

		vim.notify(string.format("Java runtime for this project: %s", runtime.label))
	end)
end

return M
