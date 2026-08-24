-- sessions.lua — named manual snapshots of layout + buffers (:h mksession).
-- You curate windows/buffers, save under a name, reload it verbatim later.
-- No autosave, no cwd coupling, no rules about what gets included.

vim.opt.sessionoptions = { "blank", "buffers", "curdir", "folds", "tabpages", "winsize", "winpos" }

local M = {}

local uv = vim.uv
local DIR = vim.fn.stdpath("data") .. "/sessions"

-- --- Helpers ---------------------------------------------------------------

local function ensure_dir()
  vim.fn.mkdir(DIR, "p")
end

local function path_for(name)
  return DIR .. "/" .. name .. ".vim"
end

local function sanitize(name)
  name = vim.trim(name or "")
  if name == "" then return nil end
  name = name:gsub("[%/\\]", "-")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  -- block traversal / hidden / empty after sanitizing
  if name == "" or name:match("^%.+$") then return nil end
  if name:match("^%-+$") then return nil end
  -- limit length to keep filesystem happy
  if #name > 120 then name = name:sub(1, 120) end
  return name
end

local function reltime(sec)
  local d = os.time() - sec
  if d < 60 then return "just now" end
  if d < 3600 then return string.format("%dm ago", math.floor(d / 60)) end
  if d < 86400 then return string.format("%dh ago", math.floor(d / 3600)) end
  if d < 7 * 86400 then return string.format("%dd ago", math.floor(d / 86400)) end
  return os.date("%Y-%m-%d", sec)
end

-- Count badd lines in a session file = number of restored buffers
local function bufcount(path)
  local ok, lines = pcall(io.lines, path)
  if not ok or not lines then return 0 end
  local n = 0
  local ok_iter = true
  for line in lines do
    if line:match("^badd%s") then n = n + 1 end
  end
  return n
end

-- Extract saved filenames from a session file (for picker previews)
local function session_files(path)
  local files = {}
  local ok, lines = pcall(io.lines, path)
  if not ok or not lines then return { "(no saved buffers)" } end
  for line in lines do
    local f = line:match("^badd%s+[-+]?%d*%s*(.+)$")
    if f then
      f = f:gsub("\\ ", " ")
      table.insert(files, f)
    end
  end
  if #files == 0 then files[1] = "(no saved buffers)" end
  return files
end

function M.list()
  ensure_dir()
  local out = {}
  local ok_dir, iter = pcall(vim.fs.dir, DIR)
  if not ok_dir or not iter then return out end
  for name, t in iter do
    local path = DIR .. "/" .. name
    if t == "file" and name:sub(-4) == ".vim" then
      local st = uv.fs_stat(path)
      if st and st.mtime then
        table.insert(out, {
          name = name:sub(1, -5),
          path = path,
          mtime = st.mtime.sec,
        })
      end
    end
  end
  table.sort(out, function(a, b) return a.mtime > b.mtime end)
  return out
end

-- --- Core ------------------------------------------------------------------

function M.save(name)
  ensure_dir()
  if not name or name == "" then
    vim.ui.input({ prompt = "Session name: " }, function(input)
      if input and input ~= "" then M.save(input) end
    end)
    return
  end

  local sanitized = sanitize(name)
  if not sanitized then
    vim.notify("Invalid session name: " .. name, vim.log.levels.ERROR)
    return
  end
  name = sanitized
  local path = path_for(name)
  if vim.fn.filereadable(path) == 1 then
    local answer = vim.fn.confirm(string.format("Overwrite session '%s'?", name), "&Yes\n&No", 2)
    if answer ~= 1 then return end
  end

  vim.cmd("mksession! " .. vim.fn.fnameescape(path))
  vim.notify(string.format("Session '%s' saved (%d buffers)", name, bufcount(path)))
end

-- Wipe current state quietly, then source the session file.
-- Modified buffers trigger the normal save-confirm prompt (opt.confirm = true).
function M.load_path(path)
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("No such session file: " .. path, vim.log.levels.ERROR)
    return
  end
  vim.cmd("silent! tabonly")
  vim.cmd("silent! only")
  -- Use :%bdelete without silent! so opt.confirm can prompt on modified buffers
  local ok, err = pcall(vim.cmd, "%bdelete")
  if not ok then
    -- E89 or confirm abort: don't source session, keep current state
    vim.notify("Load cancelled: " .. tostring(err), vim.log.levels.WARN)
    return
  end
  vim.cmd("source " .. vim.fn.fnameescape(path))
  vim.v.this_session = path
end

function M.load(name)
  if name and name ~= "" then
    local sanitized = sanitize(name)
    if not sanitized then
      vim.notify("Invalid session name: " .. name, vim.log.levels.ERROR)
      return
    end
    M.load_path(path_for(sanitized))
    return
  end
  local sessions = M.list()
  if #sessions == 0 then
    vim.notify("No saved sessions", vim.log.levels.WARN)
    return
  end
  vim.ui.select(sessions, {
    prompt = "Load session:",
    format_item = function(s) return string.format("%s (%s)", s.name, reltime(s.mtime)) end,
  }, function(s)
    if s then M.load_path(s.path) end
  end)
end

function M.delete(name)
  if not name or name == "" then
    vim.ui.input({ prompt = "Delete session: " }, function(input)
      if input and input ~= "" then M.delete(input) end
    end)
    return
  end

  local sanitized = sanitize(name)
  if not sanitized then
    vim.notify("Invalid session name: " .. name, vim.log.levels.ERROR)
    return
  end
  local path = path_for(sanitized)
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("No such session: " .. name, vim.log.levels.ERROR)
    return
  end
  local answer = vim.fn.confirm(string.format("Delete session '%s'?", sanitized), "&Yes\n&No", 2)
  if answer == 1 then
    local ok, err = os.remove(path)
    if ok then
      vim.notify("Session '" .. sanitized .. "' deleted")
    else
      vim.notify("Delete failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

-- --- Frontend 1: quickfix --------------------------------------------------

local QF_TITLE = "Sessions"

function M.qf()
  -- Uses default qflist infrastructure (setqflist + copen) but text-only.
  -- No filename/bufnr so qf shows just "name · N buffers · time" with no
  -- file column and no jump target - s/v/.cc have nothing to open.
  local sessions = M.list()
  local items = {}
  for _, s in ipairs(sessions) do
    table.insert(items, {
      text = string.format("%s · %d buffers · %s", s.name, bufcount(s.path), reltime(s.mtime)),
    })
  end
  vim.fn.setqflist({}, " ", { title = QF_TITLE, items = items })
  vim.cmd("copen")

  local bufnr = vim.api.nvim_get_current_buf()

  local function load_under_cursor()
    local s = sessions[vim.fn.line(".")]
    if not s then return end
    vim.cmd("cclose")
    M.load_path(s.path)
  end

  local opts = { buffer = bufnr, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>", load_under_cursor,
    vim.tbl_extend("force", opts, { desc = "Load session" }))
  vim.keymap.set("n", "l", load_under_cursor,
    vim.tbl_extend("force", opts, { desc = "Load session" }))
  vim.keymap.set("n", "d", function()
    local s = sessions[vim.fn.line(".")]
    if not s then return end
    local answer = vim.fn.confirm("Delete session '" .. s.name .. "'?", "&Yes\n&No", 2)
    if answer ~= 1 then return end
    local ok, err = os.remove(s.path)
    if not ok then
      vim.notify("Delete failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    -- Refresh the list in place; keeps the qf window open
    sessions = M.list()
    local refreshed = {}
    for _, s2 in ipairs(sessions) do
      table.insert(refreshed, {
        text = string.format("%s · %d buffers · %s", s2.name, bufcount(s2.path), reltime(s2.mtime)),
      })
    end
    vim.fn.setqflist({}, " ", { title = QF_TITLE, items = refreshed })
  end, vim.tbl_extend("force", opts, { desc = "Delete session" }))
end

-- --- Frontend 2: snacks picker ---------------------------------------------

function M.pick()
  local ok, Snacks = pcall(require, "snacks")
  if not ok then
    M.load() -- fall back to vim.ui.select
    return
  end

  local items = {}
  for _, s in ipairs(M.list()) do
    s.text = s.name
    table.insert(items, s)
  end
  if #items == 0 then
    vim.notify("No saved sessions", vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = "Sessions",
    items = items,
    preview = function(ctx)
      ctx.preview:set_lines(session_files(ctx.item.path))
    end,
    confirm = function(picker, item)
      picker:close()
      vim.schedule(function() M.load_path(item.path) end)
    end,
  })
end

-- --- Commands & Keymaps ----------------------------------------------------

vim.api.nvim_create_user_command("SessionSave", function(c) M.save(c.args) end,
  { nargs = "?", desc = "Save current setup as a named session" })
vim.api.nvim_create_user_command("SessionLoad", function(c) M.load(c.args) end,
  { nargs = "?", desc = "Load a named session" })
vim.api.nvim_create_user_command("SessionsDelete", function(c) M.delete(c.args) end,
  { nargs = "?", desc = "Delete a named session" })
vim.api.nvim_create_user_command("Sessions", function() M.qf() end,
  { desc = "Browse sessions in quickfix" })

local map = vim.keymap.set
map("n", "<leader>S", "<cmd>Sessions<cr>", { desc = "Sessions (quickfix)" })
map("n", "<leader>Ss", "<cmd>SessionSave<cr>", { desc = "Save session" })
map("n", "<leader>Sl", function() M.pick() end, { desc = "Load session (picker)" })
map("n", "<leader>Sd", "<cmd>SessionsDelete<cr>", { desc = "Delete session" })

return M
