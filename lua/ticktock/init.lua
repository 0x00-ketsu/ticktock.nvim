local api = vim.api

local tab = require('ticktock.utils.tab')
local config = require('ticktock.config')
local database = require('ticktock.database')
local notify = require('ticktock.utils.notify')
local validator = require('ticktock.utils.validator')

local menu = require('ticktock.views.menu')
local task = require('ticktock.views.task')

---@class Global 'Plugin declared global variables'
---@field vim.g.tt_todo_count number 'Count of todo task(s)'
---@field vim.g.tt_dbfile string 'Path of sqlite3 db file'
---@field vim.g.tt_tabnr number 'Tabpage handle of ticktock'
---@field vim.g.tt_menu_bufnr number 'Buffer handle of ticktock menu view'

---@class Tabpage 'Plugin declared tabpage-scoped variables'
---@field vim.t.tt_select_menu 'Current selected menu'

---@type Menu
local menu_view
---@type Task
local task_view

local M = {}

M.setup = function(opts)
  config.setup(opts)

  -- validate
  local ok, errmsg = validator.inspect()
  if not ok then
    notify.error(errmsg)
    return
  end

  -- initial config.global
  local ok, errmsg = database.initial_dbfile()
  if ok then
    require('ticktock.repository.init')
  else
    notify.error(errmsg)
    return
  end
end

M.open = function(opts)
  opts = opts or {}

  -- New tabpage
  api.nvim_command('tabe ' .. config.plugin_name)
  vim.g.tt_tabnr = api.nvim_get_current_tabpage()

  -- Default selected menu
  vim.t.tt_select_menu = menu.default

  -- Task View
  local task_winnr = api.nvim_get_current_win()
  local task_bufnr = api.nvim_get_current_buf()
  vim.g.tt_task_winnr = task_winnr
  task_view = task.create({winnr = task_winnr, bufnr = task_bufnr})
  task_view:load_tasks()
  opts.task_view = task_view

  -- Menu View
  menu_view = menu.create(opts)
end

---Menu action
---
---@param action string
M.menu_do_action = function(action)
  menu_view:do_action(action)
end

---Task action
---
---@param action string
M.task_do_action = function(action)
  task_view:do_action(action)
end

M.close = function()
  tab.close_tabpage(vim.g.tt_tabnr, true)
end

return M
