local api = vim.api

local fmt = require('ticktock.utils.fmt')
local config = require('ticktock.config')
local buffer = require('ticktock.utils.buf')
local task_repo = require('ticktock.repository.task')

---@class Menu
---@field order table 'Ordered list of submenu names'
---@field items table 'Detail of sub menus'
---@field default string 'default selected menu'
---@field winnr number 'Window handle'
---@field bufnr number 'Buffer handle'
---@field bufname string 'Buffer name'
---@field task_view Task 'task view instance'
local Menu = {
  default = 'todo',
  order = {'todo', 'completed', 'trash'}, -- lower string
  items = {
    todo = {icon = '📝', text = 'Todo', hl_group = ''},
    completed = {icon = '✅', text = 'Completed', hl_group = 'TicktockCompleted'},
    trash = {icon = '🚮', text = 'Trash', hl_group = 'TicktockDeleted'}
  }
}

local uid_counter = 1

---Create a new Menu
---
---@param opts? table
---@return Menu
Menu.create = function(opts)
  opts = opts or {}

  vim.cmd('below new')
  local pos = {left = 'H', right = 'L'}
  vim.cmd('wincmd ' .. (pos[config.opts.view.menu.position] or 'H'))

  local view = Menu:new(opts)
  view:setup(opts)

  return view
end

---Menu class
---
---@param opts? table
---@return Menu
function Menu:new(opts)
  opts = opts or {}

  local winnr = opts.winnr or api.nvim_get_current_win()
  local bufnr = api.nvim_get_current_buf()
  vim.g.tt_menu_bufnr = bufnr
  local this = {
    winnr = winnr,
    bufnr = bufnr,
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
function Menu:setup(opts)
  opts = opts or {}

  local options = config.opts.view.menu
  api.nvim_win_set_width(self.winnr, options.width)

  local bufname = string.format('ticktock:/menu/%d', Menu.next_uid())
  local ok = pcall(api.nvim_buf_set_name, self.bufnr, bufname)
  if not ok then
    buffer.wipe_named_buffer(bufname)
    api.nvim_buf_set_name(self.bufnr, bufname)
  end

  -- setup buffer
  self:set_option('filetype', 'ticktock')
  self:set_option('buftype', 'nofile')
  self:set_option('bufhidden', 'wipe')
  self:set_option('swapfile', false)
  self:set_option('buflisted', false)

  -- setup window
  self:set_option('fcs', 'eob: ', true)
  self:set_option('wrap', false, true)
  self:set_option('spell', false, true)
  self:set_option('list', false, true)
  self:set_option('number', false, true)
  self:set_option('relativenumber', false, true)
  self:set_option('colorcolumn', '', true)
  self:set_option('signcolumn', 'no', true)
  self:set_option('winfixwidth', true, true)
  self:set_option('winfixheight', true, true)
  self:set_option('statusline', '[ticktock]', true)

  buffer.unlock(self.bufnr)
  Menu.load(self.bufnr)
  buffer.lock(self.bufnr)

  -- Binding keymaps
  local options = config.opts
  local key_bindings = options.view.menu.keys
  for action, keys in pairs(key_bindings) do
    if type(keys) == 'string' then
      keys = {keys}
    end

    for _, key in pairs(keys) do
      api.nvim_buf_set_keymap(
          self.bufnr, 'n', key,
              [[<cmd>lua require('ticktock').menu_do_action(']] .. action .. [[')<cr>]],
              {silent = true, noremap = true, nowait = true}
      )
    end
  end
end

---Do action
---
---@param action string
function Menu:do_action(action)
  local selected_menu = self:get_selected_menu()
  vim.t.tt_select_menu = selected_menu
  self.task_view.filter = selected_menu

  if action == 'preview' then
    self:preview()
  elseif action == 'open' then
    self:open()
  end
end

---@package
function Menu:open()
  self.task_view:load_tasks()
  if self.task_view then
    Menu.switch_to(self.task_view.winnr, self.task_view.bufnr)
  end
end

---@package
function Menu:preview()
  self.task_view:load_tasks()
end

---@package
---Get current selected menu name
---
---@return string
function Menu:get_selected_menu()
  local curline = api.nvim_get_current_line()
  local name = curline:match('%a+')
  return string.lower(name)
end

---@package
function Menu:is_valid()
  return api.nvim_buf_is_valid(self.bufnr) and api.nvim_buf_is_loaded(self.bufnr)
end

---@package
---Set option for window or buffer
---
---@param name string
---@param value any
---@param win? boolean
function Menu:set_option(name, value, win)
  if win then
    api.nvim_win_set_option(self.winnr, name, value)
  else
    api.nvim_buf_set_option(self.bufnr, name, value)
  end
end

---Load menu view
---
---@param bufnr integer
Menu.load = function(bufnr)
  vim.g.tt_todo_count = task_repo.get_todo_task_count()

  -- render menus
  local menus = {}
  local start_lineno = 0
  local hl_lineno, hl_groups = start_lineno, {}
  for _, name in ipairs(Menu.order) do
    local item = Menu.items[name]
    -- menu
    local menu = ''
    if name == 'todo' and vim.g.tt_todo_count then
      menu = string.format('%s %s (%d)', item.icon, item.text, vim.g.tt_todo_count)
    else
      menu = string.format('%s %s', item.icon, item.text)
    end
    table.insert(menus, menu)

    -- highlight
    if #item.hl_group > 0 then
      local hl = {line = hl_lineno, group = item.hl_group}
      table.insert(hl_groups, hl)
    end
    hl_lineno = hl_lineno + 1
  end
  Menu.set_lines(bufnr, menus, start_lineno)

  -- highlight submenus
  for _, hl in ipairs(hl_groups) do
    api.nvim_buf_add_highlight(bufnr, config.ns, hl.group, hl.line, 0, -1)
  end
end

---Reload menu view
---
---@param bufnr integer
Menu.reload = function(bufnr)
  buffer.unlock(bufnr)
  Menu.set_lines(bufnr, {}, 0)
  Menu.load(bufnr)
  buffer.lock(bufnr)
end

---Switch to specific window & buffer
---
---@param winnr integer
---@param bufnr integer
Menu.switch_to = function(winnr, bufnr)
  if winnr and api.nvim_win_is_valid(winnr) then
    api.nvim_set_current_win(winnr)
    if bufnr and api.nvim_buf_is_valid(bufnr) then
      api.nvim_win_set_buf(winnr, bufnr)
    end
  end
end

---Return next uid
---
---@return integer
Menu.next_uid = function()
  local uid = uid_counter
  uid_counter = uid_counter + 1

  return uid
end

---Get highlight group of specific menu name.
---
---@param target string 'menu name'
---@return string
Menu.get_hl_group = function(target)
  if #target < 1 then
    return ''
  end

  local submenus = Menu.items
  for name, detail in pairs(submenus) do
    if name == target then
      return detail.hl_group
    end
  end

  return ''
end

---Set (replace) a line-range in the menu buffer.
---
---@param bufnr integer
---@param lines table
---@param first? number
---@param last? number
---@param strict? boolean
Menu.set_lines = function(bufnr, lines, first, last, strict)
  first = first or 0
  last = last or -1
  strict = strict or false
  return api.nvim_buf_set_lines(bufnr, first, last, strict, lines)
end

return Menu
