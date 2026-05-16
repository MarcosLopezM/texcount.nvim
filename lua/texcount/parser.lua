local M = {}
local files = require("texcount.file_handling")

---@class TexCountResult
---@field freq integer
---@field word string
---@param stdout string
---@return TexCountResult[]
function M.parse_texcount_output(stdout)
	local ignores = files.get_ignored_words()
	local words = {}
	local is_header = false

	for line in stdout:gmatch("[^\r\n]+") do
		if line:find("---", 1, true) then
			is_header = true
		elseif is_header then
			local word, freq = line:match("^%s*(.+)%s*:%s*(%d+)%s*$")

			if word and word ~= "" and not ignores[word] then
				table.insert(words, { freq = tonumber(freq), word = word })
			end
		end
	end

	if #words > 0 then
		table.remove(words)
	end

	return words
end

return M
