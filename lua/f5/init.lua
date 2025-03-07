local Options = {
    reload_files = false,
    reload_modules = false,
}

local function setup(config)
    Options = vim.tbl_deep_extend('force', Options, config)
end

local function build_module_names(path)
    local path_parts = {}
    for part in path:gmatch('[^/\\]+') do
        table.insert(path_parts, part)
    end

    local module_name = nil
    local module_names = {}
    for i = #path_parts - 1, 1, -1 do
        local path_part = path_parts[i]
        if path_part == 'lua' then
            break
        end

        if module_name then
            module_name = module_name .. '.' .. path_part
        else
            module_name = path_part
        end

        table.insert(module_names, module_name)
    end

    return module_names
end

local function on_write(path)
    if not vim.startswith(path, vim.fn.stdpath('config')) then
        return
    end

    if Options.reload_files then
        dofile(path)
    end

    if Options.reload_modules then
        for _, module_name in ipairs(build_module_names(path)) do
            package.loaded[module_name] = nil
        end
    end
end

return {
    on_write = on_write,
    setup = setup,
}
