-- Keymaps are automatically loaded on the VeryLazy event
-- Default LazyVim keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- Better vertical movement with centered cursor
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- Keep visual selection when indenting
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Move lines up/down in visual mode (LazyVim has Alt+j/k, adding J/K in visual)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Paste without yanking the replaced text
map("x", "p", [["_dP]], { desc = "Paste without yanking replaced text" })

-- Delete without yanking
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Quick save
map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })

-- Quickfix navigation
map("n", "]q", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
map("n", "[q", "<cmd>cprev<CR>zz", { desc = "Prev quickfix item" })

-- Buffer navigation (supplements LazyVim defaults)
map("n", "<leader>bo", "<cmd>%bd|e#|bd#<CR>", { desc = "Close other buffers" })

-- LSP-related keymaps (supplements LazyVim defaults)
map("n", "<leader>li", "<cmd>LspInfo<CR>", { desc = "LSP info" })
map("n", "<leader>lr", "<cmd>LspRestart<CR>", { desc = "LSP restart" })

-- Terminal: Escape to normal mode in terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ── Run / Compile ─────────────────────────────────────────
local function run_in_terminal(cmd)
  vim.cmd("w")
  Snacks.terminal(cmd, {
    win = { position = "float", height = 0.4, width = 0.9 },
  })
end

local function c_bin() return "/tmp/" .. vim.fn.expand("%:t:r") end
local function c_src() return vim.fn.expand("%") end

-- PRIMARY: clang + Weverything + ASan + UBSan (best error messages + catches most bugs)
map("n", "<leader>rr", function()
  run_in_terminal(
    "clang -std=c17 -Weverything -Wno-unsafe-buffer-usage -Wno-padded"
    .. " -fsanitize=address,undefined -fno-omit-frame-pointer -g "
    .. c_src() .. " -o " .. c_bin()
    .. " && echo '── Build OK ──' && " .. c_bin()
  )
end, { desc = "Run C (clang + Weverything + ASan/UBSan)" })

-- MEMORY: clang + MSan — catches uninitialized memory reads (clang-only, run separately)
map("n", "<leader>rm", function()
  run_in_terminal(
    "clang -std=c17 -Wall -Wextra -fsanitize=memory -fno-omit-frame-pointer -g "
    .. c_src() .. " -o " .. c_bin() .. "_msan"
    .. " && echo '── MSan Build OK ──' && " .. c_bin() .. "_msan"
  )
end, { desc = "Run C (clang + MSan: uninitialized memory)" })

-- EMBEDDED PEDANTIC: max warnings for clean embedded C, -O2 performance
-- -Wdouble-promotion   catches float→double silent promotion (kills embedded perf)
-- -Wcast-align=strict  catches misaligned pointer casts (hard faults on ARM/RISC-V)
-- -Wstrict-prototypes  requires full prototypes — no implicit args
-- -Wmissing-prototypes every function must be declared before use
-- -Wconversion         catches implicit int/float narrowing
-- -Wlogical-op         catches suspicious && / || with constants
-- -Wswitch-enum        every enum value must have a case
-- -Wswitch-default     every switch must have a default
-- -fno-common          no BSS merging — each symbol gets its own section
-- -ffunction-sections  each function in its own section → linker can GC dead code
-- -fdata-sections      same for data
-- -O2                  production performance without unsafe O3 transforms
map("n", "<leader>re", function()
  run_in_terminal(
    "gcc -std=c11 -O2"
    .. " -Wall -Wextra -Wpedantic"
    .. " -Wshadow -Wdouble-promotion -Wformat=2 -Wundef"
    .. " -Wcast-align=strict -Wstrict-prototypes -Wmissing-prototypes"
    .. " -Wconversion -Wfloat-conversion -Wnull-dereference"
    .. " -Wlogical-op -Wswitch-enum -Wswitch-default"
    .. " -fno-common -ffunction-sections -fdata-sections"
    .. " -g "
    .. c_src() .. " -o " .. c_bin()
    .. " && echo '── Embedded Build OK ──' && " .. c_bin()
  )
end, { desc = "Run C (GCC embedded pedantic + O2)" })

-- GCC fallback: useful for GNU extensions (LamQuant, __attribute__, inline asm)
map("n", "<leader>rg", function()
  run_in_terminal(
    "gcc -std=gnu11 -Wall -Wextra -fsanitize=address,undefined -g "
    .. c_src() .. " -o " .. c_bin()
    .. " && echo '── Build OK ──' && " .. c_bin()
  )
end, { desc = "Run C (GCC + GNU extensions)" })

-- FAST: clang -O2, no sanitizers (perf testing / timing)
map("n", "<leader>rq", function()
  run_in_terminal(
    "clang -O2 -std=c17 " .. c_src() .. " -o " .. c_bin() .. " && " .. c_bin()
  )
end, { desc = "Run C (fast, no sanitizers)" })

-- Python
map("n", "<leader>rp", function()
  run_in_terminal("python " .. vim.fn.expand("%"))
end, { desc = "Run Python" })

-- Assembly (via gcc/as)
map("n", "<leader>ra", function()
  run_in_terminal("gcc " .. c_src() .. " -o " .. c_bin() .. " && " .. c_bin())
end, { desc = "Run Assembly (via gcc)" })
