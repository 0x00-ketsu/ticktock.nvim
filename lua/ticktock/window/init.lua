local api = vim.api

---Calculate window `anchor`
---
---@param width integer
---@param height integer
---@return string
local function decide_anchor(width, height)
  local row = vim.fn.winline() > vim.fn.winheight(0) - height and 'S' or 'N'
  local col = vim.fn.wincol() > vim.fn.winwidth(0) - width and 'E' or 'W'

  return row .. col
end

local M = {}

---Create a new float window
---
---@param enter_win? boolean 'default is false'
---@param opts? table
---@return integer 'window handler'
M.new = function(enter_win, opts)
  opts = opts or {}
  enter_win = enter_win or false

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  local win_width = opts.width or 30
  local win_height = opts.height or 5
  local opts = {
    style = opts.style or 'minimal',
    relative = opts.style or 'cursor',
    anchor = decide_anchor(win_width, win_height),
    width = win_width,
    height = win_height,
    row = 1,
    col = 0,
    border = 'rounded'
  }

  local win = api.nvim_open_win(buf, enter_win, opts)

  return win
end

return M
