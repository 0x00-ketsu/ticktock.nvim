local defaults = {
  view = {
    menu = {
      position = 'left', -- one of 'left', 'right'
      width = 35,
      keys = {
        open = {'o', '<CR>'}, -- open and swith to Task View
        preview = 'p' -- preview Task View
        -- next = 'j', -- next item
        -- previous = 'k' -- preview item
      }
    },
    task = {
      keys = {
        create = 'n', -- create new task
        edit = 'e', -- edit task
        complete = 'gc', -- complete task
        delete = 'gd', -- delete task
        refresh = 'r', -- refresh task list
        hover = 'K' -- show task detail in float window
      }
    }
  }
}

local M = {plugin_name = 'ticktock.nvim'}
M.ns = vim.api.nvim_create_namespace(M.plugin_name)

---Assign default options
---
---@param opts table
M.setup = function(opts)
  M.global = {
    table = {
      task = 'tasks' -- table name of Task
    }
  }
  ---@diagnostic disable-next-line: param-type-mismatch
  M.opts = vim.tbl_deep_extend('force', {}, defaults, opts or {})

  -- register highlight
  require('ticktock.highlight')
end

M.setup {}

return M
