local api = vim.api
local fn = vim.fn

local M = {}

---@class BufSpec
---@field loaded boolean Filter out buffers that aren't loaded.
---@field listed boolean Filter out buffers that aren't listed.
---@field no_hidden boolean Filter out buffers that are hidden.
---@field tabpage integer Filter out buffers that are not displayed in a given tabpage.

---@param opts? BufSpec
---@return table bufnrs
M.list_bufs = function(opts)
  opts = opts or {}

  local bufnrs
  if opts.no_hidden or opts.tabpage then
    local wins = opts.tabpage and api.nvim_tabpage_list_wins(opts.tabpage) or api.nvim_list_wins()
    local bufnr
    local seen = {}
    bufnrs = {}
    for _, winnr in pairs(wins) do
      bufnr = api.nvim_win_get_buf(winnr)
      if not seen[bufnr] then
        bufnrs[#bufnrs + 1] = bufnr
      end
      seen[bufnr] = true
    end
  else
    bufnrs = api.nvim_list_bufs()
  end

  return vim.tbl_filter(
      function(bufnr)
        if opts.loaded and not api.nvim_buf_is_loaded(bufnr) then
          return false
        end

        if opts.listed and not vim.bo[bufnr].buflisted then
          return false
        end

        return true
      end, bufnrs
  )
end

---@param name string
---@param opts? BufSpec
---@return number?
M.find_named_buffer = function(name, opts)
  for _, bufnr in ipairs(M.list_bufs(opts)) do
    if fn.bufname(bufnr) == name then
      return bufnr
    end
  end

  return nil
end

---@param name string
---@param opts? BufSpec
M.wipe_named_buffer = function(name, opts)
  local bufnr = M.find_named_buffer(name, opts)
  if bufnr then
    api.nvim_buf_set_name(bufnr, '')

    for _, winnr in pairs(fn.win_findbuf(bufnr)) do
      api.nvim_win_close(winnr, true)
    end

    vim.schedule(
        function()
          pcall(api.nvim_buf_delete, bufnr, {})
        end
    )
  end
end

---Lock buffer.
---
---@param bufnr number
M.lock = function(bufnr)
  api.nvim_buf_set_option(bufnr, 'readonly', true)
  api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

---Unlock buffer
---
---@param bufnr number
M.unlock = function(bufnr)
  api.nvim_buf_set_option(bufnr, 'modifiable', true)
  api.nvim_buf_set_option(bufnr, 'readonly', false)
end

return M
