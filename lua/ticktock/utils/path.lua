local vl = vim.loop

local M = {}

---Get current system path separator
---
---@return string
M.sep = (function()
  if jit then
    local os = string.lower(jit.os)
    if os == "linux" or os == "osx" or os == "bsd" then
      return "/"
    else
      return "\\"
    end
  else
    return package.config:sub(1, 1)
  end
end)()

---Check filepath is exists.
---
---@param filepath string
---@return boolean
M.exists = function(filepath)
  return M.fs_stat(filepath).exists and true or false
end

---Return file path state (exists, is_directory).
---
---@param filepath string
---@return table
M.fs_stat = function(filepath)
  local stat = vl.fs_stat(filepath)
  return {
    exists = stat and true or false,
    is_directory = (stat and stat.type == 'directory') and true or false
  }
end

---Return `true` if filepath is directory else `false`.
---
---@param filepath string
---@return boolean
M.is_dir = function(filepath)
  local stat = M.fs_stat(filepath)
  return stat.is_directory
end

---Return parent path of input file absoulte path.
---
---@return function(abs_path) string
M.get_parent_dir = (function()
  local formatted = string.format("^(.+)%s[^%s]+", M.sep, M.sep)
  return function(abs_path)
    return abs_path:match(formatted)
  end
end)()

---Return file(s) & dir(s) under specific dir_path.
---
---@param dir_path string
---@return table?
M.scandir = function(dir_path)
  local pipe = io.popen('ls ' .. dir_path)
  if not pipe then
    return nil
  end

  local filenames = {}
  pipe:flush()
  for filename in pipe:lines() do
    table.insert(filenames, filename)
  end
  pipe:close()

  return filenames
end

return M
