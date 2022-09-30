local config = require('ticktock.config')
local logger = require('ticktock.utils.logger')
local path = require('ticktock.utils.path')
local response = require('ticktock.utils.response')

local db_file = config.global.db_file

local ok, sqlite = pcall(require, 'ljsqlite3')
if not ok then
  response.failed("This plugin requires lua-ljsqlite3 (https://github.com/stepelu/lua-ljsqlite3)")
end

---Return true if table exist in sqlite else return false
---
---@param conn table 'sqlite connection'
---@param table_name string
---@return boolean exist
local function is_table_exist(conn, table_name)
  sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='" .. table_name .. "';"
  local result = conn:exec(sql)
  return type(result) ~= 'nil' and true or false
end

---Build a connection with SQLite
---If connection is success, try to initial table(s) if not exists
---
---Do not forget to close connection! `conn:close()`
---
---@param filepath string SQLite db file path
---@return boolean success
---@return table | nil db
local function connect_and_initial(filepath)
  if not path.fs_stat(filepath) then
    logger.warn('Ticktock db file is not exists, auto create it.')
  end

  conn = sqlite.open(filepath)
  if not conn then
    logger.error('Ticktock build connection to db file failed.')
    return false, nil
  end

  -- Create table(s) if not exist
  local table_name = config.global.table_name
  if not is_table_exist(conn, table_name) then
    logger.warn('table: ' .. table_name .. ' not exist, auto create table')
    local fields = {
      'id INTEGER PRIMARY KEY AUTOINCREMENT', 'title TEXT NOT NULL', 'content TEXT',
      'create_time TEXT', 'create_at INTEGER', 'is_completed INTEGER DEFAULT 0',
      'is_deleted INTEGER DEFAULT 0'
    }
    sql = 'CREATE TABLE ' .. table_name .. ' (' .. table.concat(fields, ',') .. ')'
    conn:exec(sql)
  end

  return true, conn
end

local M = {}

---Execute sql statement
---Return execute result
---
---@param sql string
---@return table | nil
M.execute = function(sql)
  ok, conn = connect_and_initial(db_file)
  if not ok then
    return nil
  end

  local result = conn:exec(sql)
  conn:close()

  return result
end

return M
