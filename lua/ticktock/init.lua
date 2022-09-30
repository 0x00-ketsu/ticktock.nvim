local api = vim.api

local config = require('ticktock.config')
local Menu = require('ticktock.views.menu')
local Task = require('ticktock.views.task')

---@class MenuView
local menu
---@class TaskView
local task

local Ticktock = {}

Ticktock.setup = function(opts)
  config.setup(opts)
end

Ticktock.open = function(opts)
  opts = opts or {}
  -- New tabpage
  api.nvim_command('tabe ' .. config.plugin_name)

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
