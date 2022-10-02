local pathlib = require('ticktock.utils.path')
local response = require('ticktock.utils.response')

local function define_highlights()
  vim.cmd("highlight TicktockTip ctermfg=159 guifg=#ff9966")
  vim.cmd("highlight TicktockTitle ctermfg=159 guifg=#fabd2f")
  vim.cmd("highlight TicktockCompleted ctermfg=159 guifg=#00FF00")
  vim.cmd("highlight TicktockDeleted ctermfg=159 guifg=#FF0000")
end

---Create db file and return path
---Return empty string if create failed
---
---@return string
local function initial_db_file()
  local filename = 'db.sqlite3'
  local db_dir = os.getenv('HOME') .. pathlib.sep .. '.ticktock'
  local db_path = db_dir .. pathlib.sep .. filename

  if pathlib.exists(filename) then
    return db_path
  end

  local result = vim.fn.mkdir(db_dir, 'p')
  if result ~= 1 then
    response.success('Initial create db path in: ~/.ticktock failed')
    return ''
  end

  return db_path
end

local global = {db_file = initial_db_file(), table_name = 'tasks'}
local defaults = {
  view = {
    menu = {
      position = 'left', -- one of 'left', 'right'
      width = 35
    },
    task = {}
  },
  -- Work under Normal mode
  key_bindings = {
    menu = {
      open = {'o', '<CR>'}, -- open and swith to Task View
      preview = 'go' -- preview Task View
      -- next = 'j', -- next item
      -- previous = 'k' -- preview item
    },
    task = {
      create = 'gn', -- create new task
      edit = 'ge', -- edit task
      complete = 'gc', -- complete task
      delete = 'gd', -- delete task
      refresh = 'gr', -- refresh task list
      hover_detail = 'K' -- show task detail in float window
    }
  }
}

local M = {plugin_name = 'ticktock'}
M.namespace = vim.api.nvim_create_namespace(M.plugin_name)

---Assign default options
---
---@param opts table
M.setup = function(opts)
  M.global = global
  ---@diagnostic disable-next-line: param-type-mismatch
  M.opts = vim.tbl_deep_extend('force', {}, defaults, opts or {})

  define_highlights()
end

M.setup {}

return M
