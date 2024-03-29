local M = {}

---Pretty print.
---
---@param list any
---@param level? integer
---@param is_filter? boolean
M.pretty_print = function(list, level, is_filter)
  if type(list) ~= 'table' then
    print(list)
    return
  end

  is_filter = is_filter or true
  level = level or 1

  local indent_str = ''
  for _ = 1, level do
    indent_str = indent_str .. '  '
  end

  print(indent_str .. '{')
  for k, v in pairs(list) do
    if is_filter then
      if k ~= '_class_type' and k ~= 'delete_me' then
        local item_str = string.format('%s%s = %s', indent_str .. ' ', tostring(k), tostring(v))
        print(item_str)
        if type(v) == 'table' then
          M.pretty_print(v, level + 1)
        end
      end
    else
      local item_str = string.format('%s%s = %s', indent_str .. ' ', tostring(k), tostring(v))
      print(item_str)
      if type(v) == 'table' then
        M.pretty_print(v, level + 1)
      end
    end
  end
  print(indent_str .. '}')
end

return M
