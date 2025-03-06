local Options = {}

local function setup(config)
    Options = vim.tbl_deep_extend('force', Options, config)
end

local function on_write(path)
    for name, _ in pairs(package.loaded) do
        if vim.startswith(name, 'f5') then
            package.loaded[name] = nil
        end
    end
end

return {
    on_write = on_write,
    setup = setup,
}
