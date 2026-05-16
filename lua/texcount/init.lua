local M = {}
local display = require("texcount.display")
local parser = require("texcount.parser")
local files = require("texcount.file_handling")

M.config = {
	min_freq = 2,
	keymaps = {
		run = "<leader>tc",
		add = "<leader>ta",
		delete = "<leader>td",
	},
}

M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	require("texcount.highlights").apply()

	local km = M.config.keymaps
	if km then
		vim.keymap.set("n", km.run, M.run, { desc = "TexCount: Run" })
		vim.keymap.set("n", km.add, files.add_word_to_ignore, { desc = "TexCount: Add word to ignore." })
		vim.keymap.set("n", km.delete, files.delete_word_from_ignore, { desc = "TexCount: Delete word from ignore." })
	end
end

---@param min_freq string | number
---@param filename string
function M.run(min_freq, filename)
	min_freq = min_freq or M.config.min_freq
	filename = filename or vim.fn.expand("%")
	local cmd = { "texcount", "-freq=" .. min_freq, "-strict", "--merge ", filename }

	vim.system(cmd, { text = true }, function(obj)
		if obj.code ~= 0 then
			vim.schedule(function()
				vim.notify("TexCount: " .. (obj.stderr or "Unknown error"), vim.log.levels.ERROR)
			end)
			return
		end

		local results = parser.parse_texcount_output(obj.stdout)

		vim.schedule(function()
			display.create_stats_window(results)
		end)
	end)
end

return M
