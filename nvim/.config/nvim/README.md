# nvim config

LazyVim-based IDE setup for C, RISC-V, Python, Rust, Go.
Theme: Kanagawa. Font: IntoneMono Nerd Font Mono.

---

## Stack

| Layer | Tool |
|-------|------|
| Base | [LazyVim](https://lazyvim.org) on nvim 0.12+ |
| Completion | blink.cmp |
| Fuzzy find | snacks.nvim |
| Navigation | flash.nvim |
| Notes (markdown) | obsidian.nvim → `~/Desktop/ObsidianVault` |
| Notes (structured) | Neorg → `~/Desktop/ObsidianVault/neorg/` |
| Debugger | nvim-dap + nvim-dap-ui |
| Git UI | lazygit (`<leader>gg`) |

---

## Plugin files

```
lua/config/
  lazy.lua        — extras and plugin imports
  keymaps.lua     — all custom keybinds
  options.lua     — editor settings, cursor shapes
  autocmds.lua    — filetype rules, indentation

lua/plugins/
  notes.lua       — obsidian.nvim + neorg
  debug.lua       — nvim-dap for C and Python
  editor.lua      — flash, surround, trouble, gitsigns, which-key
  lsp.lua         — Mason, LSP servers, conform formatters
  treesitter.lua  — parsers, textobjects, context
  ui.lua          — lualine, dashboard, bufferline, noice
  colorscheme.lua — kanagawa
```

---

## LSP servers (auto-installed via Mason)

`clangd` `rust-analyzer` `pyright` `lua-language-server` `gopls`
`typescript-language-server` `bash-language-server` `marksman`
`yaml-language-server` `json-lsp` `taplo` `cmake-language-server`

## Formatters

`clang-format` `black` `isort` `stylua` `prettier` `shfmt` `rustfmt` `gofmt` `taplo` `cmake-format`

## DAP adapters

`codelldb` (C/C++) `debugpy` (Python)

---

## Keymaps

### Navigation
| Key | Action |
|-----|--------|
| `<C-d>` / `<C-u>` | Scroll down/up (cursor stays centered) |
| `n` / `N` | Next/prev search result (centered) |
| `s` + 2 chars | flash.nvim jump anywhere on screen |
| `S` | flash.nvim treesitter selection |

### Editing
| Key | Action |
|-----|--------|
| `<C-s>` | Save |
| `<leader>d` | Delete without yanking |
| `p` (visual) | Paste without yanking replaced text |
| `J` / `K` (visual) | Move selection down/up |
| `<` / `>` (visual) | Indent and keep selection |

### LSP
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover docs |
| `<leader>ca` | Code action |
| `<leader>li` | LSP info |
| `<leader>lr` | LSP restart |

### Run / Compile (C)
| Key | Preset | Use when |
|-----|--------|----------|
| `<leader>rr` | clang `-Weverything` + ASan + UBSan | Default — best diagnostics |
| `<leader>rm` | clang + MSan | After `rr` is clean — catches uninitialized reads |
| `<leader>re` | GCC embedded pedantic `-O2` | Embedded / clean code audit |
| `<leader>rg` | GCC + GNU extensions | `__attribute__`, inline asm, LamQuant |
| `<leader>rq` | clang `-O2`, no sanitizers | Perf/timing benchmarks |
| `<leader>rp` | Python | Run `.py` file |
| `<leader>ra` | GCC assembler | `.asm` / `.s` files |

#### Embedded pedantic flags (`<leader>re`)
```
gcc -std=c11 -O2
  -Wall -Wextra -Wpedantic
  -Wshadow                   variable shadowing
  -Wdouble-promotion         float→double silent promotion (kills MCU perf)
  -Wformat=2                 format string security
  -Wundef                    using undefined macros
  -Wcast-align=strict        misaligned pointer casts → hard fault on ARM/RISC-V
  -Wstrict-prototypes        require full function prototypes
  -Wmissing-prototypes       every function declared before use
  -Wconversion               implicit narrowing conversions
  -Wfloat-conversion         float↔int implicit conversion
  -Wnull-dereference         potential null dereference
  -Wlogical-op               suspicious && / || with constants
  -Wswitch-enum              every enum value needs a case
  -Wswitch-default           every switch needs a default
  -fno-common                no BSS symbol merging
  -ffunction-sections        each function in own section → linker GC
  -fdata-sections            same for data
```

### Debug (DAP)
| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Continue / start (asks for binary path for C) |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Toggle REPL |
| `<leader>du` | Toggle DAP UI |
| `<leader>dx` | Terminate session |

C debug workflow: `gcc -g file.c -o file` → `<leader>dc` → point at binary.
Python: just `<leader>dc` on `.py` file, no compile needed.

### Notes (Obsidian vault)
| Key | Action |
|-----|--------|
| `<leader>od` | Today's daily note |
| `<leader>of` | Fuzzy find note |
| `<leader>os` | Search vault content |
| `<leader>on` | New note → Inbox |
| `<leader>ob` | Backlinks |
| `<leader>ol` | Links in current note |
| `<leader>ot` | Tags |

### Notes (Neorg)
| Key | Action |
|-----|--------|
| `<leader>nj` | Journal today |
| `<leader>ni` | Neorg index |
| `<leader>nm` | Open neorg workspace |
| `<leader>nr` | Return to last file |
| `gO` (in .norg) | Table of contents |
| `<C-Space>` (in .norg) | Cycle task state |

### Buffers / Windows
| Key | Action |
|-----|--------|
| `<leader>bb` | Switch buffer |
| `<leader>bo` | Close other buffers |
| `]q` / `[q` | Next/prev quickfix |
| `<leader>xx` | Trouble diagnostics |

---

## Second Brain (vault)

Vault: `~/Desktop/ObsidianVault` | Repo: `github.com/Quitetall/SecondBrain`

Structure (LYT — Linking Your Thinking):
```
00 - Inbox/        capture everything here first
10 - Atlas/        Home.md → Atlas.md → all MOCs
20 - Cards/        atomic knowledge notes
30 - Sources/      books, papers, references
40 - Projects/     active work (LamQuant, School)
50 - Archive/      dead stuff — never delete
Daily Notes/       Obsidian daily notes
neorg/             Neorg workspace (.norg files)
```

Open vault in nvim: `notes` (shell alias — starts nvim as server at `/tmp/nvim-notes.sock`)

---

## Shell (zshrc additions)

```bash
VAULT="$HOME/Desktop/ObsidianVault"
NVIM_SOCKET="/tmp/nvim-notes.sock"

notes() {
  rm -f "$NVIM_SOCKET"
  cd "$VAULT" && nvim --listen "$NVIM_SOCKET" "$VAULT/10 - Atlas/Home.md"
}
```

Atuin replaces `Ctrl+R` for shell history search.

---

## Fresh install notes

1. `stow nvim` from dotfiles
2. Open nvim — Lazy auto-installs all plugins
3. `:MasonInstall debugpy` — Python DAP adapter
4. `codelldb` auto-installed via Mason `ensure_installed`
5. Neorg norg/norg_meta parsers: symlink from lazy-rocks to site/parser (handled automatically in notes.lua config function)
6. Install font: `sudo pacman -S ttf-intone-nerd`
7. Ghostty font: `IntoneMono Nerd Font Mono`
