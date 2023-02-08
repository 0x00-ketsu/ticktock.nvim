local api = vim.api
local fn = vim.fn

local config = require('ticktock.config')
local menu = require('ticktock.views.menu')
local repo = require('ticktock.repository.task')

local buffer = require('ticktock.utils.buf')
local window = require('ticktock.utils.win')
local notify = require('ticktock.utils.notify')

---@class Task
---@field winnr integer 'Window number'
---@field bufnr integer 'Buffer number'
---@field bufname string 'Buffer name'
---@field filter string 'Menu View selected item'
---@field hover_winnr integer 'Window number of task detail'
---@field edit_winnr integer 'Window number of edit task'
---@field edit_task_id number 'Edit task ID'
---@field tasks Task[] 'task records, sequence like Task declared'
local Task = {}

local uid_counter = 1

---Create a new task View
---
---@param opts? table
---@return Task
Task.create = function(opts)
  opts = opts or {}
  local task = Task:new(opts)
  task:setup(opts)
  return task
end

---TaskView class
---
---@param opts? table
---@return Task
function Task:new(opts)
  opts = opts or {}

  local this = {
    winnr = opts.winnr,
    bufnr = opts.bufnr,
    bufname = opts.bufname or 'tasks',
    filter = opts.filter or menu.default
  }
  setmetatable(this, self)
  self.__index = self
  return this
end

---Setup
---
---@param opts? table
function Task:setup(opts)
  opts = opts or {}

  bufname = string.format('ticktock:/task/%d', Task.next_uid())
  local ok = pcall(api.nvim_buf_set_name, self.bufnr, bufname)
  if not ok then
    buffer.wipe_named_buffer(bufname)
    api.nvim_buf_set_name(self.bufnr, bufname)
  end

  -- buffer
  self:set_option('filetype', 'ticktock')
  self:set_option('bufhidden', 'wipe')
  self:set_option('buftype', 'nofile')
  self:set_option('swapfile', false)
  self:set_option('buflisted', false)

  -- window
  self:set_option('fcs', 'eob: ', true)
  self:set_option('wrap', false, true)
  self:set_option('spell', false, true)
  self:set_option('list', false, true)
  self:set_option('winfixwidth', true, true)
  self:set_option('winfixheight', true, true)
  self:set_option('number', false, true)
  self:set_option('relativenumber', false, true)
  self:set_option('colorcolumn', '', true)
  self:set_option('signcolumn', 'no', true)
  self:set_option('statusline', '[tasks]', true)

  vim.api.nvim_exec(
      [[
        aug TicktockTask
            au!
            au CursorMoved <buffer> lua require('ticktock').task_do_action('close_hover')
            au InsertLeave *.tt lua require('ticktock').task_do_action('save')
        aug END
    ]], false
  )

  -- Binding keymaps
  local options = config.opts
  local key_bindings = options.view.task.keys
  for action, keys in pairs(key_bindings) do
    if type(keys) == 'string' then
      keys = {keys}
    end

    for _, key in pairs(keys) do
      vim.api.nvim_buf_set_keymap(
          self.bufnr, 'n', key,
              [[<cmd>lua require('ticktock').task_do_action(']] .. action .. [[')<cr>]],
              {silent = true, noremap = true, nowait = true}
      )
    end
  end

  self:lock()
end

---Reload tasks fillup Task View
---
function Task:refresh()
  self:load_tasks()
end

---Load tasks fillup Task View
---
function Task:load_tasks()
  self:unlock()
  self:clear()

  local tasks = self:get_tasks()
  if #tasks == 0 then
    self:set_hints()
    self:lock()
    return
  end

  local lines = {}
  for _, task in pairs(tasks) do
    local line = string.format('%d# %s', task.id, task.title)
    table.insert(lines, line)
  end
  self:set_lines(lines)

  -- Highlight line for different menu(s)
  local hl_group = menu.get_hl_group(self.filter)
  for idx, _ in pairs(tasks) do
    if hl_group and #hl_group > 0 then
      api.nvim_buf_add_highlight(self.bufnr, config.ns, hl_group, idx - 1, 0, -1)
    end
  end
  self:lock()
end

---Return tasks (id, title)
---
---@return table
function Task:get_tasks()
  local filter = self.filter
  local where = {}
  local order_by = {desc = 'create_ts'}
  if filter == 'todo' then
    where = {is_completed = 0, is_deleted = 0}
  elseif filter == 'completed' then
    where = {is_completed = 1, is_deleted = 0}
  elseif filter == 'trash' then
    where = {is_deleted = 1}
  end

  return repo.select(where, order_by)
end

---Get current select task detail
---
---@return table?
function Task:get_task_detail()
  local task_id, _ = self:get_task_line()
  return repo.detail(task_id)
end

---Get current select task ID
---Return 0 if parse task ID failed
---
---@return number, string
function Task:get_task_line()
  local line = api.nvim_get_current_line()
  ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
  local item = vim.split(line, '# ')
  local task_id, title = item[1], item[2]

  return tonumber(task_id, 10), title
end

---Do action
---
---@param action string
function Task:do_action(action)
  local menu_bufnr = vim.g.tt_menu_bufnr
  if action == 'refresh' then
    self:refresh()
  elseif action == 'create' then
    self:create_task()
    menu.reload(menu_bufnr)
  elseif action == 'save' then
    self:save_task()
  elseif action == 'edit' then
    self:edit_task()
  elseif action == 'complete' then
    self:complete_task()
    menu.reload(menu_bufnr)
  elseif action == 'delete' then
    self:delete_task()
    menu.reload(menu_bufnr)
  elseif action == 'hover' then
    self:hover_task()
  elseif action == 'close_hover' then
    self:close_hover()
  end
end

---Create a new task
---
function Task:create_task()
  vim.ui.input(
      {prompt = 'Enter Todo name: '}, function(title)
        local ok, errmsg = self:validate_title(title)
        if not ok then
          notify.error(errmsg)
          return
        end

        local ok, errmsg = repo.create(title, '')
        if not ok then
          notify.error('Create todo item failed: ' .. errmsg)
        else
          notify.success('Create todo item success.')
        end
      end
  )

  print(' ')
  self:refresh()
end

---Preview Task
---
function Task:hover_task()
  self:close_edit()

  local _, lines, win_opts = self:get_render_win_data(true)
  local winnr = window.open_float_win(false, win_opts)
  local bufnr = api.nvim_win_get_buf(winnr)

  self.hover_winnr = winnr

  api.nvim_win_set_option(winnr, 'cursorline', true)
  api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
  api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')

  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  Task.highlight_title(bufnr)
  buffer.lock(bufnr)
end

---Show task edition Window
---
function Task:edit_task()
  self:close_hover()

  local task_id, lines, win_opts = self:get_render_win_data(false)

  -- Expand window width & height
  win_opts.width = win_opts.width + 20
  win_opts.height = win_opts.height + 5

  local winnr = window.open_float_win(true, win_opts)
  local bufnr = api.nvim_win_get_buf(winnr)

  self.edit_winnr = winnr
  self.edit_task_id = task_id

  api.nvim_win_set_option(winnr, 'cursorline', true)
  api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
  api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
  api.nvim_buf_set_name(bufnr, 'edit_task.tt')

  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  Task.highlight_title(bufnr)
end

---Save updated task used together with `edit_task()`
function Task:save_task()
  local bufnr = api.nvim_win_get_buf(self.edit_winnr)
  local updated_title = api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
  local ok, errmsg = self:validate_title(updated_title)
  if not ok then
    notify.error(errmsg)
    return
  end

  local contents = {}
  local lines = api.nvim_buf_get_lines(bufnr, 1, -1, false)
  for i = 1, #lines, 1 do
    table.insert(contents, lines[i])
  end

  local updated_content = ''
  if not contents then
    updated_content = ''
  else
    updated_content = table.concat(contents, '\\n')
  end

  local where = {id = self.edit_task_id}
  local set = {title = updated_title, content = updated_content}
  local ok = repo.update(where, set)
  if ok then
    notify.success('Update todo success.')
  else
    notify.error('Update todo failed.')
  end

  self:refresh()
end

---Mark current selected task as completed
---
function Task:complete_task()
  local task_id, title = self:get_task_line()
  local ok = repo.complete(task_id)
  if ok then
    notify.success('Complete todo: ' .. title .. ' success.')
  else
    notify.error('Complete todo: ' .. title .. ' failed.')
  end

  self:refresh()
end

---Mark current selected task as deleted
---
function Task:delete_task()
  local task_id, title = self:get_task_line()
  local ok = repo.delete(task_id)
  if ok then
    notify.success('Delete todo: ' .. title .. ' success.')
  else
    notify.success('Delete todo: ' .. title .. ' failed.')
  end

  self:refresh()
end

---Close `hover_detail` window
---
function Task:close_hover()
  if self.hover_winnr and api.nvim_win_is_valid(self.hover_winnr) then
    api.nvim_win_close(self.hover_winnr, true)
  end
end

---Validation for task title
---
---@param title string
---@return boolean valid
---@return string message
function Task:validate_title(title)
  if type(title) == 'nil' or #title < 3 then
    return false, 'Todo name should be at least 3 characters.'
  elseif #title > 100 then
    return false, 'Todo name should be at less than 100 characters.\nTry write to content.'
  end

  return true, ''
end

---Close 'edit_task' window
---
function Task:close_edit()
  if self.edit_winnr and api.nvim_win_is_valid(self.edit_winnr) then
    api.nvim_win_close(self.edit_winnr, true)
  end
end

---Render hint messages.
---
function Task:set_hints()
  local lines = {}
  local filter = self.filter
  if filter == 'todo' then
    local key_bindings = config.opts.view.task.keys
    local keymap_create_task = key_bindings.create
    lines = {'Have a nice day!', '', 'Press `' .. keymap_create_task .. '` to create a new task.'}
  elseif filter == 'completed' then
    lines = {'No completed task(s).'}
  elseif filter == 'trash' then
    lines = {'Tash is empty.'}
  end

  self:set_lines(lines)

  for i = 0, #lines, 1 do
    api.nvim_buf_add_highlight(self.bufnr, config.ns, 'TicktockHint', i, 0, -1)
  end
end

---Clear tasks in Task View
---
function Task:clear()
  self:set_lines({})
end

---@package
---Set (replace) a line-range in the task buffer.
---
---@param lines table
---@param first? number
---@param last? number
---@param strict? boolean
function Task:set_lines(lines, first, last, strict)
  first = first or 0
  last = last or -1
  strict = strict or false
  return api.nvim_buf_set_lines(self.bufnr, first, last, strict, lines)
end

---Lock View
---
function Task:lock()
  buffer.lock(self.bufnr)
end

---Unlock View
---
function Task:unlock()
  buffer.unlock(self.bufnr)
end

---Set option for window or buffer
---
---@param name string
---@param value any
---@param win? boolean
function Task:set_option(name, value, win)
  if win then
    api.nvim_win_set_option(self.winnr, name, value)
  else
    api.nvim_buf_set_option(self.bufnr, name, value)
  end
end

---Deal with current selected task and format task data
---
---@param is_add_sep_line boolean 'default is false'
---@return number 'task ID'
---@return table 'lines for nvim_buf_set_lines()'
---@return table 'window width & height'
function Task:get_render_win_data(is_add_sep_line)
  is_add_sep_line = is_add_sep_line or false

  local task_id, _ = self:get_task_line()
  local detail = repo.detail(task_id)
  if detail == nil then
    return task_id, {}, {}
  end

  local title = detail.title
  local content = detail.content

  local win_width = #title
  -- seperate `\n` to new line
  ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
  local contents = vim.split(content, '\\n')
  for _, line in pairs(contents) do
    win_width = math.max(win_width, #line)
  end

  -- fillup lines
  local lines = {}
  table.insert(lines, title)
  if is_add_sep_line then
    table.insert(lines, string.rep('-', win_width))
  end
  for _, line in pairs(contents) do
    if #line >= 0 then
      table.insert(lines, line)
    end
  end

  return task_id, lines, {width = win_width + 1, height = vim.tbl_count(lines)}
end

---Highlight title
---
---@param bufnr integer
Task.highlight_title = function(bufnr)
  api.nvim_buf_add_highlight(bufnr, config.ns, 'TicktockTitle', 0, 0, -1)
end

---Return next uid
---
---@return integer
Task.next_uid = function()
  local uid = uid_counter
  uid_counter = uid_counter + 1

  return uid
end

return Task
