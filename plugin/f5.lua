if not vim.g.f5 then
    local on_write = function(event)
        require('f5').on_write(event.match)
    end

    vim.api.nvim_create_autocmd(
        'BufWritePost',
        {pattern = '*.lua', callback = on_write}
    )
end
