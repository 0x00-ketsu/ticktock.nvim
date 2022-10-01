local api = vim.api

local buffer = require('ticktock.utils.buf')
local config = require('ticktock.config')
local constants = require('ticktock.views.constants')
local tbl = require('ticktock.utils.tbl')
local repo = require('ticktock.db.task')
local vutils = require('ticktock.views.utils')
local window = require('ticktock.window.init')
local response = require('ticktock.utils.response')
local util = require('ticktock.utils.util')

---@class TaskView
---@field winnr integer 'Window number'
---@field bufnr integer 'Buffer number'
---@field bufname string 'Buffer name'
---@field filter string 'Menu View selected item'
---@field hover_winnr integer 'Window number of task detail'
---@field edit_winnr integer 'Window number of edit task'
---@field edit_task_id number 'Edit task ID'
---@field tasks Task[] 'task records, sequence like Task declared'
local View = {}

local uid_counter = 0

---Create a new task View
---
---@param opts? table
---@return TaskView
View.create = function(opts)
  opts = opts or {}

  local view = View:new(opts)
  view:setup(opts)

  return view
end

---TaskView class
---
---@param opts? table
---@return TaskView
function View:new(opts)
  opts = opts or {}

  local this = {
    winnr = opts.winnr,
    bufnr = opts.bufnr,
    bufname = opts.bufname or 'tasks',
    filter = opts.filter or 'todo'
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
  vim.cmd("set statusline=[tasks]")

  self:set_option('filetype', 'markdown')
  self:set_option('bufhidden', 'wipe')
  self:set_option('buftype', 'nofile')
  self:set_option('swapfile', false)
  self:set_option('buflisted', false)
  self:set_option('winfixwidth', true, true)
  self:set_option('wrap', false, true)
  self:set_option('spell', false, true)
  self:set_option('list', false, true)
  self:set_option('winfixheight', true, true)
  self:set_option('signcolumn', 'no', true)
  self:set_option('fcs', 'eob: ', true)

  vim.api.nvim_exec(
      [[
        augroup TicktockTask
            autocmd! * <buffer>
            autocmd CursorMoved <buffer> lua require("ticktock").do_task_action("close_hover")
        augroup END
    ]], false
  )

  -- Binding keymaps
  local options = config.opts
  local key_bindings = options.key_bindings.task
  for action, keys in pairs(key_bindings) do
    if type(keys) == 'string' then
      keys = {keys}
    end

    -- Except binding `save` action
    if action ~= 'save' then
      for _, key in pairs(keys) do
        if key ~= 'save' then
          vim.api.nvim_buf_set_keymap(
              self.bufnr, 'n', key,
                  [[<cmd>lua require('ticktock').do_task_action(']] .. action .. [[')<cr>]],
                  {silent = true, noremap = true, nowait = true}
          )
        end
      end
    end
  end

  self:lock()
end

---Reload tasks fillup Task View
---
function View:refresh()
  self:load_tasks()
end

---Load tasks fillup Task View
---
function View:load_tasks()
  self:unlock()
  self:clear()

  local items = {}
  local tasks = self:get_tasks()
  for _, task in pairs(tasks) do
    local id = tonumber(task[1], 10)
    local title = task[2]
    table.insert(items, id .. '# ' .. title)
  end
  api.nvim_buf_set_lines(self.bufnr, 0, -1, false, items)

  -- Highlight line for different menu(s)
  local hl_group = ''
  hl_group = constants.HL_GROUP_CHOICES[self.filter]
  for idx, _ in pairs(tasks) do
    if hl_group and #hl_group > 0 then
      api.nvim_buf_add_highlight(self.bufnr, config.namespace, hl_group, idx - 1, 0, -1)
    end
  end

  self:lock()
end

---Return tasks (id, title)
---
---@return table
function View:get_tasks()
  local tasks = {}

  local sql = vutils.convert_menu_to_sql(self.filter)
  local result = repo.execute_raw_sql(sql)

  if type(result) ~= 'nil' then
    tasks = tbl.tbl_zip(result['id'], result['title'])
  end

  return tasks
end

---Get current select task detail
---
---@return table | nil
function View:get_task_detail()
  local task_id, _ = self:get_task_line()
  return repo.detail(task_id)
end

---Get current select task ID
---Return 0 if parse task ID failed
---
---@return number, string
function View:get_task_line()
  local line = api.nvim_get_current_line()
  ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
  local item = vim.split(line, '#')
  local task_id, title = item[1], item[2]

  return tonumber(task_id, 10), title
end

---Do action
---
---@param action string
function View:do_action(action)
  if action == 'refresh' then
    self:refresh()
  elseif action == 'create' then
    self:create_task()
  elseif action == 'save' then
    self:save_task()
  elseif action == 'edit' then
    self:edit_task()
  elseif action == 'complete' then
    self:complete_task()
  elseif action == 'delete' then
    self:delete_task()
  elseif action == 'hover_detail' then
    self:hover_detail()
  elseif action == 'close_hover' then
    self:close_hover_window()
  end
end

---Create a new task
---
function View:create_task()
  vim.ui.input(
      {prompt = 'Enter Todo name: '}, function(title)
        local ok, msg = self:validate_title(title)
        if not ok then
          response.failed(msg)
          return
        end

        local ok, msg = repo.create(title, '')
        if not ok then
          response.failed('Create task failed: ' .. msg)
        else
          response.success('Create task success')
        end
      end
  )

  self:refresh()
end

---Preview Task
---
function View:hover_detail()
  self:close_edit_window()

  local _, lines, win_opts = self:get_render_win_data(true)
  local winnr = window.new(false, win_opts)
  local bufnr = api.nvim_win_get_buf(winnr)

  self.hover_winnr = winnr

  api.nvim_win_set_option(winnr, 'cursorline', true)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  View.highlight_title(bufnr)
  buffer.lock_buf(bufnr)
end

---Show task edition Window
---
function View:edit_task()
  self:close_hover_window()

  local task_id, lines, win_opts = self:get_render_win_data(false)
  -- Expand window width & height
  win_opts.width = win_opts.width + 20
  win_opts.height = win_opts.height + 5

  local winnr = window.new(true, win_opts)
  local bufnr = api.nvim_win_get_buf(winnr)

  self.edit_winnr = winnr
  self.edit_task_id = task_id
  self:set_keymap_for_save_task()

  api.nvim_win_set_option(winnr, 'cursorline', true)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  View.highlight_title(bufnr)
end

---Save updated task used together with `edit_task()`
function View:save_task()
  local bufnr = api.nvim_win_get_buf(self.edit_winnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local lines_count = vim.tbl_count(lines)
  if lines_count < 1 then
    return
  end

  local updated_title, contents = '', {}
  updated_title = lines[1]
  local ok, msg = self:validate_title(updated_title)
  if not ok then
    response.failed(msg)
    return
  end

  for i = 2, lines_count, 1 do
    table.insert(contents, lines[i])
  end

  if not contents then
    updated_content = ''
  else
    updated_content = table.concat(contents, '\\n')
  end

  local ok, msg = repo.update(self.edit_task_id, {title = updated_title, content = updated_content})
  if not ok then
    response.failed(msg)
    return
  end

  response.success('Update todo success')
  self:refresh()
end

---Mark current selected task as completed
---
function View:complete_task()
  local task_id, title = self:get_task_line()
  local ok, msg = repo.complete(task_id)
  if not ok then
    response.failed(msg)
    return
  end

  response.success('Complete todo: ' .. title)
  self:refresh()
end

---Mark current selected task as deleted
---
function View:delete_task()
  local task_id, title = self:get_task_line()
  local ok, msg = repo.delete(task_id)
  if not ok then
    response.failed(msg)
    return
  end

  response.success('Delete todo: ' .. title)
  self:refresh()
end

---Close `hover_detail` window
---
function View:close_hover_window()
  if self.hover_winnr and api.nvim_win_is_valid(self.hover_winnr) then
    api.nvim_win_close(self.hover_winnr, true)
  end
end

---Validation for task title
---
---@param title string
---@return boolean valid
---@return string message
function View:validate_title(title)
  local t_len = #title
  if t_len < 3 then
    return false, 'Todo name should be at least 3 characters.'
  elseif t_len > 100 then
    return false, 'Todo name should be at less than 100 characters.\nTry write to content.'
  end

  return true, ''
end

---Close 'edit_task' window
---
function View:close_edit_window()
  if self.edit_winnr and api.nvim_win_is_valid(self.edit_winnr) then
    api.nvim_win_close(self.edit_winnr, true)
  end
end

---Clean tasks in Task View
---
function View:clear()
  return api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {})
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

---Deal with current selected task and format task data
---
---@param is_add_sep_line boolean 'default is false'
---@return number 'task ID'
---@return table 'lines for nvim_buf_set_lines()'
---@return table 'window width & height'
function View:get_render_win_data(is_add_sep_line)
  is_add_sep_line = is_add_sep_line or false

  local task_id, _ = self:get_task_line()
  local detail = repo.detail(task_id)
  if not detail then
    return task_id, {}, {}
  end

  local lines = {}
  local title = detail['title'][1]
  local content = detail['content'][1]

  local win_width = #title
  -- seperate `\n` to new line
  ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
  local contents = vim.split(content, '\\n')
  for _, line in pairs(contents) do
    win_width = math.max(win_width, #line)
  end

  -- fillup lines
  table.insert(lines, title)
  if is_add_sep_line then
    table.insert(lines, string.rep('-', win_width))
  end
  for _, line in pairs(contents) do
    if #line > 0 then
      table.insert(lines, line)
    end
  end

  return task_id, lines, {width = win_width, height = vim.tbl_count(lines)}
end

---Get keymap of `save` task
---
function View:set_keymap_for_save_task()
  local options = config.opts
  local key_bindings = options.key_bindings.task
  for action, keys in pairs(key_bindings) do
    if type(keys) == 'string' then
      keys = {keys}
    end

    if action == 'save' then
      local bufnr = api.nvim_win_get_buf(self.edit_winnr)
      for _, key in pairs(keys) do
        vim.api.nvim_buf_set_keymap(
            bufnr, 'n', key,
                [[<cmd>lua require('ticktock').do_task_action(']] .. action .. [[')<cr>]],
                {silent = true, noremap = true, nowait = true}
        )
      end
    end
  end
end

---Highlight title
---
---@param bufnr integer
View.highlight_title = function(bufnr)
  api.nvim_buf_add_highlight(bufnr, config.namespace, 'TicktockTitle', 0, 0, -1)
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
