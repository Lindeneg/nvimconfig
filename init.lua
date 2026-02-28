-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- ============================================================================
-- Utility functions
-- ============================================================================
OS_NAME = { WINDOWS = "Windows", UNIX = "Unix/Linux", UNKNOWN = "Unknown" }
function GetOS()
	local sep = package.config:sub(1, 1)
	if sep == "/" then
		return OS_NAME.UNIX
	elseif sep == "\\" then
		return OS_NAME.WINDOWS
	else
		return OS_NAME.UNKNOWN
	end
end

local function file_exists(name)
	local f = io.open(name, "r")
	if f then
		io.close(f)
		return true
	end
	return false
end

-- ============================================================================
-- Options
-- ============================================================================
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.swapfile = false
vim.o.backup = false
vim.o.undodir = vim.fn.expand("~/.vim/undodir")
vim.o.undofile = true
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.termguicolors = true
vim.o.wrap = false
vim.o.scrolloff = 8
vim.o.updatetime = 50
vim.o.mouse = "a"
vim.o.showmode = false
vim.o.breakindent = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split"
vim.o.cursorline = false
vim.o.confirm = true

vim.g.netrw_list_hide = "\\.obj$"
vim.g.ftplugin_sql_omni_key = "ø"

-- ============================================================================
-- Autocommand
-- ============================================================================
local base_path_map = {
	[OS_NAME.WINDOWS] = "D:/dev/",
	[OS_NAME.UNIX] = "/Users/cl/dev",
}
local base_path = base_path_map[GetOS()]

vim.api.nvim_create_autocmd("BufNewFile", {
	pattern = "*.h",
	callback = function()
		if base_path == nil then
			return
		end
		local name = vim.api.nvim_buf_get_name(0):gsub("\\", "/")
		name = name:gsub(base_path, "")
		name = name:gsub("src/", "")
		name = name:gsub("/", "_"):gsub("-", "_"):gsub("%.h", "_h_"):upper()
		vim.api.nvim_buf_set_lines(0, 0, 4, false, {
			string.format("#ifndef %s", name),
			string.format("#define %s", name),
			"",
			string.format("#endif // %s", name),
		})
	end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.{vs,fs}",
	callback = function()
		vim.bo.filetype = "glsl"
	end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.{env*}",
	callback = function()
		vim.bo.filetype = "sh"
	end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- ============================================================================
-- Custom Commands
-- ============================================================================
local COMMENT_MODE = "c"
local comment_map = {
	c = "//",
	cpp = "//",
	h = "//",
	hpp = "//",
	go = "//",
	lua = "--",
	rust = "//",
	python = "#",
	sh = "#",
	js = "//",
	javascript = "//",
	ts = "//",
	typescript = "//",
	typescriptreact = "//",
	gdscript = "#",
	cmake = "#",
}
vim.api.nvim_create_user_command("Comment", function(opts)
	local comment_token = comment_map[vim.bo.filetype]
	if not comment_token then
		return
	end
	local is_comment_mode = opts.args == COMMENT_MODE
	local selected_lines = vim.fn.getline("'<", "'>")
	local new_lines = {}
	for _, line in ipairs(selected_lines) do
		local first_words = line:match("%S%S?")
		if is_comment_mode then
			table.insert(new_lines, comment_token .. line)
		elseif first_words == comment_token then
			table.insert(new_lines, line:gsub(first_words, "", 1))
		else
			table.insert(new_lines, line)
		end
	end
	vim.api.nvim_buf_set_lines(0, vim.fn.line("'<") - 1, vim.fn.line("'>"), false, new_lines)
end, { nargs = 1, range = true })

local os_map = {
	[OS_NAME.WINDOWS] = { build = ".\\misc\\build.bat", run = ".\\misc\\run.bat" },
	[OS_NAME.UNIX] = { build = "make", run = "cmake ." },
}
local os_cmds = os_map[GetOS()]
local RUN_MODE = "r"
local build_map = {
	go = "make build",
	typescript = "yarn build",
	javascript = "yarn build",
	cs = "dotnet build",
	rust = "cargo check",
}
local run_map = {
	go = "make run",
	rust = "cargo run",
	typescript = "yarn start",
	javascript = "yarn start",
	cs = "dotnet run",
}
vim.api.nvim_create_user_command("Compile", function(opts)
	local is_run_mode = opts.args == RUN_MODE
	local ft = vim.bo.filetype
	local cmd = is_run_mode and run_map[ft] or build_map[ft]
	if not cmd then
		if is_run_mode and file_exists(os_cmds.run) then
			cmd = os_cmds.run
		elseif not is_run_mode and file_exists(os_cmds.build) then
			cmd = os_cmds.build
		else
			return
		end
	end
	vim.cmd("below split")
	vim.cmd("term")
	vim.fn.feedkeys("a")
	local enter = vim.api.nvim_replace_termcodes("<CR>", true, true, true)
	vim.fn.feedkeys("cls" .. enter)
	vim.fn.feedkeys(cmd .. enter)
end, { nargs = 1 })

local fmt_map = {
	rust = "rustfmt",
	c = "clang-format",
	cpp = "clang-format",
	h = "clang-format",
	hpp = "clang-format",
	typescript = "prettier",
	typescriptreact = "prettier",
	javascript = "prettier",
	vue = "prettier",
	html = "prettier",
	css = "prettier",
	json = "prettier",
	lua = "stylua",
	go = "gofmt",
}

vim.api.nvim_create_user_command("GenericFormat", function()
	if vim.bo.filetype == "go" then
		vim.cmd("GoImports")
		vim.cmd("GoFmt")
		return
	end
	local formatter = fmt_map[vim.bo.filetype]
	if formatter then
		require("conform").format({ formatters = { formatter } })
	else
		vim.cmd([[%s/\s\+$//e]]) -- remove trailing whitespace
	end
end, { nargs = 0 })

vim.api.nvim_create_user_command("GoFmt", function()
	require("conform").format({ formatters = { "gofmt" } })
end, {})
vim.api.nvim_create_user_command("GoImports", function()
	require("conform").format({ formatters = { "goimports" } })
end, {})
vim.api.nvim_create_user_command("ClangFormat", function()
	require("conform").format({ formatters = { "clang-format" } })
end, {})
vim.api.nvim_create_user_command("Rustfmt", function()
	require("conform").format({ formatters = { "rustfmt" } })
end, {})
vim.api.nvim_create_user_command("Prettier", function()
	require("conform").format({ formatters = { "prettier" } })
end, {})

-- ============================================================================
-- Keymaps
-- ============================================================================
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<leader>pv", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "<leader>7", ":Comment c<CR>", opts)
map("v", "<leader>8", ":Comment u<CR>", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)
map("n", "J", "mzJ`z", opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "<leader>,", ":Compile d<CR>", opts)
map("n", "<leader>.", ":Compile r<CR>", opts)
map("n", "<leader>m", ":GenericFormat<CR>", opts)
map("t", "<leader>'", [[<C-\><C-n>]], opts)
map("n", "<leader>'", ":noh<CR>", opts)
map("n", "<F2>", function()
	vim.opt.foldenable = not vim.opt.foldenable._value
	vim.opt.foldmethod = "indent"
end, opts)

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle undotree" })

map("n", "<leader>pf", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<C-p>", "<cmd>Telescope git_files<CR>", { desc = "Git files" })
map("n", "<leader>ps", function()
	require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep string" })

-- ============================================================================
-- Lazy Plugin Manager
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- Plugin Specifications
-- ============================================================================
require("lazy").setup({
	{ "folke/neoconf.nvim", cmd = "Neoconf" },
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},

	{
		"Lindeneg/gruvbox",
		priority = 1000,
		config = function()
			vim.g.gruvbox_contrast_dark = "hard"
			vim.g.gruvbox_number_column = "bg0"
			vim.g.gruvbox_sign_column = "bg0"
			vim.cmd.colorscheme("gruvbox")

			local green = vim.api.nvim_get_hl(0, { name = "GruvboxGreen" }).fg
			local yellow = vim.api.nvim_get_hl(0, { name = "GruvboxYellow" }).fg
			local default_fg = vim.api.nvim_get_hl(0, { name = "GruvboxFg1" }).fg
			local aqua = vim.api.nvim_get_hl(0, { name = "GruvboxAqua" }).fg
			local orange = vim.api.nvim_get_hl(0, { name = "GruvboxOrange" }).fg
			local purple = vim.api.nvim_get_hl(0, { name = "GruvboxPurple" }).fg
			local gray = vim.api.nvim_get_hl(0, { name = "GruvboxGray" }).fg
			local string_color = "#20a017"
			local red = "#fb4934"

			local hl = vim.api.nvim_set_hl

			-- defaults
			hl(0, "Include", { fg = red })
			hl(0, "PreProc", { fg = red })
			hl(0, "StorageClass", { fg = red })
			hl(0, "Identifier", { fg = default_fg })
			hl(0, "@lsp.type.property", { link = "@variable" })
			hl(0, "String", { fg = string_color })
			hl(0, "@lsp.type.member", { fg = green })

			-- cpp
			hl(0, "cppStructure", { fg = red })

			-- typescript
			hl(0, "typeScriptFuncKeyword", { fg = red })
			hl(0, "typescriptKeywordOp", { fg = red })
			hl(0, "typescriptOperator", { fg = red })
			hl(0, "typescriptTypeReference", { fg = red })
			hl(0, "typescriptImport", { fg = red })
			hl(0, "typescriptExceptions", { fg = red })
			hl(0, "typescriptModule", { fg = red })
			hl(0, "typescriptImportType", { fg = red })
			hl(0, "typescriptTypeBracket", { fg = red })
			hl(0, "typescriptTry", { fg = red })
			hl(0, "typescriptExport", { fg = red })
			hl(0, "typescriptAmbientDeclaration", { fg = red })
			hl(0, "typescriptGlobal", { fg = default_fg })
			hl(0, "typescriptIdentifierName", { fg = default_fg })
			hl(0, "typescriptInterfaceName", { fg = default_fg })
			hl(0, "typescriptFuncCallArg", { link = "@variable" })
			hl(0, "typescriptFileReaderProp", { link = "@variable" })
			hl(0, "typescriptMember", { link = "@variable" })
			hl(0, "typescriptCastKeyword", { fg = red })
			hl(0, "typescriptPredefinedType", { fg = yellow })
			hl(0, "typescriptProp", { link = "@variable" })
			hl(0, "typescriptBlock", { link = "@variable" })
			hl(0, "typescriptConditionalParen", { link = "@variable" })
			hl(0, "typescriptXHRProp", { link = "@variable" })
			hl(0, "typescriptResponseProp", { link = "@variable" })
			vim.cmd("hi! typescriptObjectType guifg=" .. default_fg)
			vim.cmd("hi! typescriptTypeArguments guifg=" .. red)
			vim.cmd("hi! typescriptIdentifierName guifg=" .. red)
			vim.cmd("hi! typescriptVariable guifg=" .. red)
			vim.cmd("hi! javascriptVariable guifg=" .. red)

			-- javascript
			hl(0, "javaScriptFunction", { fg = red })
			hl(0, "javaScript", { fg = default_fg })

			-- html/vue
			hl(0, "@lsp.type.component.vue", { link = "@variable" })

			-- Tag names — red to match keyword style
			hl(0, "@tag", { fg = red })
			hl(0, "@tag.builtin", { fg = red })
			hl(0, "htmlTagName", { fg = purple })
			hl(0, "htmlSpecialTagName", { fg = purple })
			hl(0, "htmlTag", { fg = gray })
			hl(0, "htmlEndTag", { fg = gray })

			-- Attributes — orange, distinct from tags
			hl(0, "@tag.attribute", { fg = gray })
			hl(0, "htmlArg", { fg = gray })

			-- Tag delimiters (< > </ />) — muted gray
			hl(0, "@tag.delimiter", { fg = gray })

			-- Attribute values — string green (already covered by String)
			-- = sign — gray
			hl(0, "htmlString", { fg = string_color })

			-- Special chars (&amp; etc) — purple
			hl(0, "htmlSpecialChar", { fg = purple })
			hl(0, "@character.special", { fg = purple })

			-- Script/style tags — purple
			hl(0, "htmlScriptTag", { fg = purple })

			-- Vue-specific
			hl(0, "@punctuation.special", { fg = orange }) -- {{ }} interpolation
			hl(0, "@function.method", { fg = green }) -- @click handlers
			hl(0, "@variable.member", { fg = aqua }) -- :prop bindings
			hl(0, "@directive_name", { fg = red })

			-- css
			hl(0, "cssClassName", { fg = green })
			hl(0, "cssClassNameDot", { fg = green })
			hl(0, "cssIdentifier", { fg = green })
			hl(0, "cssGridProp", { fg = aqua })
			hl(0, "cssMediaProp", { fg = aqua })
			hl(0, "cssDefinition", { fg = aqua })
			hl(0, "cssTextProp", { fg = aqua })
			hl(0, "cssAnimationProp", { fg = aqua })
			hl(0, "cssUIProp", { fg = aqua })
			hl(0, "cssTransformProp", { fg = aqua })
			hl(0, "cssTransitionProp", { fg = aqua })
			hl(0, "cssPrintProp", { fg = aqua })
			hl(0, "cssBorderProp", { fg = aqua })
			hl(0, "cssPositioningProp", { fg = aqua })
			hl(0, "cssBoxProp", { fg = aqua })
			hl(0, "cssFontDescriptorProp", { fg = aqua })
			hl(0, "cssFlexibleBoxProp", { fg = aqua })
			hl(0, "cssBorderOutlineProp", { fg = aqua })
			hl(0, "cssBackgroundProp", { fg = aqua })
			hl(0, "cssMarginProp", { fg = aqua })
			hl(0, "cssListProp", { fg = aqua })
			hl(0, "cssTableProp", { fg = aqua })
			hl(0, "cssFontProp", { fg = aqua })
			hl(0, "cssPaddingProp", { fg = aqua })
			hl(0, "cssDimensionProp", { fg = aqua })
			hl(0, "cssRenderProp", { fg = aqua })
			hl(0, "cssColorProp", { fg = aqua })
			hl(0, "cssGeneratedContentProp", { fg = aqua })
			hl(0, "cssFunctionName", { fg = green })
			hl(0, "cssColor", { fg = purple })
			hl(0, "cssImportant", { fg = red })
			hl(0, "cssBraces", { fg = gray })
			hl(0, "cssSelectorOp", { fg = gray })
			hl(0, "cssSelectorOp2", { fg = gray })
			hl(0, "@property.css", { fg = aqua })

			-- yaml
			hl(0, "yamlBlockMappingKey", { link = "@variable" })
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		version = false,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
            vim.api.nvim_create_autocmd('FileType', {
              pattern = { 'prisma' },
              callback = function() vim.treesitter.start() end,
            })

			require("nvim-treesitter").setup({
				highlight = {
					enable = true,
					disable = function(lang, bufnr)
						return vim.api.nvim_buf_line_count(bufnr) > 50000 and (lang == "cpp" or lang == "c")
					end,
					additional_vim_regex_highlighting = false,
				},
			})
			require("nvim-treesitter").install({
				"c",
				"javascript",
				"typescript",
				"vue",
				"bash",
				"cmake",
				"yaml",
				"c_sharp",
				"cpp",
				"go",
				"html",
				"css",
				"json",
				"python",
				"tsx",
				"lua",
				"vim",
				"vimdoc",
				"query",
				"gdscript",
				"prisma",
			})
		end,
	},

	"mbbill/undotree",

	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	"HiPhish/rainbow-delimiters.nvim",

	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1
			local function my_on_attach(bufnr)
				local api = require("nvim-tree.api")
				local function opts(desc)
					return { desc = desc, buffer = bufnr, noremap = true, silent = true }
				end
				api.config.mappings.default_on_attach(bufnr)
				vim.keymap.set("n", "%", api.fs.create, opts("Create"))
				vim.keymap.set("n", "d", api.fs.create, opts("Create directory (use /)"))
				vim.keymap.set("n", "D", api.fs.remove, opts("Delete"))
				vim.keymap.set("n", "R", api.fs.rename_full, opts("Move / rename (full path)"))
				vim.keymap.set("n", "C", api.tree.collapse_all, opts("Collapse all folders"))
			end
			require("nvim-tree").setup({
				sort = { sorter = "case_sensitive" },
				view = { width = 30 },
				renderer = {
					group_empty = true,
					icons = { show = { file = true, folder = true, folder_arrow = true, git = true } },
				},
				filters = { dotfiles = false },
				git = { ignore = false },
				filesystem_watchers = {
					ignore_dirs = {
						"node_modules",
						".cache",
						"generated",
						".next",
						"cmake-*",
						".vs",
						".idea",
						".claude",
						".next",
					},
				},
				update_focused_file = { enable = true, update_root = false },
				on_attach = my_on_attach,
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason-org/mason.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"Hoffs/omnisharp-extended-lsp.nvim", -- for omnisharp handlers
			"saghen/blink.cmp", -- completion engine
		},
		config = function()
			require("mason").setup()
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- Mason package names
					"omnisharp",
					"lua-language-server",
					"python-lsp-server",
					"typescript-language-server",
					"vue-language-server",
					"html-lsp",
					"css-lsp",
					"cmake-language-server",
					"clangd",
					"gopls",
					-- Formatters (for conform)
					"stylua",
					"goimports",
					"clang-format",
					"prettier",
				},
			})

			local capabilities = require("blink.cmp").get_lsp_capabilities()

			local function goto_first_definition()
				local params = vim.lsp.util.make_position_params(0, "utf-8")
				vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
					if err then
						vim.notify("LSP definition error: " .. err.message, vim.log.levels.ERROR)
						return
					end
					if not result or vim.tbl_isempty(result) then
						vim.notify("No definition found", vim.log.levels.INFO)
						return
					end
					local loc = result[1] or result
					vim.lsp.util.show_document(loc, "utf-8", { focus = true })
				end)
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("custom-lsp-attach", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					local bufnr = event.buf

					vim.keymap.set(
						"n",
						"gd",
						goto_first_definition,
						{ buffer = bufnr, desc = "LSP: Goto first definition" }
					)
					vim.keymap.set(
						"n",
						"gD",
						vim.lsp.buf.definition,
						{ buffer = bufnr, desc = "LSP: Goto all definitions" }
					)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP: Hover" })
					vim.keymap.set("n", "<leader>vd", function()
						vim.diagnostic.open_float()
					end, { buffer = bufnr, desc = "LSP: Open diagnostic float" })
					vim.keymap.set(
						"n",
						"<leader>vca",
						vim.lsp.buf.code_action,
						{ buffer = bufnr, desc = "LSP: Code action" }
					)
				end,
			})

			vim.lsp.config["clangd"] = {
				cmd = {
					"clangd",
					"--offset-encoding=utf-16",
					"--query-driver=C:\\Users\\chris\\mingw64\\bin\\g++*,C:\\Users\\chris\\mingw64\\bin\\c++*",
				},
				capabilities = capabilities,
			}

			vim.lsp.config["omnisharp"] = {
				cmd = { "dotnet", "D:\\omnisharp\\OmniSharp.dll" },
				capabilities = capabilities,
				handlers = {
					["textDocument/definition"] = require("omnisharp_extended").definition_handler,
					["textDocument/typeDefinition"] = require("omnisharp_extended").type_definition_handler,
					["textDocument/references"] = require("omnisharp_extended").references_handler,
					["textDocument/implementation"] = require("omnisharp_extended").implementation_handler,
				},
				settings = {
					FormattingOptions = { EnableEditorConfigSupport = true, OrganizeImports = nil },
					MsBuild = { LoadProjectsOnDemand = nil },
					RoslynExtensionsOptions = {
						EnableAnalyzersSupport = nil,
						EnableImportCompletion = nil,
						AnalyzeOpenDocumentsOnly = nil,
					},
					Sdk = { IncludePrereleases = true },
				},
			}

			local vue_language_server_path = vim.fn.stdpath("data")
				.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

			local tsserver_filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }
			local vue_plugin = {
				name = "@vue/typescript-plugin",
				location = vue_language_server_path,
				languages = { "vue" },
				configNamespace = "typescript",
			}
			local ts_ls_config = {
				init_options = {
					plugins = {
						vue_plugin,
					},
				},
				filetypes = tsserver_filetypes,
			}

			local vue_ls_config = {}

			vim.lsp.config("vue_ls", vue_ls_config)
			vim.lsp.config("ts_ls", ts_ls_config)

			vim.lsp.enable({
				"ts_ls",
				"vue_ls",
				"lua_ls",
				"omnisharp",
				"clangd",
				"pylsp",
				"html",
				"cssls",
				"cmake",
				"gopls",
			})
		end,
	},

	{
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				version = "2.*",
				build = (function()
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
			},
		},
		opts = {
			keymap = { preset = "enter" },
			appearance = { nerd_font_variant = "mono" },
			completion = { documentation = { auto_show = false } },
			sources = { default = { "lsp", "path", "snippets" } },
			snippets = { preset = "luasnip" },
			fuzzy = { implementation = "lua" },
			signature = { enabled = true },
		},
	},

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>m",
				function()
					vim.cmd("GenericFormat")
				end,
				desc = "[M]y format",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = nil,
			formatters = {
				prettier = {
					command = "prettier",
					args = {
						"--stdin-filepath",
						"$FILENAME",
						"--arrow-parens",
						"always",
						"--bracket-spacing",
						"false",
						"--bracket-same-line",
						"true",
						"--embedded-language-formatting",
						"auto",
						"--end-of-line",
						"lf",
						"--html-whitespace-sensitivity",
						"css",
						"--print-width",
						"100",
						"--semi",
						"true",
						"--single-quote",
						"false",
						"--tab-width",
						"4",
						"--trailing-comma",
						"es5",
					},
					stdin = true,
				},
			},
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "goimports", "gofmt" },
				rust = { "rustfmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				vue = { "prettier" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				json = { "prettier" },
			},
		},
	},
	"nvim-tree/nvim-web-devicons",
}, {
	ui = {
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})
