-- options.lua —

local opt = vim.opt

-- General behavior
opt.mouse = "a"                 -- Enable mouse support in all modes
opt.clipboard = "unnamedplus"   -- Sync yank/paste with system clipboard
opt.undofile = true             -- Maintain persistent undo files across edit sessions
opt.swapfile = false            -- Disable swap files
opt.autoread = true             -- Automatically read files modified outside of Neovim
opt.confirm = true              -- Confirm unsaved changes when quitting instead of failing
opt.updatetime = 250            -- Faster CursorHold trigger + swap sync delay
opt.timeoutlen = 400            -- Time in ms to wait for a mapped sequence to complete
opt.selection = "inclusive"     -- Selection behavior (includes final character)

-- Editor UI
opt.number = true               -- Display current line number
opt.relativenumber = true       -- Display relative numbers for other lines
opt.cursorline = true           -- Highlight the screen line under the cursor
opt.signcolumn = "yes"          -- Always show signcolumn to avoid shifting layout
opt.scrolloff = 8               -- Keep 8 buffer lines visible above/below cursor
opt.wrap = false                -- Disable soft line wrapping
opt.termguicolors = true        -- True color support (24-bit)
opt.list = true                 -- Display whitespace guides
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = "╌" } -- Hide empty line tildes (~) and show fold character

-- Code Folding
opt.foldlevel = 99              -- Start with all folds open
opt.foldmethod = "expr"         -- Fold based on treesitter expression
opt.foldnestmax = 10            -- Limit folding depth
opt.foldtext = ""               -- Show folded line with actual syntax highlighting
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Windows & Splits
opt.splitright = true           -- Open vertical splits to the right
opt.splitbelow = true           -- Open horizontal splits below

-- Indentation
opt.expandtab = true            -- Translate tabs to spaces
opt.shiftwidth = 4              -- Visual indent size
opt.tabstop = 4                 -- Visual width of a tab character
opt.softtabstop = 4
opt.smartindent = true          -- Smart syntax indenting
opt.breakindent = true          -- Wrapped lines keep original indentation level

-- Search settings
opt.ignorecase = true           -- Case-insensitive search queries
opt.smartcase = true            -- Match case if query contains capital letters
opt.inccommand = "split"        -- Show live preview of search-and-replace command in a split

-- Enable syntax highlighting for fenced code blocks in Markdown
vim.g.markdown_fenced_languages = {
  "ts=typescript",
  "js=javascript",
  "bash",
  "sh",
  "python",
  "lua",
  "vim",
  "json",
  "yaml",
  "html",
  "css",
  "rust"
}
