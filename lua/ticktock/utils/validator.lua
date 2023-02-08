local fn = vim.fn

local config = require('ticktock.config')

local M = {}

---Pre validation.
---
---@return boolean is_ok
---@return string errmsg
M.inspect = function()
  local ok, errmsg = M.validate_os()
  if not ok then
    return false, errmsg
  end

  local ok, errmsg = M.validate_sqlite()
  if not ok then
    return false, errmsg
  end

  return true, ''
end

---Check current OS type is suit for run this plugin.
---
---@return boolean is_ok
---@return string errmsg
M.validate_os = function()
  -- validate file format
  local ff = vim.bo.fileformat
  local accept_ffs = {'unix', 'mac'}
  ---@diagnostic disable-next-line: param-type-mismatch
  if not vim.tbl_contains(accept_ffs, ff) then
    local errmsg = 'Plugin is only work under Linux or Mac.'
    return false, errmsg
  end

  return true, ''
end

---Check if plugin `sqlite.lua` is installed.
---
---@return boolean is_ok
---@return string errmsg
M.validate_sqlite = function()
  local ok, _ = pcall(require, 'sqlite')
  if not ok then
    -- LuaFormatter off
    local errmsg = config.plugin_name .. ': requires plugin: sqlite.lua (https://github.com/kkharji/sqlite.lua)'
    -- LuaFormatter on
    return false, errmsg
  end

  return true, ''
end

return M
