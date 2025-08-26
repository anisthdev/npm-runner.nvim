local core = require("npm-runner.core")
local config = require("npm-runner.config")

local M = {}

function M.setup(opts)
	config.setup(opts)
end

vim.api.nvim_create_user_command("NpmRun", core.run, { nargs = "?" })

vim.api.nvim_create_user_command("NpmRunToggle", core.toggle, {
	nargs = 1,
	complete = function()
		return core.get_running_scripts()
	end,
})

vim.api.nvim_create_user_command("NpmRunStop", core.stop, {
	nargs = 1,
	complete = function()
		return core.get_running_scripts()
	end,
})

return M