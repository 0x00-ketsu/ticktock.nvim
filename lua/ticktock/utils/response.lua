local M = {}

---Send success message to client
---
---@param message string
M.success = function(message)
  vim.notify(message)
end

---Send failed message to client
---
---@param message string
M.failed = function(message)
  vim.notify(message, vim.log.levels.ERROR)
end

return M
