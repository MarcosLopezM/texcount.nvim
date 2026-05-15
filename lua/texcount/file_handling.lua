local M = {}

---@type {[string]: boolean}
local ignored_words = nil

---@return string
M.get_ignored_file = function()
	local local_file = vim.fn.getcwd() .. "/ignore.txt"
	local file_exists = vim.fn.filereadable(local_file)

	if file_exists == 1 then
		return local_file
	end

	local fallback_file = vim.fn.stdpath("data") .. "/ignore.txt"
	return fallback_file
end

---@return {[string]: boolean}
M.get_ignored_words = function()
	if ignored_words then
		return ignored_words
	end

	local file_path = M.get_ignored_file()
	ignored_words = {}

	for line in io.lines(file_path) do
		local word = line:match("^%s*(.-)%s*$")

		if word and word ~= "" then
			ignored_words[word] = true
		end
	end

	return ignored_words
end

---@return string | nil
M.ensure_local_file = function()
	local local_file = vim.fn.getcwd() .. "/ignore.txt"
	if vim.fn.filereadable(local_file) == 1 then
		return local_file
	end

	local fallback = vim.fn.stdpath("data") .. "/ignore.txt"
	local fallback_file = io.open(fallback, "r")
	local content = fallback_file and fallback_file:read("*a") or ""
	if fallback_file then
		fallback_file:close()
	end
	local new_file = io.open(local_file, "w")
	if not new_file then
		vim.notify("TexCount: Failed to create local ignore file.", vim.log.levels.ERROR)
		return nil
	end

	new_file:write(content)
	new_file:close()

	return local_file
end

---@param local_file string
function M.write_ignore_words(local_file)
	local file = io.open(local_file, "w")
	if not file then
		vim.notify("TexCount: Failed to open ignore file for writing.", vim.log.levels.ERROR)
		return false
	end

	for word, _ in pairs(ignored_words) do
		file:write(word .. "\n")
	end
	file:close()
	return true
end

M.add_word_to_ignore = function()
	M.get_ignored_words()

	local word = vim.fn.expand("<cword>")
	if not word then
		return
	end

	if ignored_words[word] then
		vim.notify("TexCount: '" .. word .. "' is already being ignored.", vim.log.levels.WARN)
		return
	end

	local local_file = M.ensure_local_file()
	if not local_file then
		return
	end
	ignored_words[word] = true

	local file = io.open(local_file, "a")

	if not file then
		vim.notify("TexCount: Failed to open ignore file for writing.", vim.log.levels.ERROR)
		return
	end
	file:write(word .. "\n")
	file:close()
	vim.notify("TexCount: Added '" .. word .. "' to ignore list.", vim.log.levels.INFO)
end

M.delete_word_from_ignore = function()
	M.get_ignored_words()

	local word = vim.fn.expand("<cword>")
	if not word then
		return
	end
	if not ignored_words[word] then
		vim.notify("TexCount: '" .. word .. "' is not in ignore list.", vim.log.levels.WARN)
		return
	end

	local local_file = M.ensure_local_file()
	if not local_file then
		return
	end
	ignored_words[word] = nil

	if M.write_ignore_words(local_file) then
		vim.notify("TexCount: Removed '" .. word .. "' from ignore list.", vim.log.levels.INFO)
	end
end

return M
