local Options = {
    enabled = true,
    reload_files = false,
    reload_modules = true,
}

local function setup(config)
    Options = vim.tbl_deep_extend('force', Options, config)
end

local function toggle()
    Options.enabled = not Options.enabled
    if Options.enabled then
        vim.notify('F5 enabled')
    else
        vim.notify('F5 disabled')
    end
end

local function build_module_names(path)
    local path_parts = {}
    for path_part in path:gmatch('[^/\\]+') do
        table.insert(path_parts, path_part)
    end

    local path_start_index = nil
    for i = #path_parts - 1, 1, -1 do
        if path_parts[i]:lower() == 'lua' then
            path_start_index = i + 1
            break
        end
    end

    local module_names = {}
    if path_start_index then
        local module_name = nil
        for i = path_start_index, #path_parts do
            local path_part = path_parts[i]
            if not vim.endswith(path_part:lower(), '.lua') then
                if module_name then
                    module_name = module_name .. '.' .. path_part
                else
                    module_name = path_part
                end
                table.insert(module_names, module_name)
            end
        end
    end

    return module_names
end

local function on_write(path)
    if not Options.enabled then
        return
    end

    local config_path = vim.fn.stdpath('config')
    if vim.fn.getftype(config_path) == 'link' then
        config_path = vim.fn.resolve(config_path)
    end

    if not vim.startswith(path, config_path) then
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
    toggle = toggle,
}
