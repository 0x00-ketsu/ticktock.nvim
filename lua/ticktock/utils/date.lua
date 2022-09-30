local M = {}

---Return current time timestamp
---
---@return integer
M.get_current_timestamp = function()
  ---@diagnostic disable-next-line: param-type-mismatch
  return os.time(os.date("*t"))
end

return M
