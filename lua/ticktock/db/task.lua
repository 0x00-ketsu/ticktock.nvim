local db = require('ticktock.db.init')
local config = require('ticktock.config')
local logger = require('ticktock.utils.logger')
local date = require('ticktock.utils.date')

local table_name = config.global.table_name

---@class Task
---@field title string
---@field content string
---@field is_completed integer
---@field is_deleted integer

local TASK_FIELDS = {
  ['id'] = 'number',
  ['title'] = 'string',
  ['content'] = 'string',
  ['is_completed'] = 'number',
  ['is_deleted'] = 'number',
}

local M = {}

---Search tasks
---Rule:
---     select from field `title` and `content`
---
---@param text string
---@return table | nil
M.search = function(text)
  local sql = "SELECT * FROM " .. table_name .. " WHERE title like %" .. text ..
                  "% OR content like %" .. text .. "%;"
  return M.execute_raw_sql(sql)
end

---Get uncomplete task count
---Return -1 if failed
---
---@return number
M.get_uncomplete_task_count = function()
  local sql = "SELECT COUNT(id) as cnt FROM " .. table_name .. " WHERE is_completed = 0 AND is_deleted = 0;"
  local result = M.execute_raw_sql(sql)

  if type(result) ~= 'nil' then
    local uncomplete_count = result['cnt'][1]
    return tonumber(uncomplete_count, 10)
  end

  return -1
end

---Get task detail with ID
---Return all fields, sequence ref to `@class Task`
---
---@param id number
---@return table | nil
M.detail = function(id)
  local sql = "SELECT * FROM " .. table_name .. " WHERE id = " .. id .. ";"
  return M.execute_raw_sql(sql)
end

---Create a new task
---
---@param title string
---@param content string
---@return boolean success
---@return string message
M.create = function(title, content)
  local timestamp = date.get_current_timestamp()
  local create_time = os.date('%Y-%m-%d %H:%M:%S')
  local sql =
      "INSERT INTO " .. table_name .. " (title, content, create_time, create_at) VALUES('" .. title ..
          "', '" .. content .. "', '" .. create_time .. "', " .. timestamp .. ");"
  local result = M.execute_raw_sql(sql)

  if type(result) == 'nil' then
    return true, ''
  else
    logger.error("create new task failed, title: " .. title .. " content: " .. content)
    return false, 'insert failed'
  end
end

---Update task status with id
---If id in param t, ignore the id (in t)
---
---@param id integer
---@param fields table 'key: field, value: updated field value'
---@return boolean success
---@return string message
M.update = function(id, fields)
  local update_fields = {}
  for field, value in pairs(fields) do
    if not M.is_correct_field_and_value(field, value) then
      return false, 'field name or value is uncorrect'
    end

    if type(value) == 'string' then
      table.insert(update_fields, " '" .. tostring(field) .. "' = '" .. value .. "'")
    else
      table.insert(update_fields, " '" .. tostring(field) .. "' = " .. value .. "")
    end
  end

  local sql = "UPDATE " .. table_name .. " SET " .. table.concat(update_fields, ',') .. " WHERE id = " .. id .. ";"
  M.execute_raw_sql(sql)

  return true, ''
end

---Mark a task as completed with id
---
---@param id number
---@return boolean success
---@return string message
M.complete = function(id)
  if type(id) == 'number' and id > 0 then
    return M.update_field(id, 'is_completed', 1)
  else
    local msg = 'complete task with invalid param `id`: ' .. id
    logger.error(msg)
    return false, msg
  end
end

---Mark a task as deleted (soft delete) with id
---
---@param id number
---@return boolean success
---@return string message
M.delete = function(id)
  if type(id) == 'number' and id > 0 then
    return M.update_field(id, 'is_deleted', 1)
  else
    local msg = 'delete task with invalid param `id`: ' .. id
    logger.error(msg)
    return false, msg
  end
end

---Update task with specific field
---
---@param id integer 'Task ID'
---@param name string 'field name'
---@param value any 'field value'
---@return boolean success
---@return string message
M.update_field = function(id, name, value)
  if not M.is_correct_field_and_value(name, value) then
    return false, 'invalid field name: ' .. name
  end

  local sql = ''
  -- LuaFormatter off
  if type(value) == 'string' then
    sql = "UPDATE " .. table_name .. " SET " .. name .. " = '" .. value .. "' WHERE id = " .. id .. ";"
  else
    sql = "UPDATE " .. table_name .. " SET " .. name .. " = " .. value .. " WHERE id = " .. id .. ";"
  end
  -- LuaFormatter on
  M.execute_raw_sql(sql)

  return true, ''
end

---Check if field name and field value is correct
---Rules:
---     field name: exist in table
---     field value: match type with field
---
---@param name string
---@param value any
---@return boolean
M.is_correct_field_and_value = function(name, value)
  if not M.is_valid_field(name) then
    logger.error("table field: " .. tostring(name) .. " is not a valid field")
    return false
  end

  if type(value) ~= TASK_FIELDS[name] then
    logger.error(
        "table field: " .. tostring(name) .. " with value: " .. tostring(value) .. " is not correct"
    )
    return false
  end

  return true
end

---Return true if `field_name` is an correct field name in table
---
---@param field_name string
---@return boolean
M.is_valid_field = function(field_name)
  ---@diagnostic disable-next-line: param-type-mismatch
  return vim.tbl_contains(vim.tbl_keys(TASK_FIELDS), field_name)
end

---Execute sql statement
---If execute `insert`, `update` statement, result nil is success
---
---@param sql string
---@return table | nil
M.execute_raw_sql = function(sql)
  local ok, result = pcall(db.execute, sql)
  if not ok or not result then
    if type(result) == 'string' then
      logger.error(result)
      return nil
    end
  end

  return result
end

return M
