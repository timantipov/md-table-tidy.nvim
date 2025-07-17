local Utils = require "md-table-tidy.utils"
local Table = require "md-table-tidy.table"

---@class TableTidy.Renderer
---@field padding integer
local Render = {}
Render.__index = Render

---@param opts table<string, any>
---@return TableTidy.Renderer
function Render:new(opts)
  opts = vim.tbl_deep_extend("force", { padding = 0 }, opts or {})
  return setmetatable({
    padding = opts.padding,
  }, self)
end

---@param tbl TableTidy.Table
---@return string[] #rendered markdown lines
function Render:render(tbl)
  --> -, :- ,-: , :-:
  local min_widths = {
    [Table.alignments.DEFAULT] = 1,
    [Table.alignments.LEFT] = 2,
    [Table.alignments.RIGHT] = 2,
    [Table.alignments.CENTER] = 3,
  }

  -- fix width for narrow columns
  local columns = tbl.columns
  for i, col in ipairs(tbl.columns) do
    columns[i].width = math.max(min_widths[col.align] - self.padding * 2, col.width)
  end

  local lines = {}
  table.insert(lines, self:render_row(Utils.pluck(columns, "header"), columns))
  table.insert(lines, self:render_delimiter_row(columns))
  for _, row in ipairs(tbl.rows) do
    table.insert(lines, self:render_row(row, columns))
  end
  return lines
end

---@private
---@param row TableTidy.Table.Row
---@param columns TableTidy.Table.Column[]
---@return string
function Render:render_row(row, columns)
  return self:wrap_cells(Utils.map(row, function(v, i)
    return self:align_cell(v, columns[i].width, columns[i].align)
  end))
end

---@private
---@param columns TableTidy.Table.Column[]
---@return string
function Render:render_delimiter_row(columns)
  return self:wrap_cells(Utils.map(columns, function(col, _)
    local width = col.width + self.padding * 2
    if col.align == Table.alignments.LEFT then
      return ":" .. string.rep("-", width - 1)
    end
    if col.align == Table.alignments.RIGHT then
      return string.rep("-", width - 1) .. ":"
    end
    if col.align == Table.alignments.CENTER then
      return ":" .. string.rep("-", width - 2) .. ":"
    end
    return string.rep("-", width)
  end))
end

---@private
---@param row TableTidy.Table.Row
---@return string
function Render:wrap_cells(row)
  return "|" .. table.concat(row, "|") .. "|"
end

---@private
---@param str string
---@param width? integer
---@param align? Table.Alignment
---@param char? string filler
---@return string
function Render:align_cell(str, width, align, char)
  local strlen = vim.fn.strchars(str)
  align = align or Table.alignments.LEFT
  char = char or " "

  local padding = string.rep(char, self.padding)
  str = padding .. str .. padding

  if width < strlen then
    width = strlen
  end

  if align == Table.alignments.RIGHT then
    return string.rep(char, width - strlen) .. str
  end

  if align == Table.alignments.CENTER then
    local left = string.rep(char, math.ceil((width - strlen) / 2))
    local right = left
    if vim.fn.strchars(left) * 2 + strlen > width then
      right = string.sub(left, 2)
    end
    return left .. str .. right
  end

  return str .. string.rep(char, width - strlen)
end

return Render
