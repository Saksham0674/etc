-- ui.lua
-- Theme (Everforest + Pinned Theme Picker), Lualine, Dropbar, Which-Key

return {
  {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.g.everforest_background = "medium"
      vim.g.everforest_transparent_background = 2
      vim.g.everforest_better_performance = 1
      vim.g.everforest_enable_italic = 1

      local default_theme = "everforest"
      local pin_file = vim.fs.joinpath(vim.fn.stdpath("data"), "theme-pins.json")

      local function read_pins()
        local f = io.open(pin_file, "r")
        if not f then return { default_theme } end
        local ok, data = pcall(vim.json.decode, f:read("*a") or "")
        f:close()
        if ok and type(data) == "table" and data[1] then return data end
        return { default_theme }
      end

      local function write_pins(pins)
        local f = io.open(pin_file, "w")
        if f then
          f:write(vim.json.encode(pins))
          f:close()
        end
      end

      local pins = read_pins()
      pcall(vim.cmd.colorscheme, pins[1])

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.api.nvim_set_hl(0, "RenderMarkdownCode", { link = "CursorLine" })
          vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { link = "ColorColumn" })
          
          local groups = { "TroubleNormal", "TroubleNormalNC", "NvimTreeNormal", "NvimTreeNormalNC" }
          for _, group in ipairs(groups) do
            vim.api.nvim_set_hl(0, group, { link = "Normal" })
          end
        end,
      })
      vim.api.nvim_exec_autocmds("ColorScheme", {})

      local function open_theme_picker()
        local snacks = require("snacks")
        local all_colors = vim.fn.getcompletion("", "color")

        local pinned_map = {}
        for _, p in ipairs(pins) do pinned_map[p] = true end

        local items = {}
        for _, p in ipairs(pins) do
          table.insert(items, { text = p, formatted = "📌 " .. p, is_pinned = true })
        end
        for _, c in ipairs(all_colors) do
          if not pinned_map[c] then
            table.insert(items, { text = c, formatted = "   " .. c, is_pinned = false })
          end
        end

        local initial_scheme = vim.g.colors_name or default_theme
        local confirmed = false

        snacks.picker({
          title = "Select Theme ( Pinned first | <C-p> toggle pin)",
          items = items,
          layout = {
            preset = "select",
            layout = {
              box = "vertical",
              backdrop = false,
              width = 0.38,
              height = 0.50,
              row = 2,
              col = -2,
              border = "rounded",
            },
          },
          format = function(item)
            return { { item.formatted, item.is_pinned and "DiagnosticWarn" or "Normal" } }
          end,
          on_change = function(picker, item)
            if item and item.text then
              pcall(vim.cmd.colorscheme, item.text)
            end
          end,
          confirm = function(picker, item)
            confirmed = true
            picker:close()
            if item and item.text then
              pcall(vim.cmd.colorscheme, item.text)
              vim.notify("Colorscheme set to " .. item.text, vim.log.levels.INFO)
            end
          end,
          on_close = function()
            if not confirmed then
              pcall(vim.cmd.colorscheme, initial_scheme)
            end
          end,
          win = {
            input = {
              keys = { ["<C-p>"] = { "toggle_pin", desc = "Toggle Pin Theme", mode = { "n", "i" } } },
            },
          },
          actions = {
            toggle_pin = function(picker, item)
              if not item or not item.text then return end
              local theme = item.text
              if vim.tbl_contains(pins, theme) then
                pins = vim.tbl_filter(function(n) return n ~= theme end, pins)
                if not pins[1] then pins = { default_theme } end
                vim.notify(theme .. " unpinned")
              else
                table.insert(pins, theme)
                vim.notify(theme .. " pinned")
              end
              write_pins(pins)
              picker:close()
              vim.schedule(open_theme_picker)
            end,
          },
        })
      end

      _G.open_theme_picker = open_theme_picker
      vim.api.nvim_create_user_command("Theme", open_theme_picker, { desc = "Select colorscheme with live preview (pinned first)" })
      vim.api.nvim_create_user_command("ThemePin", function()
        local cur = vim.g.colors_name
        if not cur then return end
        if vim.tbl_contains(pins, cur) then
          pins = vim.tbl_filter(function(n) return n ~= cur end, pins)
          if not pins[1] then pins = { default_theme } end
          vim.notify(cur .. " unpinned")
        else
          pins[#pins + 1] = cur
          vim.notify(cur .. " pinned")
        end
        write_pins(pins)
      end, { desc = "Pin or unpin the current active theme" })
    end
  },
  
  { "yardnsm/nvim-base46" },

  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local function env_component()
        local v = vim.env.VIRTUAL_ENV or vim.env.CONDA_DEFAULT_ENV
        return v and ("󰌠 env: " .. vim.fn.fnamemodify(v, ":t")) or ""
      end

      local function lsp_component()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then return "" end
        local names = {}
        for _, c in ipairs(clients) do table.insert(names, c.name) end
        return "󰒋 lsp: " .. table.concat(names, ", ")
      end

      local function fmt_component()
        local ok, conform = pcall(require, "conform")
        if not ok then return "" end
        local fmts = conform.list_formatters(0)
        if #fmts == 0 then return "" end
        local names = {}
        for _, f in ipairs(fmts) do table.insert(names, f.name) end
        return "󰉼 fmt: " .. table.concat(names, ", ")
      end

      local function lint_component()
        local ok, l = pcall(require, "lint")
        if not ok then return "" end
        local linters = l.linters_by_ft[vim.bo.filetype] or {}
        if #linters == 0 then return "" end
        return "󰍉 lint: " .. table.concat(linters, ", ")
      end

      require("lualine").setup({
        options = {
          theme = "everforest",
          globalstatus = true,
          icons_enabled = true,
          component_separators = { left = "│", right = "│" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
        },
        sections = {
          lualine_a = {},
          lualine_b = {
            { "branch", icon = "󰘬" },
            { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
            { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
          },
          lualine_c = {
            { "filename", file_status = true, newfile_status = true, path = 1, symbols = { modified = " [+]", readonly = " [RO]", unnamed = "[No Name]" } },
          },
          lualine_x = { env_component, lsp_component, fmt_component, lint_component },
          lualine_y = { "filetype" },
          lualine_z = { "mode" },
        },
      })
    end
  },

  {
    "Bekaboo/dropbar.nvim",
    config = function()
      require("dropbar").setup({
        bar = {
          sources = function(buf, win)
            local sources = require("dropbar.sources")
            return { sources.path, sources.markdown, sources.lsp }
          end,
        },
        sources = {
          path = {
            relative_to = function(buf, win)
              local bufname = vim.api.nvim_buf_get_name(buf)
              if bufname == "" then return vim.fn.getcwd() end
              local git_root = vim.fs.root(bufname, ".git")
              if git_root then return git_root end
              return vim.fs.dirname(bufname)
            end,
          },
        },
      })
    end
  },

  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").setup({
        preset = "classic",
        delay = 400,
        icons = { breadcrumb = "»", separator = "➜", group = "+" },
        spec = {
          { "<leader>b", group = "buffers" },
          { "<leader>f", group = "files/find" },
          { "<leader>s", group = "search/symbols" },
          { "<leader>g", group = "grep/git" },
          { "<leader>h", group = "hunks" },
          { "<leader>x", group = "trouble/diagnostics" },
          { "<leader>r", group = "surround/refactor" },
          { "<leader>c", group = "code/format" },
          { "<leader>t", group = "theme/typst/toggles" },
        }
      })
    end
  },

  {
    "NvChad/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end
  },

  {
    "akinsho/bufferline.nvim",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          separator_style = "thin",
          always_show_bufferline = true,
          show_buffer_close_icons = false,
          show_close_icon = false,
          color_icons = true,
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              highlight = "Directory",
              separator = true,
            }
          }
        }
      })

      vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
      vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
      vim.keymap.set("n", "<leader>bd", function() require("snacks").bufdelete() end, { desc = "Close Buffer (Safely)" })
      vim.keymap.set("n", "<leader>tb", function()
        vim.o.showtabline = vim.o.showtabline == 0 and 2 or 0
      end, { desc = "Toggle Bufferline" })
    end
  }
}
