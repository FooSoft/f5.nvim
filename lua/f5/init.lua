local Options = {}

local function setup(config)
    Options = vim.tbl_deep_extend('force', Options, config)
end

return {
    setup = setup,
}
