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
    return self:align_cell(v, self.tbl.columns[i].width, self.tbl.columns[i].align)
  end))
end

---@private
---@return string
function Render:render_delimiter()
  return self:wrap_cells(Utils.map(self.tbl.columns, function(col, _)
    local aligment = self:align_cell("-", col.width, col.align, "-")
    if col.align == Table.alignments.LEFT then
      aligment = ":" .. string.sub(aligment, 2)
    end
    if col.align == Table.alignments.RIGHT then
      aligment = string.sub(aligment, 2) .. ":"
    end
    if col.align == Table.alignments.CENTER then
      aligment = ":" .. string.sub(aligment, 2, -2) .. ":"
    end
    return aligment
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
---@param char? string char for rep
---@return string
function Render:align_cell(str, width, align, char)
  width = (width + self.padding * 2) or 0
  align = align or Table.alignments.LEFT
  char = char or " "

  if char == " " then
    local padding = string.rep(" ", self.padding)
    str = padding .. str .. padding
  end

  if width < #str then
    width = #str
  end

  if align == Table.alignments.RIGHT then
    return string.rep(char, width - #str) .. str
  end

  if align == Table.alignments.CENTER then
    local left = string.rep(char, math.floor((width - #str) / 2))
    local right = left
    if #left * 2 + #str < width then
      right = left .. char
    end
    return left .. str .. right
  end
  return str .. string.rep(char, width - #str)
end

return Render
