if vim.g.f5_loaded then
    return
else
    vim.g.f5_loaded = true
end

local function on_write(event)
    require('f5').on_write(event.match)
end

local function toggle()
    require('f5').toggle()
end

vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.lua',
    callback = on_write
})

vim.api.nvim_create_user_command('F5', toggle, {})
