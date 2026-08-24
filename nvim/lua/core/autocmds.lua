-- autocmds.lua — event-driven autocommands.

local group = vim.api.nvim_create_augroup("user_autocmds", { clear = true })

-- Automatically check for changes on disk when Neovim gains focus (works across Tmux panes)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = group,
  desc = "Reload files changed outside Neovim",
  callback = function()
    if vim.o.buftype == "" and vim.fn.mode() == "n" then
      vim.cmd("checktime")
    end
  end,
})

-- Notify when a file has been reloaded from disk changes
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  desc = "Notify on external file reload",
  callback = function()
    vim.notify("File changed on disk — reloaded.", vim.log.levels.INFO)
  end,
})

-- Briefly highlight yanked text on copy
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.highlight.on_yank({ hlgroup = "IncSearch", timeout = 150 })
  end,
})

-- Quickfix List Live Auto-Preview on Cursor Move (buffers only)
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "qf",
  callback = function(args)
    -- Sessions qflist (title="Sessions" in sessions.lua:195) has text-only items
    -- with no file to preview - skip .cc preview for it.
    local qf_title = vim.fn.getqflist({ title = 1 }).title
    if qf_title == "Sessions" then return end
    vim.api.nvim_create_autocmd("CursorMoved", {
      buffer = args.buf,
      callback = function()
        local qf_win = vim.api.nvim_get_current_win()
        local ok = pcall(vim.cmd, ".cc")
        if ok and vim.api.nvim_win_is_valid(qf_win) then
          vim.api.nvim_set_current_win(qf_win)
        end
      end,
    })
  end,
})

