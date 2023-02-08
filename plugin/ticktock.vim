if exists("g:loaded_ticktock")
    finish
endif
let g:loaded_ticktock = 1

" Register commands
command! TTOpen lua require('ticktock').open()
command! TTClose lua require('ticktock').close()
