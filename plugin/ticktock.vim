" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_ticktock")
    finish
endif
let g:loaded_ticktock = 1

" Defines a package path for Lua. This facilitates importing the
" Lua modules from the plugin's dependency directory.
let s:lua_rocks_deps_loc = expand("<sfile>:h:r") . "/../lua/ticktock/deps"
let s:sqlite_loc = s:lua_rocks_deps_loc . '/lua-?/init.lua'
exe "lua package.path = package.path .. ';" . s:sqlite_loc . "'"
