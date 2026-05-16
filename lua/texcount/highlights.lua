local M = {}

function M.apply()
	local hl_groups = {
		{ "FreqExtreme", { fg = "#ca1551", bold = true } },
		{ "FreqHigh", { fg = "#fb4d3d" } },
		{ "FreqMedium", { fg = "#03cea4" } },
		{ "FreqLow", { fg = "#72ddf7" } },
		{ "FreqMin", { fg = "#eac435" } },
		{ "FreqFileName", { fg = "#61afef", bold = true } },
		{ "FreqPosition", { fg = "#e5c07b" } },
		{ "FreqWord", { fg = "#e06c75", bold = true } },
		{ "FreqWordFile", { fg = "#e06c75", underline = true, bold = true } },
	}

	for _, group in ipairs(hl_groups) do
		vim.api.nvim_set_hl(0, group[1], group[2])
	end
end

return M
