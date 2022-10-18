local config = require('ticktock.config')

local ok, notify = pcall(require, 'notify')

local M = {}

---Send success message to client
---
---@param message string
M.success = function(message)
  if ok then
    notify(message, 'info', {title = config.plugin_name})
  else
    vim.notify(message)
  end
end

---Send failed message to client
---
---@param message string
M.failed = function(message)
  if ok then
    notify(message, 'error', {title = config.plugin_name})
  else
    vim.notify(message, vim.log.levels.ERROR)
  end
end

return M
