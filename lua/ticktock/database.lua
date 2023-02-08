local sqlite = require('sqlite')
local path = require('ticktock.utils.path')
local notify = require('ticktock.utils.notify')

local M = {}

---Create db file, if failed return error message.
---
---@return boolean is_success
---@return string errmsg
M.initial_dbfile = function()
  local filename = 'db.sqlite3'
  local db_dir = os.getenv('HOME') .. path.sep .. '.ticktock'
  local db_path = db_dir .. path.sep .. filename
  if path.exists(db_path) then
    vim.g.tt_dbfile = db_path
    return true, ''
  end

  local result = vim.fn.mkdir(db_dir, 'p')
  if result ~= 1 then
    return false, 'Ticktock initial db file failed.'
  end

  fp, err = io.open(db_path, 'w')
  if fp ~= nil then
    vim.g.tt_dbfile = db_path
    fp:close()
    return true, ''
  end

  return false, 'Ticktock initial db file failed.'
end

---Build a connection with SQLite.
---
---Do not forget to close connection! `conn:close()`.
---
---@return table? 'database connection handle'
M.connect = function()
  local dbfile = vim.g.tt_dbfile
  if dbfile == nil or not path.fs_stat(dbfile) then
    notify.error('Ticktock db file is not exists!')
    return nil
  end

  local conn = sqlite.new(dbfile, {keep_open = true})
  if conn == nil then
    notify.error('Connect to db file failed!')
    return nil
  end

  return conn
end

return M
