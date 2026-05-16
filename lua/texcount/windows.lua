local M = {}

---@param opts table?
---@return integer buf
---@return integer win
M.create_floating_win = function(opts)
	local buf = vim.api.nvim_create_buf(false, true)

	local max_width = vim.api.nvim_win_get_width(0)
	local max_height = vim.api.nvim_win_get_height(0)
	local width = math.floor(max_width * 0.5)
	local height = math.floor(max_height * 0.5)
	local col = (max_width - width) / 2
	local row = (max_height - height) / 2

	local default_config = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	}

	local win_opts = vim.tbl_extend("force", default_config, opts or {})
	local win = vim.api.nvim_open_win(buf, true, win_opts)
	vim.wo[win].wrap = true
	vim.wo[win].scrolloff = 0
	vim.wo[win].sidescrolloff = 0
	vim.wo[win].cursorline = true

	vim.keymap.set("n", "q", "<CMD>close<CR>", { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", "<CMD>close<CR>", { buffer = buf, silent = true })

	vim.bo[buf].buftype = "nofile"

	return buf, win
end

M.get_non_float_win = function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config_win = vim.api.nvim_win_get_config(win)
		if not config_win.relative or config_win.relative == "" then
			return win
		end
	end
end

return M
