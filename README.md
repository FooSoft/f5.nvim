# F5

This plugin streamlines Neovim plugin development by hot-reloading Lua scripts when they are saved to disk. Only scripts residing in the standard-path `config` location are considered for reload. The `config` directory is typically the root for both Neovim configuration scripts and plugins, allowing F5 to be used for both.

## Configuration

The plugin is configured via the `setup` function. Options may be provided to change the default settings shown below.

```lua
require('f5').setup({
    enabled = true,
    reload_files = false,
    reload_modules = true,
})
```
#### `enabled`

Specifies whether or not the plugin is enabled by default.

#### `reload_files`

Specifies if Lua scripts should be reloaded via `dofile` when changed. You should only set this to `true` if you trust the scripts you are editing.

#### `reload_modules`

Specifies if Lua modules should be cleared from `package.loaded` cache when changed. Note that this does not update any stored references to the module in scripts; users of the module must still call `require` to fetch the updated version.

## Commands

Commands have no keyboard bindings by default. Specify your own mappings as needed.

#### `F5`

Toggles the enabled state of the plugin.
