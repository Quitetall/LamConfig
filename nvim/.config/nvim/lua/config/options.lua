-- Options are automatically loaded before lazy.nvim startup
-- Default LazyVim options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation defaults (overridden per filetype in autocmds.lua)
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Scrolling
opt.scrolloff = 10
opt.sidescrolloff = 10

-- Clipboard — use system clipboard
opt.clipboard = "unnamedplus"

-- UI
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
opt.showmode = false
opt.pumheight = 15
opt.splitbelow = true
opt.splitright = true

-- Persistent undo
opt.undofile = true
opt.undolevels = 10000

-- Faster updates
opt.updatetime = 200
opt.timeoutlen = 300

-- Mouse
opt.mouse = "a"

-- Fill chars — cleaner look
opt.fillchars = {
  fold = " ",
  diff = "╱",
  eob = " ",
}

-- Cursor shapes
--   block  = fat square (normal mode default)
--   ver25  = thin vertical bar (insert mode, 25% width)
--   hor20  = thin horizontal underline (replace mode)
opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
