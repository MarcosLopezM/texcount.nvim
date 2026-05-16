if vim.g.loaded_texcount then
	return
end
vim.g.loaded_texcount = true

vim.api.nvim_create_user_command("TexCount", function(opts)
	local args = vim.split(opts.args, "%s+", { trimempty = true })
	require("texcount").run(args[1], args[2])
end, {
	nargs = "*",
	desc = "Run TexCount on the current file.",
})

vim.api.nvim_create_user_command("TexCountAddIgnore", function()
	require("texcount.file_handling").add_word_to_ignore()
end, {
	desc = "Add a word to the ignore list.",
})

vim.api.nvim_create_user_command("TexCountDeleteIgnore", function()
	require("texcount.file_handling").delete_word_from_ignore()
end, {
	desc = "Delete a word from the ignore list.",
})
