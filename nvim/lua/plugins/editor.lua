-- editor.lua

return {
  { "Saghen/blink.lib" },
  { "rafamadriz/friendly-snippets" },
  
  {
    "folke/lazydev.nvim",
    ft = "lua",
    config = function()
      require("lazydev").setup({
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      })
    end
  },

  { 
    "Saghen/blink.cmp",
    build = "cargo build --release",
    config = function()
      local blink = require("blink.cmp")
      if type(blink.library_available) == "function" and not blink.library_available() then
        pcall(function() blink.build():pwait() end)
      end

      blink.setup({
        keymap = { preset = "super-tab" },
        fuzzy = { implementation = "prefer_rust_with_warning" },
        completion = {
          menu = { border = "rounded" },
          documentation = { window = { border = "rounded" } },
        },
        cmdline = {
          enabled = true,
          sources = { default = { "path", "cmdline" } },
        },
        sources = {
          default = { "lazydev", "lsp", "path", "snippets", "buffer", "cmdline" },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
              fallbacks = { "lsp" },
            },
          },
        },
        snippets = { preset = "default" },
      })
      
      -- Advertise capabilities globally for LSP to pick up
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function()
          pcall(function()
            vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
          end)
        end,
      })
    end
  },

  {
    "stevearc/conform.nvim",
    config = function()
      local conform = require("conform")
      conform.setup({
        formatters_by_ft = {
          python = { "ruff_format" },
          lua = { "stylua" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          toml = { "taplo" },
          rust = { "rustfmt" },
          c = { "clang-format" },
          cpp = { "clang-format" },
        },
      })

      vim.keymap.set({ "n", "v" }, "<leader>lf", function()
        conform.format({ lsp_fallback = true, async = true })
      end, { desc = "Format current buffer or selection" })
    end
  },

  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python = { "ruff" },
        bash = { "shellcheck" },
        javascript = { "eslint" },
        typescript = { "eslint" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("linter_auto_check", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
      local default_langs = {
        "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
        "typst", "rust", "typescript", "javascript", "tsx", "c", "cpp",
        "go", "bash", "yaml", "toml", "json", "python"
      }
      
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<CR>",
            node_incremental = "<CR>",
            scope_incremental = false,
            node_decremental = "<BS>",
          },
        },
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          local ok, config = pcall(require, "nvim-treesitter.config")
          local ok_install, install = pcall(require, "nvim-treesitter.install")
          if ok and ok_install then
            local missing = config.norm_languages(default_langs, { installed = true })
            if #missing > 0 then
              install.install(missing, {})
            end
          end
        end
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter_main_auto_start", { clear = true }),
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end
  },
  
  {
    "nvim-treesitter/nvim-treesitter-context",
    config = function()
      require("treesitter-context").setup({
        enable = true, max_lines = 3, min_window_height = 0,
        line_numbers = true, multiline_threshold = 20,
        trim_scope = "outer", mode = "cursor",
      })
    end
  },

  { "williamboman/mason.nvim", config = function() require("mason").setup() end },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright", "ruff", "lua_ls", "rust_analyzer", "clangd",
          "ts_ls", "gopls", "bashls", "yamlls", "taplo", "jsonls", "tinymist"
        }
      })
    end
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim", "Saghen/blink.cmp" },
    config = function()
      local Severity = vim.diagnostic.severity
      vim.diagnostic.config({
        underline = false, virtual_text = true, virtual_lines = false, update_in_insert = false,
        float = { border = "rounded", focus = false, scope = "cursor" },
        jump = { on_jump = vim.diagnostic.open_float },
        signs = {
          numhl = {
            [Severity.ERROR] = "DiagnosticSignError", [Severity.HINT] = "DiagnosticSignHint",
            [Severity.INFO] = "DiagnosticSignInfo", [Severity.WARN] = "DiagnosticSignWarn",
          },
          text = {
            [Severity.ERROR] = "", [Severity.HINT] = "",
            [Severity.INFO] = "", [Severity.WARN] = "",
          },
        },
      })

      vim.lsp.config("lua_ls", {
        cmd = { 'lua-language-server' }, filetypes = { 'lua' },
        root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
        settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } },
      })
      vim.lsp.enable("lua_ls")

      vim.lsp.config("pyright", { settings = { python = { analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true, diagnosticMode = "workspace" } } } })
      vim.lsp.enable("pyright")

      local simple_servers = { "ruff", "rust_analyzer", "clangd", "ts_ls", "gopls", "bashls", "yamlls", "taplo", "jsonls" }
      for _, s in ipairs(simple_servers) do
        vim.lsp.config(s, {})
        vim.lsp.enable(s)
      end

      local function create_tinymist_command(command_name, client, bufnr)
        local cmd_display = command_name:match('tinymist%.export(%w+)')
        local function run_tinymist_command()
          local arguments = { vim.api.nvim_buf_get_name(bufnr) }
          return client:exec_cmd({ title = "Export " .. cmd_display, command = command_name, arguments = arguments }, { bufnr = bufnr })
        end
        return run_tinymist_command, ('Export' .. cmd_display), ('Export to ' .. cmd_display)
      end

      vim.lsp.config("tinymist", {
        cmd = { 'tinymist' }, filetypes = { 'typst' }, root_markers = { '.git' },
        settings = { exportPdf = "onSave", formatterMode = "typstyle" },
        on_attach = function(client, bufnr)
          for _, command in ipairs({ 'tinymist.exportSvg', 'tinymist.exportPng', 'tinymist.exportPdf', 'tinymist.exportHtml', 'tinymist.exportMarkdown' }) do
            local cmd_func, cmd_name, cmd_desc = create_tinymist_command(command, client, bufnr)
            vim.api.nvim_buf_create_user_command(bufnr, cmd_name, cmd_func, { nargs = 0, desc = cmd_desc })
          end
        end,
      })
      vim.lsp.enable("tinymist")

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP: Hover Info" }))
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "LSP: Goto Definition" }))
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "LSP: Goto Declaration" }))
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "LSP: Goto Implementation" }))
          vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "LSP: Goto Type Definition" }))
          vim.keymap.set("i", "<M-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "LSP: Signature Help" }))
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "LSP: Code Action" }))
          vim.keymap.set("n", "<leader>sa", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "LSP: Code Action (Alt)" }))
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "LSP: Rename Symbol" }))
          vim.keymap.set("n", "<leader>sn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "LSP: Rename Symbol (Alt)" }))
          vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, vim.tbl_extend("force", opts, { desc = "LSP: Format file" }))
        end,
      })
    end
  },

  {
    "dnlhc/glance.nvim",
    config = function()
      local glance = require("glance")
      glance.setup({
        height = 18, border = { enable = true, top_char = '―', bottom_char = '―' },
        mappings = {
          list = {
            ['j'] = glance.actions.next, ['k'] = glance.actions.previous,
            ['<Down>'] = glance.actions.next, ['<Up>'] = glance.actions.previous,
            ['<Tab>'] = glance.actions.next_location, ['<S-Tab>'] = glance.actions.previous_location,
            ['<CR>'] = glance.actions.jump, ['v'] = glance.actions.jump_vsplit,
            ['s'] = glance.actions.jump_split, ['t'] = glance.actions.jump_tab,
            ['<Esc>'] = glance.actions.close, ['q'] = glance.actions.close,
          },
        },
      })
      local map = vim.keymap.set
      map("n", "<M-F12>", "<cmd>Glance definitions<cr>", { desc = "LSP Peek Definition (VSCode Option+F12)" })
      map("n", "gpd", "<cmd>Glance definitions<cr>", { desc = "LSP Peek Definition" })
      map("n", "gpr", "<cmd>Glance references<cr>", { desc = "LSP Peek References" })
      map("n", "gpy", "<cmd>Glance type_definitions<cr>", { desc = "LSP Peek Type Definition" })
      map("n", "gpi", "<cmd>Glance implementations<cr>", { desc = "LSP Peek Implementation" })
    end
  },

  { "lewis6991/async.nvim" },


  {
    "windwp/nvim-autopairs",
    config = function() require("nvim-autopairs").setup({ check_ts = true }) end
  },

  {
    "kylechui/nvim-surround",
    config = function()
      require("nvim-surround").setup()
      vim.keymap.set("x", "<leader>r", "<Plug>(nvim-surround-visual)", { desc = "Surround selection" })
      vim.keymap.set("x", "<leader>R", "<Plug>(nvim-surround-visual-line)", { desc = "Surround selection (line)" })
    end
  },

  { "nvim-treesitter/nvim-treesitter-textobjects" },
  {
    "echasnovski/mini.ai",
    config = function()
      local ai = require("mini.ai")
      ai.setup({
        n_lines = 500,
        custom_textobjects = {
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          o = ai.gen_spec.treesitter({ a = { "@conditional.outer", "@loop.outer", "@block.outer" }, i = { "@conditional.inner", "@loop.inner", "@block.inner" } }),
        },
      })
    end
  },

  {
    "mbbill/undotree",
    config = function()
      vim.g.undotree_CustomUndotreeCmd = "leftabove 30 vnew"
      vim.g.undotree_CustomDiffpanelCmd = "belowright 10 new"
      vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Toggle Undo Tree" })
    end
  },



  {
    "folke/flash.nvim",
    config = function()
      require("flash").setup({ modes = { char = { enabled = false } } })
      vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash Jump" })
      vim.keymap.set({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
    end
  }
}
