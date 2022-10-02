local api = vim.api

local config = require('ticktock.config')
local constants = require('ticktock.views.constants')
local buffer = require('ticktock.utils.buf')
local util = require('ticktock.utils.util')

---@class MenuView
---@field winnr integer 'Window number'
---@field bufnr integer 'Buffer number'
---@field bufname string 'Buffer name'
---@field task_view TaskView 'task view instance'
local View = {}

local uid_counter = 0

---Create a new menu View
---
---@param opts? table
---@return MenuView
View.create = function(opts)
  opts = opts or {}

  vim.cmd('below new')
  local pos = {left = 'H', right = 'L'}
  vim.cmd('wincmd ' .. (pos[config.opts.view.menu.position] or 'H'))

  local view = View:new(opts)
  view:setup(opts)

  return view
end

---MenuView class
---
---@param opts? table
---@return MenuView
function View:new(opts)
  opts = opts or {}

  local this = {
    winnr = opts.winnr or vim.api.nvim_get_current_win(),
    bufnr = vim.api.nvim_get_current_buf(),
    bufname = opts.bufname or 'menu',
    task_view = opts.task_view
  }
  setmetatable(this, self)
  self.__index = self
  return this
end

---Setup
---
---@param opts? table
function View:setup(opts)
  opts = opts or {}

  local options = config.opts.view.menu
  vim.api.nvim_win_set_width(self.winnr, options.width)

  bufname = string.format('ticktock:///views/%d/%s', View.next_uid(), self.bufname)
  local ok = pcall(api.nvim_buf_set_name, self.bufnr, bufname)
  if not ok then
    buffer.wipe_named_buffer(bufname)
    api.nvim_buf_set_name(self.bufnr, bufname)
  end

  -- set options
  vim.cmd('setlocal nonu')
  vim.cmd('setlocal nornu')
  vim.cmd('setlocal colorcolumn=""')
  vim.cmd("set statusline=[ticktock]")

  self:set_option('filetype', config.plugin_name)
  self:set_option('buftype', 'nofile')
  self:set_option('bufhidden', 'wipe')
  self:set_option('swapfile', false)
  self:set_option('buflisted', false)
  self:set_option('winfixwidth', true, true)
  self:set_option('wrap', false, true)
  self:set_option('spell', false, true)
  self:set_option('list', false, true)
  self:set_option('winfixheight', true, true)
  self:set_option('signcolumn', 'no', true)
  self:set_option('fcs', 'eob: ', true)

  local menus = {}
  table.insert(menus, constants.TODO_MENU)
  table.insert(menus, constants.COMPLETED_MENU)
  table.insert(menus, constants.TRASH_MENU)
  api.nvim_buf_set_lines(self.bufnr, 0, -1, false, menus)

  -- Highlight line
  api.nvim_buf_add_highlight(self.bufnr, config.namespace, 'TicktockCompleted', 1, 0, -1)
  api.nvim_buf_add_highlight(self.bufnr, config.namespace, 'TicktockDeleted', 2, 0, -1)

  -- Binding keymaps
  local options = config.opts
  local key_bindings = options.key_bindings.menu
  for action, keys in pairs(key_bindings) do
    if type(keys) == 'string' then
      keys = {keys}
    end

    for _, key in pairs(keys) do
      vim.api.nvim_buf_set_keymap(
          self.bufnr, 'n', key,
              [[<cmd>lua require('ticktock').do_menu_action(']] .. action .. [[')<cr>]],
              {silent = true, noremap = true, nowait = true}
      )
    end
  end

  self:lock()
end

---Do action
---
---@param action string
function View:do_action(action)
  local selected_menu = self:get_selected_menu()
  vim.t.tt_selected_menu = selected_menu
  self.task_view.filter = constants.MENU_CHOICES[selected_menu]

  if action == 'preview' then
    self:preview()
  elseif action == 'open' then
    self:open()
  end
end

function View:preview()
  self.task_view:load_tasks()
end

function View:open()
  self.task_view:load_tasks()
  if self.task_view then
    View.switch_to(self.task_view.winnr, self.task_view.bufnr)
  end
end

---Get current selected menu name
---
---@return string
function View:get_selected_menu()
  return api.nvim_get_current_line()
end

function View:is_valid()
  return api.nvim_buf_is_valid(self.bufnr) and api.nvim_buf_is_loaded(self.bufnr)
end

---@param lines table
---@param first? integer
---@param last? integer
---@param strict? boolean
function View:set_lines(lines, first, last, strict)
  first = first or 0
  last = last or -1
  strict = strict or false
  return api.nvim_buf_set_lines(self.bufnr, first, last, strict, lines)
end

---Lock View
---
function View:lock()
  buffer.lock_buf(self.bufnr)
end

---Unlock View
---
function View:unlock()
  buffer.unlock_buf(self.bufnr)
end

---Set option for window or buffer
---
---@param name string
---@param value any
---@param win? boolean
function View:set_option(name, value, win)
  if win then
    api.nvim_win_set_option(self.winnr, name, value)
  else
    api.nvim_buf_set_option(self.bufnr, name, value)
  end
end

---Switch to specific window & buffer
---
---@param winnr integer
---@param bufnr integer
View.switch_to = function(winnr, bufnr)
  if winnr and api.nvim_win_is_valid(winnr) then
    vim.api.nvim_set_current_win(winnr)
    if bufnr and api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_win_set_buf(winnr, bufnr)
    end
  end
end

---Return next uid
---
---@return integer
View.next_uid = function()
  local uid = uid_counter
  uid_counter = uid_counter + 1

  return uid
end

return View
