return {
  -- mini.surround — add/delete/change surrounding pairs
  {
    "nvim-mini/mini.surround",
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    },
  },

  -- flash.nvim — enhanced navigation/jumping
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      labels = "asdfghjklqwertyuiopzxcvbnm",
      search = {
        multi_window = true,
        forward = true,
        wrap = true,
      },
      jump = {
        jumplist = true,
        pos = "start",
        autojump = false,
      },
      label = {
        uppercase = false,
        after = true,
        before = false,
        style = "overlay",
      },
      modes = {
        search = {
          enabled = true,
        },
        char = {
          enabled = true,
          jump_labels = true,
        },
        treesitter = {
          labels = "abcdefghijklmnopqrstuvwxyz",
          jump = { pos = "range" },
          label = { before = true, after = true, style = "inline" },
        },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    },
  },

  -- trouble.nvim — better diagnostics list
  {
    "folke/trouble.nvim",
    opts = {
      use_diagnostic_signs = true,
      focus = true,
      auto_close = false,
      auto_preview = true,
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
  },

  -- todo-comments.nvim — highlight TODO/FIXME/HACK etc.
  {
    "folke/todo-comments.nvim",
    opts = {
      signs = true,
      highlight = {
        multiline = false,
        pattern = [[.*<(KEYWORDS)\s*:]],
      },
      search = {
        pattern = [[\b(KEYWORDS):]],
      },
    },
  },

  -- gitsigns — inline git blame, hunks
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
      },
    },
  },

  -- which-key — show pending keybinds
  {
    "folke/which-key.nvim",
    opts = {
      plugins = { spelling = true },
      spec = {
        { "<leader>l", group = "lsp" },
      },
    },
  },
}
