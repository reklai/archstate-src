local runtime = require("reklai.java.runtime")

local M = {}

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

local function glob(pattern)
	local matches = vim.fn.glob(pattern, true, true)
	return type(matches) == "table" and matches or {}
end

local function mason_path(...)
	return vim.fn.stdpath("data") .. "/mason/" .. table.concat({ ... }, "/")
end

local function package_path(package, ...)
	return mason_path("packages", package, ...)
end

local function bundle_jars()
	local bundles = {}

	vim.list_extend(
		bundles,
		glob(package_path("java-debug-adapter", "extension/server/com.microsoft.java.debug.plugin-*.jar"))
	)
	for _, jar in ipairs(glob(package_path("java-test", "extension/server/*.jar"))) do
		local filename = vim.fn.fnamemodify(jar, ":t")
		if filename ~= "com.microsoft.java.test.runner-jar-with-dependencies.jar" and filename ~= "jacocoagent.jar" then
			bundles[#bundles + 1] = jar
		end
	end
	vim.list_extend(bundles, glob(package_path("vscode-spring-boot-tools", "extension/jars/*.jar")))
	vim.list_extend(bundles, glob(mason_path("share", "vscode-spring-boot-tools/jdtls/*.jar")))

	return bundles
end

local function workspace_dir(root)
	local name = vim.fs.basename(root)
	local hash = vim.fn.sha256(root):sub(1, 12)
	return vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. name .. "-" .. hash
end

local function jdtls_cmd(root)
	local jdtls_bin = mason_path("bin", "jdtls")
	if vim.fn.executable(jdtls_bin) ~= 1 then
		jdtls_bin = "jdtls"
	end
	local jdtls_runtime = runtime.default_jdtls_runtime()
	local java_executable = jdtls_runtime and (jdtls_runtime.path .. "/bin/java") or "java"

	local cmd = {
		jdtls_bin,
		"--java-executable",
		java_executable,
		"-data",
		workspace_dir(root),
	}

	local lombok = package_path("jdtls", "lombok.jar")
	if vim.uv.fs_stat(lombok) then
		table.insert(cmd, 2, "--jvm-arg=-javaagent:" .. lombok)
	end

	return cmd
end

local function capabilities()
	local ok, blink = pcall(require, "blink.cmp")
	if ok then
		return blink.get_lsp_capabilities()
	end
	return vim.lsp.protocol.make_client_capabilities()
end

local function settings(root)
	return {
		java = {
			autobuild = { enabled = true },
			completion = {
				importOrder = { "java", "javax", "jakarta", "org", "com" },
				favoriteStaticMembers = {
					"org.junit.jupiter.api.Assertions.*",
					"org.mockito.Mockito.*",
					"org.assertj.core.api.Assertions.*",
				},
			},
			configuration = {
				runtimes = runtime.jdtls_runtimes(root),
				updateBuildConfiguration = "interactive",
			},
			contentProvider = { preferred = "fernflower" },
			eclipse = { downloadSources = true },
			implementationsCodeLens = { enabled = true },
			import = {
				gradle = {
					enabled = true,
					wrapper = { enabled = true },
				},
				maven = { enabled = true },
			},
			inlayHints = {
				parameterNames = { enabled = "all" },
			},
			maven = { downloadSources = true },
			references = { includeDecompiledSources = true },
			saveActions = { organizeImports = false },
			signatureHelp = { enabled = true },
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
		},
	}
end

function M.start(bufnr)
	bufnr = bufnr or 0
	local root = vim.fs.root(bufnr, root_markers)
	if not root then
		vim.notify("JDTLS needs a Maven, Gradle, or git project root.", vim.log.levels.WARN, { title = "Java" })
		return
	end

	local ok, jdtls = pcall(require, "jdtls")
	if not ok then
		vim.notify("nvim-jdtls is not installed yet.", vim.log.levels.ERROR, { title = "Java" })
		return
	end

	local extended_capabilities = vim.deepcopy(jdtls.extendedClientCapabilities or {})
	extended_capabilities.resolveAdditionalTextEditsSupport = true

	jdtls.start_or_attach({
		cmd = jdtls_cmd(root),
		root_dir = root,
		capabilities = capabilities(),
		settings = settings(root),
		init_options = {
			bundles = bundle_jars(),
			extendedClientCapabilities = extended_capabilities,
		},
		on_attach = function(_, attach_bufnr)
			local ok_dap, jdtls_dap = pcall(require, "jdtls.dap")
			if ok_dap then
				jdtls_dap.setup_dap({ hotcodereplace = "auto" })
				pcall(jdtls_dap.setup_dap_main_class_configs)
			end

			local ok_setup, jdtls_setup = pcall(require, "jdtls.setup")
			if ok_setup then
				pcall(jdtls_setup.add_commands)
			end

			vim.b[attach_bufnr].java_project_root = root
		end,
	})
end

return M
