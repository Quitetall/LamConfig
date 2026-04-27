require("lazy").setup({
  spec = {
    -- Import LazyVim and its default plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Import any additional LazyVim extras here
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.clangd" },
    { import = "lazyvim.plugins.extras.lang.go" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    { import = "lazyvim.plugins.extras.lang.toml" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.cmake" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.dap.core" },

    -- Import custom plugins from lua/plugins/
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    -- LazyVim recommends latest stable versions
    version = false,
  },
  install = { colorscheme = { "kanagawa", "tokyonight", "habamax" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      -- Disable some built-in plugins we don't need
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
