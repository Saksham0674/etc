-- tools.lua

-- Helper function for Oil
local function open_in_background(exit_oil)
  local oil = require("oil")
  local bufnr = vim.api.nvim_get_current_buf()
  local mode = vim.api.nvim_get_mode().mode
  local start_line, end_line

  if mode:sub(1, 1):lower() == "v" or mode == "\22" then
    start_line = vim.fn.line("v")
    end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  else
    start_line = vim.fn.line(".")
    end_line = start_line
  end

  local dir = oil.get_current_dir()
  if not dir then return end

  local count = 0
  local first_path = nil
  for lnum = start_line, end_line do
    local entry = oil.get_entry_on_line(bufnr, lnum)
    if entry and entry.type == "file" then
      local path = dir .. entry.name
      local f_buf = vim.fn.bufadd(path)
      vim.fn.bufload(f_buf)
      vim.bo[f_buf].buflisted = true
      if not first_path then
        first_path = path
      end
      count = count + 1
    end
  end
  
  if exit_oil and first_path then
    vim.cmd("edit " .. vim.fn.fnameescape(first_path))
  end

  if count > 0 then
    vim.notify(string.format(exit_oil and "Opened %d file(s)" or "Loaded %d file(s) in background", count))
  end
end

-- Helper functions for tmux
local function handoff(at_edge, window, pane)
  vim.system({
    "tmux", "if", "-F", "#{" .. at_edge .. "}",
    "select-window -t " .. window,
    "select-pane -" .. pane,
  })
end

local function in_float()
  return vim.api.nvim_win_get_config(0).relative ~= ""
end

local function nav(dir, at_edge, window, pane)
  return function()
    local from = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(dir)
    if vim.env.TMUX and from == vim.api.nvim_get_current_win() and not in_float() then
      handoff(at_edge, window, pane)
    end
  end
end

local map = vim.keymap.set
map("n", "<C-h>", nav("h", "pane_at_left", "-1", "L"), { desc = "Navigate left (nvim/tmux)" })
map("n", "<C-j>", nav("j", "pane_at_bottom", "+1", "D"), { desc = "Navigate down (nvim/tmux)" })
map("n", "<C-k>", nav("k", "pane_at_top", "-1", "U"), { desc = "Navigate up (nvim/tmux)" })
map("n", "<C-l>", nav("l", "pane_at_right", "+1", "R"), { desc = "Navigate right (nvim/tmux)" })


return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require("snacks").setup({
        picker = {
          ui_select = true,
          icons = { 
            prompt = "> ",
            ui = {
              selected = "●",
              unselected = " ",
            },
          },

          on_show = function(picker)
            picker.layout:maximize()
          end,
          layout = {
            layout = {
              backdrop = 100,
              width = 0.99,
              height = 0.99,
              border = "none",
              box = "horizontal",
              {
                box = "vertical",
                { win = "input", height = 1, border = { " ", " ", " ", " ", " ", " ", " ", " " }, title = " Find Files ", title_pos = "left" },
                { win = "list", border = { " ", " ", " ", " ", " ", " ", " ", " " }, title = " Results ", title_pos = "left" },
              },
              { win = "preview", border = { " ", " ", " ", " ", " ", " ", " ", " " }, title = " Grep Preview ", title_pos = "left", width = 0.6 },
            },
          },
          win = {
            input = {
              keys = {
                ["<Esc>"] = false,
                ["<C-c>"] = false,
                ["<a-.>"] = { "toggle_hidden", mode = { "i", "n" } },
              }
            },
            list = {
              wo = {
                signcolumn = "yes",
                statuscolumn = "%#SnacksPickerSelected#%{v:lnum == line('.') ? '>' : ' '}%*",
              }
            }
          },
          formatters = { 
            file = { filename_first = false },
            selected = {
              show_always = true,
              unselected = true,
            },
          },
        },
        scroll = { enabled = true },
        indent = {
          enabled = true,
          char = "│",
          animate = { enabled = true, style = "out" },
          scope = { enabled = true, char = "│" },
        },
      })

      local map = vim.keymap.set
      map("n", "<leader>f", function() Snacks.picker.files({ hidden = true, ignored = true }) end, { desc = "Find Files" })
      map("n", "<leader>g", function() Snacks.picker.grep({ hidden = true, ignored = true }) end, { desc = "Live Grep" })
      map("n", "<leader>sg", function() Snacks.picker.files({ hidden = true, ignored = true }) end, { desc = "Find All Files (incl. hidden/ignored)" })
      map("n", "<leader>bs", function() Snacks.picker.buffers() end, { desc = "Find Buffers (Snacks)" })
      map("n", "<leader>b", function()
        local qf_list = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].buflisted then
            local name = vim.api.nvim_buf_get_name(buf)
            if name == "" then name = "[No Name]" end
            table.insert(qf_list, { bufnr = buf, text = name })
          end
        end
        vim.fn.setqflist(qf_list, "r")
        vim.cmd("copen")
      end, { desc = "Buffer Quickfix Dump (copen)" })
      
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function(args)
          local opts = { buffer = args.buf, silent = true }
          vim.keymap.set("n", "<C-c>", "<cmd>cclose<cr>", opts)
          vim.keymap.set("n", "l", "<cr><cmd>cclose<cr>", opts)
          vim.keymap.set("n", "<CR>", "<cr><cmd>cclose<cr>", opts)
          
          local function open_split(cmd)
            return function()
              local qf_idx = vim.fn.line('.')
              local item = vim.fn.getqflist()[qf_idx]
              if item and item.bufnr > 0 then
                vim.cmd("cclose")
                vim.cmd(cmd)
                vim.cmd("buffer " .. item.bufnr)
              end
            end
          end
          
          vim.keymap.set("n", "v", open_split("split"), opts)
          vim.keymap.set("n", "s", open_split("vsplit"), opts)
        end,
      })
      
      map("n", "<leader>bu", "<cmd>only<cr>", { desc = "Un-split Window (Keeps buffers alive)" })
      map("n", "<leader>si", function() Snacks.picker.grep_word() end, { desc = "Grep Word under cursor" })
      map("n", "<leader>so", function() Snacks.picker.recent() end, { desc = "Recent / Old Files" })
      map("n", "<leader>sh", function() Snacks.picker.help() end, { desc = "Help Tags" })
      map("n", "<leader>sm", function() Snacks.picker.man() end, { desc = "Man Pages" })
      map("n", "<leader>sr", function() Snacks.picker.lsp_references() end, { desc = "LSP References" })
      map("n", "<leader>sd", function() Snacks.picker.diagnostics() end, { desc = "LSP Diagnostics" })
      map("n", "<leader>ss", function() Snacks.picker.lines() end, { desc = "Fuzzy Find Lines in Buffer" })
      map("n", "<leader>sS", function() Snacks.picker.lsp_symbols() end, { desc = "Document Symbols" })
      map("n", "<leader>sw", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "Workspace Symbols" })
      map("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Keymaps Search" })
      map("n", "<leader>st", function() _G.open_theme_picker() end, { desc = "Colorschemes Picker (Live Preview)" })
      map("n", "<leader>sq", function() Snacks.picker.qflist() end, { desc = "Quickfix List Picker" })
      map("n", "<leader>P", function() Snacks.picker.commands() end, { desc = "Command Palette" })
      map("n", "<leader>R", function() Snacks.picker.registers() end, { desc = "Registers Search" })
    end
  },

  {
    "echasnovski/mini.icons",
    config = function()
      require("mini.icons").setup()
      require("mini.icons").mock_nvim_web_devicons()
    end
  },

  {
    "stevearc/oil.nvim",
    config = function()
      require("oil").setup({
        columns = { "icon" },
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["<C-h>"] = false, ["<C-l>"] = false, ["<C-j>"] = false, ["<C-k>"] = false,
          ["g."] = "actions.toggle_hidden", ["gr"] = "actions.refresh",
        },
        float = { border = "rounded" },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "oil",
        callback = function()
          local opts = { buffer = true, silent = true }
          vim.keymap.set("v", "<CR>", function() open_in_background(true) end, vim.tbl_extend("force", opts, { desc = "Open selected and exit" }))
          vim.keymap.set("v", "<Tab>", function() open_in_background(false) end, vim.tbl_extend("force", opts, { desc = "Open selected in background" }))
          vim.keymap.set("n", "<Tab>", function() open_in_background(false) end, vim.tbl_extend("force", opts, { desc = "Open file in background" }))
        end,
      })

      vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open Oil File Explorer" })
      vim.keymap.set("n", "<leader>e", function()
        if vim.bo.filetype == "oil" then
          require("oil").close()
        else
          require("oil").open()
        end
      end, { desc = "Toggle Oil Explorer" })
    end
  },

  { "nvim-lua/plenary.nvim" },
  { "MunifTanjim/nui.nvim" },

  {
    "folke/todo-comments.nvim",
    config = function()
      require("todo-comments").setup({
        keywords = {
          BOT = {
            icon = "🤖",
            color = "#00FFD1",
          },
        }
      })
    end
  },

  {
    "folke/trouble.nvim",
    config = function()
      require("trouble").setup({})
      vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
      vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
      vim.keymap.set("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
      vim.keymap.set("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
      vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
      vim.keymap.set("n", "<leader>xr", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP Definitions / references (Trouble)" })
    end
  },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "┃" }, change = { text = "┃" }, delete = { text = "_" },
          topdelete = { text = "‾" }, changedelete = { text = "~" }, untracked = { text = "┆" },
        },
        current_line_blame = true,
        current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 500, ignore_whitespace = false },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          map("n", "]h", function()
            if vim.wo.diff then return "]h" end
            vim.schedule(function() gs.next_hunk() end)
            return "<Ignore>"
          end, { expr = true, desc = "Next Hunk" })
          map("n", "[h", function()
            if vim.wo.diff then return "[h" end
            vim.schedule(function() gs.prev_hunk() end)
            return "<Ignore>"
          end, { expr = true, desc = "Prev Hunk" })
          map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage Hunk" })
          map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset Hunk" })
          map("v", "<leader>hs", function() gs.stage_hunk {vim.fn.line("."), vim.fn.line("v")} end, { desc = "Stage Selected Hunk" })
          map("v", "<leader>hr", function() gs.reset_hunk {vim.fn.line("."), vim.fn.line("v")} end, { desc = "Reset Selected Hunk" })
          map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage Buffer" })
          map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo Stage Hunk" })
          map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset Buffer" })
          map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview Hunk" })
          map("n", "<leader>hb", function() gs.blame_line{full=true} end, { desc = "Blame Line" })
          map("n", "<leader>hd", gs.diffthis, { desc = "Diff This" })
          map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "Diff This (Base)" })
        end
      })
    end
  },

  { "sindrets/diffview.nvim" },

  {
    "hat0uma/csvview.nvim",
    config = function()
      require("csvview").setup({
        parser = { comments = { "#", "//" } },
        keymaps = {
          textobject_field_inner = { "if", mode = { "o", "x" } },
          textobject_field_outer = { "af", mode = { "o", "x" } },
          jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
          jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
          jump_next_row = { "<Enter>", mode = { "n", "v" } },
          jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
        },
      })

      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = vim.api.nvim_create_augroup("csvview_auto_enable", { clear = true }),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          local bt = vim.bo[args.buf].buftype
          if (ft == "csv" or ft == "tsv") and bt == "" then
            vim.schedule(function()
              local csvview = require("csvview")
              if vim.api.nvim_buf_is_valid(args.buf) and vim.fn.bufwinnr(args.buf) ~= -1 and not csvview.is_enabled(args.buf) then
                pcall(csvview.enable, args.buf)
              end
            end)
          end
        end,
      })
    end
  },

  {
    "HakonHarnes/img-clip.nvim",
    config = function()
      require("img-clip").setup({
        default = { dir_path = "assets" },
        filetypes = {
          markdown = { url_encode_path = true, template = "![$CURSOR]($FILE_PATH)" },
          typst = { template = "#figure(image(\"$FILE_PATH\"), caption: [$CURSOR])" },
        },
      })
    end
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    config = function()
      require("render-markdown").setup({
        file_types = { "markdown" },
        exclude_file_types = { "typst" },
        render_modes = true,
        code = { enabled = true, sign = false, style = "full", highlight = "RenderMarkdownCode" },
      })
    end
  },

  {
    "chomosuke/typst-preview.nvim",
    config = function()
      require("typst-preview").setup({
        dependencies_bin = { ["tinymist"] = "tinymist" },
        extra_args = {},
        get_root = function(path)
          local root = os.getenv("TYPST_ROOT")
          if root then return root end
          return vim.fn.fnamemodify(path, ":p:h")
        end,
      })
      
      -- Setup filetype hooks inside typst-preview config or as global autocmds
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "typst" },
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          local opts = { buffer = args.buf, silent = true }
          vim.keymap.set("n", "<leader>p", "<cmd>PasteImage<cr>", vim.tbl_extend("force", opts, { desc = "Paste image from clipboard" }))
          if ft == "typst" then
            vim.keymap.set("n", "<leader>tp", "<cmd>TypstPreview<cr>", vim.tbl_extend("force", opts, { desc = "Start Typst Live Preview" }))
            vim.keymap.set("n", "<leader>tc", "<cmd>TypstPreviewSyncCursor<cr>", vim.tbl_extend("force", opts, { desc = "Sync Typst preview cursor" }))
          end
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "undotree",
        callback = function(opts)
          vim.keymap.set("n", "j", "J", { buffer = opts.buf, remap = true, silent = true })
          vim.keymap.set("n", "k", "K", { buffer = opts.buf, remap = true, silent = true })
        end,
      })
    end
  }
}
