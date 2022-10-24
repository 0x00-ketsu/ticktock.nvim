local M = {}

---Zip given tables like Python zip function
---
---@return table
M.tbl_zip = function(...)
  local idx, ret, args = 1, {}, {...}
  while true do -- loop smallest table-times
    local sub_t = {}
    for _, arg in ipairs(args) do
      value = arg[idx] -- becomes nil if index is out of range
      if value == nil then
        break
      end -- break for-loop
      table.insert(sub_t, value)
    end

    if value == nil then
      break
    end -- break while-loop

    table.insert(ret, sub_t) -- insert the sub result
    idx = idx + 1
  end

  return ret
end

---Return the index of value in table
---Retrun -1 if not exist
---
---@param list table
---@param value any
---@return number
M.tbl_get_index = function(list, value)
  for index, v in ipairs(list) do
    if v == value then
      return index
    end
  end

  return -1
end

---Remove duplicate elements in list, it's inplace
---
---@param list table
M.tbl_remove_duplicate = function(list)
  local seen = {}
  for index, item in ipairs(list) do
    if seen[item] then
      table.remove(list, index)
    else
      seen[item] = true
    end
  end

  list = seen
end

---Remove key (and its value) from table list
---Return a new table
---
---@param list table
---#param key any
---@return table
M.tbl_remove_key = function(list, key)
  local i = 0
  local keys, values = {}, {}
  for k, v in pairs(list) do
    i = i + 1
    keys[i] = k
    values[i] = v
  end

  while i > 0 do
    if keys[i] == key then
      table.remove(keys, i)
      table.remove(values, i)
      break
    end
    i = i - 1
  end

  local t = {}
  for i = 1, #keys do
    t[keys[i]] = values[i]
  end

  return t
end

return M
