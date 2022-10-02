local api = vim.api

local config = require('ticktock.config')
local response = require('ticktock.utils.response')
local Menu = require('ticktock.views.menu')
local Task = require('ticktock.views.task')
local constants = require('ticktock.views.constants')

---@class MenuView
local menu
---@class TaskView
local task

---Do some validations before program running
---
---@return boolean valid
---@return string message
local function pre_validate()
  -- validate file format
  local fileformat = vim.bo.fileformat
  local accept_fileformats = {'unix', 'mac'}
  ---@diagnostic disable-next-line: param-type-mismatch
  if not vim.tbl_contains(accept_fileformats, fileformat) then
    return false, 'Ticktock is only work under Linux or Mac.'
  end

  return true, ''
end

local Ticktock = {}

Ticktock.setup = function(opts)
  config.setup(opts)
end

Ticktock.open = function(opts)
  opts = opts or {}

  local ok, msg = pre_validate()
  if not ok then
    response.failed(msg)
    return
  end

  -- New tabpage
  api.nvim_command('tabe ' .. config.plugin_name)
  vim.t.is_ticktock = true

  -- Default selected menu
  vim.t.tt_selected_menu = constants.TODO_MENU

  -- Task View
  task = Task.create({winnr = api.nvim_get_current_win(), bufnr = api.nvim_get_current_buf()})
  task:load_tasks()
  opts.task_view = task

  -- Menu View
  menu = Menu.create(opts)
end

---Menu action
---
---@param action string
Ticktock.do_menu_action = function(action)
  menu:do_action(action)
end

---Task action
---
---@param action string
Ticktock.do_task_action = function(action)
  task:do_action(action)
end

return Ticktock
