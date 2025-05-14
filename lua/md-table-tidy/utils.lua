local M = {}

---@param array table
---@param first integer
---@param last integer
---@return table
function M.slice(array, first, last)
  local result = {}
  for i = first or 1, last or #array do
    result[#result + 1] = array[i]
  end
  return result
end

---@param array table
---@param key string
---@return table
function M.pluck(array, key)
  local result = {}
  for i, value in ipairs(array) do
    result[i] = value[key]
  end
  return result
end

---@param array table
---@param fn function
---@return table
function M.map(array, fn)
  local result = {}
  for i, value in ipairs(array) do
    result[i] = fn(value, i)
  end
  return result
end

---@param str string
---@param delim string
---@return table
function M.split(str, delim)
  local result = {}
  local pattern = "([^" .. delim .. "]+)"
  for match in string.gmatch(str, pattern) do
    table.insert(result, match)
  end
  return result
end

return M
