if vim.g.f5_loaded then
    return
end
vim.g.f5_loaded = true

vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.lua',
    callback = function(event)
        require('f5').on_write(event.match)
    end,
})

vim.api.nvim_create_user_command(
    'F5',
    function()
        require('f5').toggle()
    end,
    {}
)
