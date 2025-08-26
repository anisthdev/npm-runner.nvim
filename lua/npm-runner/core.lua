local M = {}
local running_scripts = {} -- Store running scripts by name
local baleia = require("baleia").setup({ line_starts_at = 1 })
local script_helper = require("npm-runner.scripts")
local config = require("npm-runner.config")

-- Get or create highlight group for a script
local function get_or_create_hl_group(name)
	local hl_group = "NpmRunnerTitle_" .. name
	local color = config.options.colors[name]
	if not color then
		local bright_colors = { "#FB513D", "#BCBE30", "#F1BB36", "#7FA499", "#CC879C", "#92C080" }
		color = bright_colors[math.random(#bright_colors)]
	end

	if vim.fn.hlexists(hl_group) == 0 then
		vim.api.nvim_set_hl(0, hl_group, { bg = color, fg = "#323232" })
	end
	return hl_group
end

-- Helper function to create a new buffer for a script
local function create_buf()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	return buf
end

-- Helper function to open a window for a script
local function open_win(buf, name)
	local current_win = vim.api.nvim_get_current_win()
	vim.cmd("botright " .. config.options.height .. "split")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	local hl_group = get_or_create_hl_group(name)
	vim.api.nvim_win_set_option(win, "winbar", "%#" .. hl_group .. "# " .. name .. " %# #")
	vim.api.nvim_win_set_option(win, "winhighlight", "WinBar:Normal")
	vim.api.nvim_win_set_option(win, "cursorline", false)
	vim.api.nvim_win_set_option(win, "number", false)
	vim.api.nvim_win_set_option(win, "relativenumber", false)
	vim.api.nvim_win_set_option(win, "signcolumn", "no")
	vim.api.nvim_win_set_option(win, "foldcolumn", "0")

	if not config.options.focus_on_open then
		vim.api.nvim_set_current_win(current_win)
	end

	return win
end

-- Helper function to close a script's window
local function close_win(win)
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

-- Helper function to append data to a script's buffer
local function append_data(buf, data)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	if not data then
		return
	end
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	baleia.buf_set_lines(buf, -1, -1, false, data)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

function M.start(name)
	if running_scripts[name] then
		vim.notify("Script '" .. name .. "' is already running.", vim.log.levels.WARN)
		if not running_scripts[name].win or not vim.api.nvim_win_is_valid(running_scripts[name].win) then
			running_scripts[name].win = open_win(running_scripts[name].buf, name)
		end
		return
	end

	local buf = create_buf()
	local win = open_win(buf, name)
	local job_id

	job_id = vim.fn.jobstart({ "npm", "run", name }, {
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = function(_, data, _)
			append_data(buf, data)
			if win and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
			end
		end,
		on_stderr = function(_, data, _)
			append_data(buf, data)
			if win and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
			end
		end,
		on_exit = function(_, code, _)
			append_data(buf, { "", "[Process '" .. name .. "' exited with code " .. code .. "]" })
			running_scripts[name] = nil
		end,
	})

	running_scripts[name] = {
		job_id = job_id,
		buf = buf,
		win = win,
	}
	vim.notify("Started script '" .. name .. "'", vim.log.levels.INFO)
end

function M.stop(args)
	local name = args.args
	if not name or name == "" then
		vim.notify("Please provide a script name to stop.", vim.log.levels.ERROR)
		return
	end

	local script = running_scripts[name]
	if script and script.job_id then
		vim.fn.jobstop(script.job_id)
		append_data(script.buf, { "", "[Process '" .. name .. "' killed]" })
		running_scripts[name] = nil
		vim.notify("Stopped script '" .. name .. "'", vim.log.levels.INFO)
	else
		vim.notify("Script '" .. name .. "' is not running.", vim.log.levels.WARN)
	end
end

function M.toggle(args)
	local name = args.args
	if not name or name == "" then
		vim.notify("Please provide a script name to toggle.", vim.log.levels.ERROR)
		return
	end

	local script = running_scripts[name]
	if script then
		if script.win and vim.api.nvim_win_is_valid(script.win) then
			close_win(script.win)
			script.win = nil
		else
			script.win = open_win(script.buf, name)
		end
	else
		vim.notify("Script '" .. name .. "' is not running.", vim.log.levels.WARN)
	end
end

function M.run(args)
	local scripts = script_helper.get_scripts()
	if #scripts == 0 then
		return
	end

	if args.args and #args.args > 0 then
		local script_name = args.args
		local is_valid = false
		for _, script in ipairs(scripts) do
			if script == script_name then
				is_valid = true
				break
			end
		end

		if is_valid then
			M.start(script_name)
		else
			vim.notify("Invalid script name: " .. script_name, vim.log.levels.ERROR)
		end
	else
		vim.ui.select(scripts, { prompt = "Select npm script: " }, function(choice)
			if choice then
				M.start(choice)
			end
		end)
	end
end

function M.get_running_scripts()
	local running = {}
	for name, _ in pairs(running_scripts) do
		table.insert(running, name)
	end
	return running
end

return M
