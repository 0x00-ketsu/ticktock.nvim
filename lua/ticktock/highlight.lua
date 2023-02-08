local M = {}

M.define = function()
  vim.cmd('highlight TicktockHint ctermfg=159 guifg=#ff9966')
  vim.cmd('highlight TicktockTitle ctermfg=159 guifg=#fabd2f')
  vim.cmd('highlight TicktockCompleted ctermfg=159 guifg=#00FF00')
  vim.cmd('highlight TicktockDeleted ctermfg=159 guifg=#FF0000')
end

M.define()
