return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- Primary languages
        "c",
        "cpp",
        "rust",
        "python",
        "lua",
        "javascript",
        "typescript",
        "tsx",
        "go",
        "gomod",
        "gowork",
        "gosum",
        "bash",

        -- Data/config formats
        "json",
        "jsonc",
        "json5",
        "yaml",
        "toml",
        "xml",

        -- Markup and docs
        "markdown",
        "markdown_inline",
        "rst",

        -- Build systems
        "cmake",
        "make",
        "ninja",

        -- Neovim / editor
        "vim",
        "vimdoc",
        "luadoc",
        "luap",
        "query",
        "regex",

        -- Git
        "diff",
        "git_config",
        "git_rebase",
        "gitcommit",
        "gitignore",

        -- Web
        "html",
        "css",

        -- Misc
        "dockerfile",
        "printf",
        "comment",
      },

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },

      indent = {
        enable = true,
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },

      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
            ["ai"] = "@conditional.outer",
            ["ii"] = "@conditional.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
            ["]a"] = "@parameter.inner",
          },
          goto_next_end = {
            ["]F"] = "@function.outer",
            ["]C"] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
            ["[a"] = "@parameter.inner",
          },
          goto_previous_end = {
            ["[F"] = "@function.outer",
            ["[C"] = "@class.outer",
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>a"] = "@parameter.inner",
          },
          swap_previous = {
            ["<leader>A"] = "@parameter.inner",
          },
        },
      },
    },
  },

  -- Treesitter textobjects
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    enabled = true,
  },

  -- Treesitter context — sticky function header
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = {
      enable = true,
      max_lines = 3,
      min_window_height = 20,
      line_numbers = true,
      multiline_threshold = 5,
      trim_scope = "outer",
      mode = "cursor",
    },
  },
}
