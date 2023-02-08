local api = vim.api

local M = {}

---Close the tabpage (close windows belongs tabpage).
---
---@param tabpage number 'Tabpage handle, or 0 for current tabpage'
---@param force boolean 'Behave like `:close!`' for window
M.close_tabpage = function (tabpage, force)
  if tabpage == nil or not api.nvim_tabpage_is_valid(tabpage) then
    return
  end

  for _, winnr in ipairs(api.nvim_tabpage_list_wins(tabpage)) do
    if api.nvim_win_is_valid(winnr) then
      api.nvim_win_close(winnr, force)
    end
  end
end

return M
