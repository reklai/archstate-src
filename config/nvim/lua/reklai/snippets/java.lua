local M = {}

local function filename_class_name()
	local name = vim.fn.expand("%:t:r")
	return name ~= "" and name or "ClassName"
end

function M.setup()
	local ok, ls = pcall(require, "luasnip")
	if not ok then
		return
	end

	local s = ls.snippet
	local t = ls.text_node
	local i = ls.insert_node
	local f = ls.function_node

	ls.add_snippets("java", {
		s("jclass", {
			t("public class "),
			f(filename_class_name),
			t({ " {", "\t" }),
			i(1),
			t({ "", "}" }),
		}),
		s("jinterface", {
			t("public interface "),
			f(filename_class_name),
			t({ " {", "\t" }),
			i(1),
			t({ "", "}" }),
		}),
		s("jenum", {
			t("public enum "),
			f(filename_class_name),
			t({ " {", "\t" }),
			i(1, "VALUE"),
			t({ "", "}" }),
		}),
		s("jrecord", {
			t("public record "),
			f(filename_class_name),
			t("("),
			i(1),
			t({ ") {", "\t" }),
			i(2),
			t({ "", "}" }),
		}),
		s("psvm", {
			t({ "public static void main(String[] args) {", "\t" }),
			i(1),
			t({ "", "}" }),
		}),
		s("jtest", {
			t({ "import org.junit.jupiter.api.Test;", "", "class " }),
			f(filename_class_name),
			t({ " {", "\t@Test", "\tvoid " }),
			i(1, "shouldDoSomething"),
			t({ "() {", "\t\t" }),
			i(2),
			t({ "", "\t}", "}" }),
		}),
		s("jcontroller", {
			t({
				"import org.springframework.web.bind.annotation.RequestMapping;",
				"import org.springframework.web.bind.annotation.RestController;",
				"",
				"@RestController",
				'@RequestMapping("',
			}),
			i(1, "/api"),
			t({ '")', "public class " }),
			f(filename_class_name),
			t({ " {", "\t" }),
			i(2),
			t({ "", "}" }),
		}),
		s("jservice", {
			t({ "import org.springframework.stereotype.Service;", "", "@Service", "public class " }),
			f(filename_class_name),
			t({ " {", "\t" }),
			i(1),
			t({ "", "}" }),
		}),
		s("jrepo", {
			t({
				"import org.springframework.data.jpa.repository.JpaRepository;",
				"import org.springframework.stereotype.Repository;",
				"",
				"@Repository",
				"public interface ",
			}),
			f(filename_class_name),
			t(" extends JpaRepository<"),
			i(1, "Entity"),
			t(", "),
			i(2, "Long"),
			t({ "> {", "\t" }),
			i(3),
			t({ "", "}" }),
		}),
	}, { key = "reklai-java" })
end

return M
