local M = {}

local windows = require("texcount.windows")

---@class WindowOpts
---@field relative? string
---@field width? integer
---@field height? integer
---@field col? number
---@field row? number
---@field style? string
---@field border? string

---@param word string
---@param stats_win integer?
---@param win_opts WindowOpts
function M.search_word_occurrences(word, stats_win, win_opts)
	local jump_ns = vim.api.nvim_create_namespace("FreqJumpHighlight")
	local display_occurrences_win = windows.get_non_float_win()
	local args = { "rg", "-n", "--column", "-w", word, "-t", "tex" }

	vim.system(args, { text = true }, function(obj)
		vim.schedule(function()
			if not obj.stdout or obj.stdout == "" then
				vim.notify("Sin coincidencias para " .. word, vim.log.levels.WARN)
				return
			end

			local entries = {}
			local display_lines = {}

			for _, line in ipairs(vim.split(obj.stdout, "\n", { plain = true })) do
				local filename, lnum, col, content = line:match("^([^:]+):(%d+):(%d+):(.*)")

				if filename then
					local short = vim.fn.fnamemodify(filename, ":t")
					table.insert(entries, {
						filename = filename,
						lnum = tonumber(lnum),
						col = tonumber(col),
					})
					table.insert(display_lines, string.format("%s:%s:%s:%s", short, lnum, col, content))
				end
			end

			if #display_lines == 0 then
				vim.notify("Sin coincidencias para " .. word, vim.log.levels.WARN)
			end

			local buf, win = windows.create_floating_win(win_opts)

			vim.api.nvim_win_set_config(win, {
				title = string.format(" %d coincidencias para %s ", #display_lines, word),
				title_pos = "center",
			})

			vim.api.nvim_buf_set_lines(buf, 0, -1, true, display_lines)
			vim.bo[buf].modifiable = false

			vim.api.nvim_win_call(win, function()
				vim.fn.matchadd("FreqFileName", "[^/:]\\+\\ze:")
				vim.fn.matchadd("FreqPosition", ":[0-9]*:[0-9]*:")
				vim.fn.matchadd("FreqWord", "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>")
			end)

			local function jump_to_entry()
				local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
				local entry = entries[cursor_line]
				if not entry then
					return
				end

				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end

				if stats_win and vim.api.nvim_win_is_valid(stats_win) then
					vim.api.nvim_win_close(stats_win, true)
				end

				if not vim.api.nvim_win_is_valid(display_occurrences_win) then
					display_occurrences_win = windows.get_non_float_win()
				end
				if not display_occurrences_win then
					return
				end

				vim.api.nvim_win_call(display_occurrences_win, function()
					vim.cmd("edit " .. vim.fn.fnameescape(entry.filename))
					vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col - 1 })
				end)

				local target_buf = vim.api.nvim_win_get_buf(display_occurrences_win)

				vim.api.nvim_buf_clear_namespace(target_buf, jump_ns, 0, -1)
				vim.api.nvim_buf_set_extmark(target_buf, jump_ns, entry.lnum - 1, entry.col - 1, {
					end_row = entry.lnum - 1,
					end_col = entry.col - 1 + #word,
					hl_group = "FreqWordFile",
				})

				vim.api.nvim_set_current_win(display_occurrences_win)
				vim.api.nvim_create_autocmd("CursorMoved", {
					buffer = target_buf,
					once = true,
					callback = function()
						vim.api.nvim_buf_clear_namespace(target_buf, jump_ns, 0, -1)
					end,
				})

				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			end

			local function close_float()
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end

				if stats_win and vim.api.nvim_win_is_valid(stats_win) then
					vim.api.nvim_set_current_win(stats_win)
				end
			end

			vim.keymap.set("n", "<CR>", jump_to_entry, { buffer = buf, silent = true })
			vim.keymap.set("n", "q", close_float, { buffer = buf, silent = true })
			vim.keymap.set("n", "<Esc>", close_float, { buffer = buf, silent = true })
		end)
	end)
end

---@param results TexCountResult[]
function M.create_stats_window(results)
	if #results == 0 then
		vim.notify("No hay palabras repetidas.", vim.log.levels.WARN)
		return
	end

	local buf, win = windows.create_floating_win()

	local show_all = false
	local display_limit = 15
	local namespace_id = vim.api.nvim_create_namespace("TexCountColors")

	local freq_hl = {
		{ threshold = 40, hl = "FreqExtreme" },
		{ threshold = 20, hl = "FreqHigh" },
		{ threshold = 10, hl = "FreqMedium" },
		{ threshold = 5, hl = "FreqMin" },
		{ threshold = 0, hl = "FreqLow" },
	}

	local function get_hl(freq)
		for _, band in ipairs(freq_hl) do
			if freq >= band.threshold then
				return band.hl
			end
		end
		return "FreqLow"
	end

	local function render_buffer()
		local lines = {}
		local highlights = {}
		local limit = show_all and #results or math.min(#results, display_limit)

		for i = 1, limit do
			local data = results[i]
			table.insert(lines, string.format("  %4d  │  %s", data.freq, data.word))
			table.insert(highlights, { row = #lines - 1, hl = get_hl(data.freq) })
		end

		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false

		vim.api.nvim_buf_clear_namespace(buf, namespace_id, 0, -1)

		for _, hl in ipairs(highlights) do
			vim.api.nvim_buf_set_extmark(buf, namespace_id, hl.row, 0, {
				end_row = hl.row + 1,
				end_col = 0,
				hl_group = hl.hl,
			})
		end

		local title = show_all and " Word Freq (All) " or string.format(" Word Freq (Top %d) ", limit)
		vim.api.nvim_win_set_config(win, { title = title, title_pos = "center" })
	end

	render_buffer()

	vim.keymap.set("n", "t", function()
		show_all = not show_all
		render_buffer()
	end, { buffer = buf, silent = true, desc = "Toggle All/Top N" })

	vim.keymap.set("n", "<CR>", function()
		local cursor = vim.api.nvim_win_get_cursor(win)
		local line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
		local word = line:match("│%s*(.-)%s*$")

		if word and word ~= "" then
			local config = vim.api.nvim_win_get_config(win)
			M.search_word_occurrences(
				word,
				win,
				{ row = config.row, col = config.col, width = config.width, height = config.height }
			)
		end
	end, { buffer = buf, silent = true, desc = "Search word occurrences" })
end

return M
