-- keymaps.lua — general editor key mappings

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Clear search highlight
map("n", "<leader>0", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Exit insert & terminal modes quickly
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Files & Buffers Management
map("n", "<leader>w", "<cmd>update<cr>", { desc = "Write buffer if modified" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit current window" })
map("n", "<leader>Q", "<cmd>wqa<cr>", { desc = "Write all buffers and quit" })
map("n", "<leader>r", "<cmd>edit!<cr>", { desc = "Reload current file from disk" })

map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader><leader>", "<C-^>", { desc = "Alternate buffer" })
map("n", "<leader>a", "<C-^>", { desc = "Alternate buffer" })

-- Split Window Management (pure Neovim splits)
map("n", "<C-w>h", "<cmd>aboveleft vsplit<cr>", { desc = "Split left" })
map("n", "<C-w>j", "<cmd>belowright split<cr>", { desc = "Split below" })
map("n", "<C-w>k", "<cmd>aboveleft split<cr>", { desc = "Split above" })
map("n", "<C-w>l", "<cmd>belowright vsplit<cr>", { desc = "Split right" })

-- Quick Window & Buffer Navigation Helpers
map("n", "gl", "$", { desc = "Jump to end of line" })
map("n", "gh", "^", { desc = "Jump to start of line text" })
map("n", "yag", ":%y<CR>", vim.tbl_extend("force", opts, { desc = "Yank entire buffer" }))
map("n", "vag", "ggVG", vim.tbl_extend("force", opts, { desc = "Select entire buffer" }))

-- Clipboard Yank
map({ "n", "v", "x" }, "<leader>y", '"+y', { desc = "Yank selection to system clipboard" })
map({ "n", "v", "x" }, "<C-y>", '"+y', { desc = "Yank selection to system clipboard" })

-- Centered scrolling & search navigation
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
map("n", "n", "nzzzv", { desc = "Next match (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous match (centered)" })

-- Visual Mode Indentation & Line Movement
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)
map("x", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("x", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Paste over visual selection without losing clipboard register
map("x", "p", '"_dP', { desc = "Paste without yanking selection" })

-- Execute last macro over visual selection
map("x", ".", function()
  return "<esc><cmd>'<,'>normal! " .. vim.v.count1 .. ".<cr>"
end, { expr = true, replace_keycodes = true, desc = "Execute macro over visual selection" })

-- Helper Utilities
map("n", "<leader>c", "1z=", { desc = "Spelling correction under cursor" })
map("n", "<C-q>", "<cmd>copen<cr>", { desc = "Open quickfix window" })
map("n", "<C-f>", "<cmd>silent !open .<cr>", { desc = "Open Finder in current directory" })

-- Insert Mode Helpers
map("i", "<C-h>", "<Left>", { desc = "Move cursor left" })
map("i", "<C-j>", "<Down>", { desc = "Move cursor down" })
map("i", "<C-k>", "<Up>", { desc = "Move cursor up" })
map("i", "<C-l>", "<Right>", { desc = "Move cursor right" })

map("i", "<M-;>", "<C-o>A;<CR>", { desc = "Append semicolon and open new line" })
map("i", "<M-,>", "<C-o>m`<C-o>A;<C-o>``", { desc = "Append semicolon at EOL and return" })
map("i", "<C-r><C-d>", function() return vim.fn.strftime("%F") end, { expr = true, desc = "Insert date (YYYY-MM-DD)" })
map("i", "<C-r><C-t>", function() return vim.fn.strftime("%T") end, { expr = true, desc = "Insert time (HH:MM:SS)" })
map("i", "<C-r><C-f>", function() return vim.fn.expand("%:t") end, { expr = true, desc = "Insert filename" })
map("i", "<C-r><C-p>", function() return vim.fn.expand("%:p") end, { expr = true, desc = "Insert full file path" })
