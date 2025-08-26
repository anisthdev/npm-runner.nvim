local uv = vim.loop
local M = {}

function M.read_package_json()
	local cwd = uv.cwd()
	local path = cwd .. "/package.json"
	local stat = uv.fs_stat(path)
	if not stat then
		vim.notify("No package.json found in " .. cwd, vim.log.levels.WARN)
		return nil
	end

	local fd = assert(uv.fs_open(path, "r", 438))
	local data = assert(uv.fs_read(fd, stat.size, 0))
	uv.fs_close(fd)

	local ok, json = pcall(vim.fn.json_decode, data)
	if not ok then
		vim.notify("Failed to parse package.json", vim.log.levels.ERROR)
		return nil
	end

	return json
end

function M.get_scripts()
	local pkg = M.read_package_json()
	if not pkg or not pkg.scripts then
		vim.notify("NO scripts found in package.json", vim.log.levels.WARN)
		return {}
	end
	local scripts = {}
	for name, _ in pairs(pkg.scripts) do
		table.insert(scripts, name)
	end
	table.sort(scripts)
	return scripts
end
return M
