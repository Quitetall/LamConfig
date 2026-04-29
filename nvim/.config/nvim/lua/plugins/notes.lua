return {
  -- obsidian.nvim — wiki links, daily notes, search inside nvim
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = {
        {
          name = "vault",
          path = "~/Desktop/ObsidianVault",
        },
      },
      daily_notes = {
        folder = "Daily Notes",
        date_format = "%Y-%m-%d",
        template = nil,
      },
      completion = {
        nvim_cmp = false,
        min_chars = 2,
      },
      new_notes_location = "notes_subdir",
      notes_subdir = "00 - Inbox",
      note_id_func = function(title)
        -- Use title as filename directly, no UUID suffix
        return title
      end,
      follow_url_func = function(url)
        vim.fn.jobstart({ "xdg-open", url })
      end,
      ui = { enable = false }, -- render-markdown.nvim handles rendering
    },
    keys = {
      { "<leader>on", "<cmd>ObsidianNew<cr>",           desc = "New Note" },
      { "<leader>oo", "<cmd>ObsidianOpen<cr>",          desc = "Open in Obsidian" },
      { "<leader>of", "<cmd>ObsidianQuickSwitch<cr>",   desc = "Find Note" },
      { "<leader>os", "<cmd>ObsidianSearch<cr>",        desc = "Search Notes" },
      { "<leader>od", "<cmd>ObsidianToday<cr>",         desc = "Daily Note" },
      { "<leader>ob", "<cmd>ObsidianBacklinks<cr>",     desc = "Backlinks" },
      { "<leader>ol", "<cmd>ObsidianLinks<cr>",         desc = "Links" },
      { "<leader>ot", "<cmd>ObsidianTags<cr>",          desc = "Tags" },
    },
  },

  -- neorg — org-mode power inside nvim, .norg files
  {
    "nvim-neorg/neorg",
    lazy = false,
    version = "*",
    dependencies = { "luarocks.nvim" },
    config = function()
      -- Ensure luarocks-installed norg parsers are visible to treesitter
      local rocks = vim.fn.stdpath("data") .. "/lazy-rocks"
      local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
      for _, pkg in ipairs({ "tree-sitter-norg", "tree-sitter-norg-meta" }) do
        local so_dir = rocks .. "/" .. pkg .. "/lib/lua/5.1/parser"
        if vim.fn.isdirectory(so_dir) == 1 then
          vim.opt.runtimepath:append(rocks .. "/" .. pkg .. "/lib/lua/5.1")
        end
      end

      require("neorg").setup({
        load = {
          ["core.defaults"] = {},       -- all standard Neorg keybinds
          ["core.concealer"] = {},      -- pretty icons/symbols
          ["core.dirman"] = {
            config = {
              workspaces = {
                notes = "~/Desktop/ObsidianVault/neorg",
              },
              default_workspace = "notes",
            },
          },
          ["core.integrations.treesitter"] = {},
          ["core.summary"] = {},        -- auto-generate workspace index
          ["core.export"] = {},         -- export .norg to markdown
          ["core.journal"] = {
            config = {
              workspace = "notes",
              journal_folder = "journal",
              index = "index.norg",
            },
          },
        },
      })

      -- Override globally-bound keys that conflict with Neorg in .norg buffers:
      --   gO is globally bound to vim.lsp.buf.document_symbol() — useless in norg
      --   <C-Space> is globally bound to treesitter incremental selection — useless in norg
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "norg",
        callback = function(ev)
          vim.keymap.set("n", "<C-Space>",
            "<Plug>(neorg.qol.todo-items.todo.task-cycle)",
            { buffer = ev.buf, desc = "Neorg: Cycle Task State" })
          vim.keymap.set("n", "gO",
            "<cmd>Neorg toc<CR>",
            { buffer = ev.buf, desc = "Neorg: Table of Contents" })
        end,
      })
    end,
    keys = {
      { "<leader>nj", "<cmd>Neorg journal today<cr>",       desc = "Neorg Journal Today" },
      { "<leader>ni", "<cmd>Neorg index<cr>",               desc = "Neorg Index" },
      { "<leader>nr", "<cmd>Neorg return<cr>",              desc = "Neorg Return" },
      { "<leader>nm", "<cmd>Neorg workspace notes<cr>",     desc = "Neorg Workspace" },
    },
  },

  -- luarocks.nvim — required by neorg for Lua dependencies
  {
    "vhyrro/luarocks.nvim",
    priority = 1001,
    opts = {},
  },
}
