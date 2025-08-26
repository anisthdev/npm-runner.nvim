local M = {}

M.options = {
	height = 10,
	focus_on_open = true,
	colors = {
		dev = "#33FF33",
		build = "#3333FF",
		test = "#FFFF33",
		format = "#FF33FF",
	},
}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
