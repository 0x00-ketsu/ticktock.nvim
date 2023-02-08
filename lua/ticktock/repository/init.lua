local notify = require('ticktock.utils.notify')
local database = require('ticktock.database')

---Create table `tasks`, ignore if table is exists.
---
---@param db table 'database connection handle'
local function create_table_tasks(db)
  if not db:exists('tasks') then
    db:create(
        'tasks', {
          id = {'integer', 'primary', 'key', 'autoincrement'},
          title = 'text',
          content = 'text',
          is_completed = {type = 'integer', default = 0},
          is_deleted = {type = 'integer', default = 0},
          create_time = 'text',
          create_ts = 'integer'
        }
    )
  end
end

local M = {}

---Auto create tables if not exists.
---
M.migrate = function()
  local db = database.connect()
  if db == nil then
    notify.error('Connect to sqlite failed.')
    return
  end

  create_table_tasks(db)

  db:close()
end

M.migrate()
