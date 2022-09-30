local config = require('ticktock.config')

local table_name = config.global.table_name

---Return SQL of menu Todo
---
---@return string
local function generate_todo_sql()
  -- LuaFormatter off
  return "SELECT * FROM " .. table_name .. " WHERE is_completed=0 AND is_deleted=0 ORDER BY create_at DESC;"
  -- LuaFormatter on
end

---Return SQL of menu completed
---
---@return string
local function generate_completed_sql()
  -- LuaFormatter off
  return "SELECT * FROM " .. table_name .. " WHERE is_completed=1 AND is_deleted=0 ORDER BY create_at DESC;"
  -- LuaFormatter on
end

---Return SQL of menu trash
---
---@return string
local function generate_trash_sql()
  -- LuaFormatter off
  return "SELECT * FROM " .. table_name .. " WHERE is_deleted=1 ORDER BY create_at DESC;"
  -- LuaFormatter on
end

local M = {}

---Convert menu to task sql
---
---@param filter string
---@return string sql
M.convert_menu_to_sql = function(filter)
  local sql = ''
  if filter == 'todo' then
    sql = generate_todo_sql()
  elseif filter == 'completed' then
    sql = generate_completed_sql()
  elseif filter == 'trash' then
    sql = generate_trash_sql()
  end

  return sql
end

return M
