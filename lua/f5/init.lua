local Options = {
    enabled = true,
    reload_files = false,
    reload_modules = true,
}

local function build_module_names(path)
    local module_path = ('/' .. path):match('/lua/(.+)%.lua$')
    local module_names = {}
    if module_path then
        local module_name
        for part in module_path:gmatch('[^/]+') do
            module_name = module_name and (module_name .. '.' .. part) or part
            table.insert(module_names, module_name)
        end
    end

    return module_names
end

local function normalize_path(path)
    path = vim.fn.fnamemodify(path, ':p')
    if vim.fn.has('win32') == 1 then
        path = path:gsub('\\', '/')
    end
    return path:gsub('/+$', '')
end

local function relative_path(path, root)
    local prefix = root .. '/'
    local candidate = path
    if vim.fn.has('win32') == 1 then
        candidate, prefix = candidate:lower(), prefix:lower()
    end
    if candidate:sub(1, #prefix) == prefix then
        return path:sub(#prefix + 1)
    end
end

local M = {}

function M.setup(config)
    Options = vim.tbl_deep_extend('force', Options, config or {})
end

function M.toggle()
    Options.enabled = not Options.enabled
    vim.notify(Options.enabled and 'F5 enabled' or 'F5 disabled')
end

function M.on_write(path)
    if not Options.enabled then
        return
    end

    path = normalize_path(path)
    local config_path = normalize_path(vim.fn.stdpath('config'))
    local realpath = (vim.uv or vim.loop).fs_realpath
    local relative = relative_path(path, config_path)
        or relative_path(
            normalize_path(realpath(path) or path),
            normalize_path(realpath(config_path) or config_path)
        )
    if not relative then
        return
    end

    if Options.reload_modules then
        for _, module_name in ipairs(build_module_names(relative)) do
            package.loaded[module_name] = nil
        end
    end

    if Options.reload_files then
        dofile(path)
    end
end

return M
