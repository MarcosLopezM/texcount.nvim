local M = {}

M.check = function()
	vim.health.start("TexCount [required]")
	if vim.fn.executable("rg") == 0 then
		vim.health.error("ripgrep not found on path")
		return
	end
	if vim.fn.executable("texcount") == 0 then
		vim.health.error("texcount not found on path")
		return
	end

	local results_rg = vim.system({ "rg", "--version" }, { text = true }):wait()
	local results_tc = vim.system({ "texcount", "--version" }, { text = true }):wait()

	if results_rg.code ~= 0 then
		vim.health.error("failed to retrieve rg's version", results_rg.stderr)
		return
	end
	if results_tc.code ~= 0 then
		vim.health.error("failed to retrieve texcount's version", results_tc.stderr)
		return
	end

	local v_rg = vim.version.parse(vim.split(results_rg.stdout or "", " ")[2])
	if not v_rg then
		vim.health.error("invalid ripgrep version output", results_rg.stdout)
		return
	end
	if v_rg.major ~= 14 then
		vim.health.error("ripgrep must be 14.x.x, but got " .. tostring(v_rg))
		return
	end
	vim.health.ok("ripgrep " .. tostring(v_rg))

	local v_tc = vim.version.parse(vim.split(results_tc.stdout or "", " ")[3])
	if not v_tc then
		vim.health.error("invalid texcount version output", results_tc.stdout)
		return
	end
	if v_tc.major ~= 3 then
		vim.health.error("texcount must be 3.x.x, but got " .. tostring(v_tc))
		return
	end
	vim.health.ok("texcount " .. tostring(v_tc))
end
return M
