local uv = vim.uv or vim.loop
local project = vim.fn.getcwd()
local temp = vim.fn.tempname()
vim.env.XDG_CONFIG_HOME = temp .. '/config'
vim.env.NVIM_APPNAME = 'nvim'
local config = vim.fn.stdpath('config')
vim.fn.mkdir(config .. '/lua', 'p')
vim.opt.runtimepath:prepend(project)
vim.opt.runtimepath:prepend(config)

local function write(path, contents)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
    vim.fn.writefile({ contents or 'return {}' }, path)
    return path
end

local count = 0
local function test(name, run)
    local f5 = require('f5')
    f5.setup({ enabled = true, reload_files = false, reload_modules = true })
    run(f5)
    count = count + 1
    print('ok - ' .. name)
end

local function check_cleared(f5, path, names)
    for _, name in ipairs(names) do
        package.loaded[name] = {}
    end
    package.loaded.f5_test_unrelated = {}
    f5.on_write(path)
    for _, name in ipairs(names) do
        assert(package.loaded[name] == nil, name .. ' remains cached')
    end
    assert(package.loaded.f5_test_unrelated ~= nil)
end

local ok, err = xpcall(function()
    test('setup accepts omitted options and preserves existing settings', function(f5)
        f5.setup({ enabled = false })
        f5.setup()
        package.loaded.f5_test = true
        f5.on_write(write(config .. '/lua/f5_test.lua'))
        assert(package.loaded.f5_test == true)
    end)

    test('ordinary modules load their new contents after a save', function(f5)
        local path = write(config .. '/lua/f5_test.lua', 'return 1')
        package.loaded.f5_test = nil
        assert(require('f5_test') == 1)
        write(path, 'return 2')
        f5.on_write(path)
        assert(require('f5_test') == 2)
    end)

    test('nested modules and their parents are cleared', function(f5)
        check_cleared(f5, write(config .. '/lua/f5_test/child.lua'),
            { 'f5_test', 'f5_test.child' })
    end)

    test('init modules clear both require names', function(f5)
        check_cleared(f5, write(config .. '/lua/f5_test/init.lua'),
            { 'f5_test', 'f5_test.init' })
    end)

    test('a nested lua directory remains part of the module name', function(f5)
        check_cleared(f5, write(config .. '/lua/f5_test/lua/child.lua'),
            { 'f5_test', 'f5_test.lua', 'f5_test.lua.child' })
    end)

    test('package plugins are supported', function(f5)
        check_cleared(f5, write(config .. '/pack/plugins/start/example/lua/f5_test.lua'),
            { 'f5_test' })
    end)

    test('a sibling config directory is ignored', function(f5)
        f5.setup({ reload_files = true })
        package.loaded.f5_test = true
        f5.on_write(write(config .. '-backup/lua/f5_test.lua', 'error("must not execute")'))
        assert(package.loaded.f5_test == true)
    end)

    test('files outside lua directories do not clear modules', function(f5)
        package.loaded.f5_test = true
        f5.on_write(write(config .. '/plugin/f5_test.lua'))
        assert(package.loaded.f5_test == true)
    end)

    test('cache clearing can be disabled', function(f5)
        f5.setup({ reload_modules = false })
        package.loaded.f5_test = true
        f5.on_write(config .. '/lua/f5_test.lua')
        assert(package.loaded.f5_test == true)
    end)

    test('file execution sees the refreshed module cache', function(f5)
        local path = write(config .. '/lua/f5_test.lua',
            '_G.f5_test_seen = package.loaded.f5_test; return {}')
        package.loaded.f5_test = true
        f5.setup({ reload_files = true })
        f5.on_write(path)
        assert(_G.f5_test_seen == nil)
    end)

    test('file execution works with cache clearing disabled', function(f5)
        f5.setup({ reload_files = true, reload_modules = false })
        _G.f5_test_ran = false
        f5.on_write(write(config .. '/init.lua', '_G.f5_test_ran = true'))
        assert(_G.f5_test_ran)
    end)

    if vim.fn.has('win32') == 0 then
        test('symlinked config supports logical and physical paths', function(f5)
            local physical = temp .. '/physical'
            assert(uv.fs_rename(config, physical))
            assert(uv.fs_symlink(physical, config))
            check_cleared(f5, config .. '/lua/f5_test.lua', { 'f5_test' })
            check_cleared(f5, physical .. '/lua/f5_test.lua', { 'f5_test' })
        end)

        test('files linked into config keep their logical module names', function(f5)
            local external = write(temp .. '/external.lua')
            local linked = config .. '/lua/f5_test_link.lua'
            assert(uv.fs_symlink(external, linked))
            check_cleared(f5, linked, { 'f5_test_link' })
        end)
    end

    test('plugin registration is idempotent and save events reload modules', function(f5)
        dofile(project .. '/plugin/f5.lua')
        dofile(project .. '/plugin/f5.lua')
        local path = write(config .. '/lua/f5_test.lua')
        package.loaded.f5_test = true
        vim.api.nvim_exec_autocmds('BufWritePost', { pattern = path })
        assert(package.loaded.f5_test == nil)
        vim.cmd('F5')
        package.loaded.f5_test = true
        vim.api.nvim_exec_autocmds('BufWritePost', { pattern = path })
        assert(package.loaded.f5_test == true)
        vim.cmd('F5')
        vim.api.nvim_exec_autocmds('BufWritePost', { pattern = path })
        assert(package.loaded.f5_test == nil)
    end)
end, debug.traceback)

vim.fn.delete(temp, 'rf')
if not ok then
    io.stderr:write(err .. '\n')
    vim.cmd('cquit 1')
else
    print(string.format('Passed %d tests', count))
    vim.cmd('qa!')
end
