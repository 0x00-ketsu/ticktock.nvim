local database = require('ticktock.database')
local config = require('ticktock.config')
local date = require('ticktock.utils.date')

local table_name = config.global.table.task

local M = {}

---Get todo task count
---Return -1 if failed
---
---@return number
M.get_todo_task_count = function()
  local db = database.connect()
  if db == nil then
    return 0
  end

  local where = {is_completed = 0, is_deleted = 0}
  local qs = M.select(where)
  return #qs
end

---Get task detail with ID
---
---@param id number
---@return table?
M.detail = function(id)
  local where = {id = id}
  local qs = M.select(where)
  if #qs > 0 then
    return qs[1]
  end

  return nil
end

---Create a new task
---
---@param title string
---@param content string
---@return boolean 'is insert success'
---@return integer 'the last inserted row id'
M.create = function(title, content)
  local db = database.connect()
  if db == nil then
    return false, -1
  end

  local timestamp = date.get_timestamp()
  local create_time = os.date('%Y-%m-%d %H:%M:%S')
  local row = {title = title, content = content, create_time = create_time, create_ts = timestamp}
  return db:insert(table_name, row)
end

---Mark a task as completed with id
---
---@param id number
---@return boolean success
M.complete = function(id)
  local where = {id = id}
  local set = {is_completed = 1}
  return M.update(where, set)
end

---Mark a task as deleted (soft delete) with id
---
---@param id number
---@return boolean success
M.delete = function(id)
  local where = {id = id}
  local set = {is_deleted = 1}
  return M.update(where, set)
end

---Update table row with where closure and list of values.
---Returns true incase the table was updated successfully.
---
---@param where table
---@param set table
---@return boolean
M.update = function(where, set)
  local db = database.connect()
  if db == nil then
    return false
  end

  local ok = db:update(table_name, {where = where, set = set})
  db:close()
  return ok
end

---Query from a table `tasks`.
---Return select result.
---
---@param where table
---@param order_by? table
---@return table[]
M.select = function(where, order_by)
  local db = database.connect()
  if db == nil then
    return {}
  end

  local spec = {where = where}
  if order_by then
    spec['order_by'] = order_by
  end

  local qs = db:select(table_name, spec)
  db:close()
  return qs
end

return M
