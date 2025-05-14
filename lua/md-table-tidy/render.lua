local Utils = require("md-table-tidy.utils")
local Table = require("md-table-tidy.table")

---@class TableTidy.Renderer
---@field padding integer
local Render = {}
Render.__index = Render

---@param opts table<string, any>
---@return TableTidy.Renderer
function Render:new(opts)
  opts = vim.tbl_deep_extend("force", { padding = 1 }, opts or {})
  return setmetatable({
    tbl = nil,
    padding = opts.padding,
  }, self)
end

---@param tbl TableTidy.Table
---@return string[] #rendered markdown lines
function Render:render(tbl)
  self.tbl = tbl
  local lines = {}
  table.insert(lines, self:render_row(Utils.pluck(self.tbl.columns, "header")))
  table.insert(lines, self:render_delimiter())
  for _, row in ipairs(self.tbl.rows) do
    table.insert(lines, self:render_row(row))
  end
  return lines
end

---@private
---@param row TableTidy.Table.Row
---@return string
function Render:render_row(row)
  return self:wrap_cells(Utils.map(row, function(v, i)
    local width = self.tbl.columns[i].width - self.padding * 2
    return self:align_cell(v, width, self.tbl.columns[i].align)
  end))
end

---@private
---@return string
function Render:render_delimiter()
  return self:wrap_cells(Utils.map(self.tbl.columns, function(col, _)
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
---@param char? string character for fill space
---@return string
function Render:align_cell(str, width, align, char)
  local strlen = vim.fn.strchars(str)
  width = (width + self.padding * 2) or strlen
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
