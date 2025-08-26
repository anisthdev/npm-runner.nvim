local M = {}
local job_id = nil
local buf, win = nil, nil
local baleia = require("baleia").setup({ line_starts_at = 1 })
local script_helper = require("npm-runner.scripts")

-- Create (or reuse) the log buffer
local function create_buf()
	if buf and vim.api.nvim_buf_is_valid(buf) then
		return buf
	end
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	return buf
end

local function open_win()
	if win and vim.api.nvim_win_is_valid(win) then
		return
	end
	vim.cmd("botright 15split")
	win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, create_buf())
end

local function close_win()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
		win = nil
	end
end

local function append_data(data)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	if not data then
		return
	end
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	baleia.buf_set_lines(buf, -1, -1, false, data)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	-- scroll to bottom if window open
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
	end
end

function M.start(name)
	if job_id then
		vim.notify("npm run dev already running", vim.log.levels.WARN)
		open_win()
		return
	end
	open_win()
	job_id = vim.fn.jobstart({ "npm", "run", name }, {
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = function(_, data, _)
			append_data(data)
		end,
		on_stderr = function(_, data, _)
			append_data(data)
		end,
		on_exit = function(_, code, _)
			append_data({ "", "[Process exited with code " .. code .. "]" })
			job_id = nil
		end,
	})
	vim.notify("Started npm run dev", vim.log.levels.INFO)
end

function M.stop()
	if job_id then
		vim.fn.jobstop(job_id)
		job_id = nil
		append_data({ "", "[Process killed]" })
		vim.notify("Stopped npm run dev", vim.log.levels.INFO)
	else
		vim.notify("No process running", vim.log.levels.WARN)
	end
end

function M.toggle()
	if win and vim.api.nvim_win_is_valid(win) then
		close_win()
	else
		open_win()
	end
end

function M.run()
	local scripts = script_helper.get_scripts()
	if #scripts == 0 then
		return
	end

	vim.ui.select(scripts, { prompt = "Select npm script: " }, function(choice)
		if choice then
			M.start(choice)
		end
	end)
end

return M
