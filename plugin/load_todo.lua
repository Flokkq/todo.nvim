vim.api.nvim_create_user_command("TodoOpen", function()
	require("todo").open()
end, {
    desc = 'Open nearest TODO.md in floating window',
})

vim.keymap.set("n", "<leader>to", "<Cmd>TodoOpen<CR>", {
    silent = true,
    noremap = true,
    desc = 'Open nearest TODO.md in floating window',
})
