return {
  -- nvim-dap — debugger core (loaded via dap.core extra)
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- ── C / C++ via codelldb (already installed by mason) ──
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }
      dap.configurations.c = {
        {
          name = "Launch (codelldb)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
      dap.configurations.cpp = dap.configurations.c

      -- ── Python via debugpy ──
      dap.adapters.python = function(cb, config)
        if config.request == "attach" then
          local port = (config.connect or config).port
          local host = (config.connect or config).host or "127.0.0.1"
          cb({ type = "server", port = port, host = host })
        else
          cb({
            type = "executable",
            command = "python",
            args = { "-m", "debugpy.adapter" },
          })
        end
      end
      dap.configurations.python = {
        {
          name = "Launch file",
          type = "python",
          request = "launch",
          program = "${file}",
          pythonPath = function()
            local venv = os.getenv("VIRTUAL_ENV")
            if venv then return venv .. "/bin/python" end
            return "python"
          end,
        },
      }

      -- ── UI: open/close automatically ──
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      -- ── Virtual text: show variable values inline ──
      require("nvim-dap-virtual-text").setup({
        commented = true, -- show as comment
      })
    end,
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end,                        desc = "Toggle Breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,                                  desc = "Continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end,                             desc = "Run to Cursor" },
      { "<leader>di", function() require("dap").step_into() end,                                 desc = "Step Into" },
      { "<leader>do", function() require("dap").step_over() end,                                 desc = "Step Over" },
      { "<leader>dO", function() require("dap").step_out() end,                                  desc = "Step Out" },
      { "<leader>dr", function() require("dap").repl.toggle() end,                               desc = "Toggle REPL" },
      { "<leader>du", function() require("dapui").toggle() end,                                  desc = "Toggle DAP UI" },
      { "<leader>dx", function() require("dap").terminate() end,                                 desc = "Terminate" },
    },
  },
}
