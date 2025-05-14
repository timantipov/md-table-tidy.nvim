---@alias TableTidy.Table.Column {header:string, align:Table.Alignment, width:integer}
---@alias TableTidy.Table.Row string[]

---@class TableTidy.Table
---@field columns TableTidy.Table.Column[]
---@field rows TableTidy.Table.Row[]
---@field range {from:integer, to:integer}
local Table = {}
Table.__index = Table

---@enum Table.Alignment
Table.alignments = {
  DEFAULT = 0,
  RIGHT = 1,
  LEFT = 2,
  CENTER = 3,
}

---@return TableTidy.Table
function Table:new()
  return setmetatable({
    columns = {},
    header = {},
    rows = {},
    range = { from = 0, to = 0 },
  }, self)
end

---@param header string
---@param align Table.Alignment
---@param width? integer
function Table:add_column(header, align, width)
  header = header or ""
  table.insert(self.columns, {
    header = header or " ",
    align = align or Table.alignments.DEFAULT,
    width = width or vim.fn.strchars(header),
  })
end

---@param row TableTidy.Table.Row
function Table:add_row(row)
  if next(row) and #row ~= #self.columns then
    error("The number of cells does not match the number of columns.", 0)
  end
  for col, cell in ipairs(row) do
    self.columns[col].width = math.max(self.columns[col].width, vim.fn.strchars(cell))
  end
  table.insert(self.rows, row)
end

return Table
