local core = require("npm-runner.core")

vim.api.nvim_create_user_command("NpmDevStart", core.start, {})
vim.api.nvim_create_user_command("NpmDevStop", core.stop, {})
vim.api.nvim_create_user_command("NpmDevToggle", core.toggle, {})
vim.api.nvim_create_user_command("NpmRun", core.run, {})

return core
