local Table = require "md-table-tidy.table"

---@class TableTidy.Parser
local Parser = {}
Parser.__index = Parser

---@param bufnr integer
---@param tbl_node TSNode
---@return TableTidy.Table
function Parser.parse(bufnr, tbl_node)
  local headers = {}
  local tbl = Table.new()
  tbl.range.from = tbl_node:range()
  for node in tbl_node:iter_children() do
    if node:type() == "ERROR" then
      error("Table parsing error", 0)
    end

    -- Parse header
    if node:type() == "pipe_table_header" then
      for cell_node in node:iter_children() do
        if cell_node:type() == "pipe_table_cell" then
          table.insert(headers, Parser._trim(vim.treesitter.get_node_text(cell_node, bufnr)))
        end
      end
    end

    -- Parse delimiter
    if node:type() == "pipe_table_delimiter_row" then
      for i, cell_node in ipairs(node:named_children()) do
        if cell_node:type() ~= "|" then
          -- using bitwise mask for calculate alignment
          -- default:00 right:01 left:10 center:11
          local align = Table.alignments.DEFAULT
          for delimiter_node in cell_node:iter_children() do
            if delimiter_node:type() == "pipe_table_align_left" then
              align = bit.bor(align, Table.alignments.LEFT)
            end
            if delimiter_node:type() == "pipe_table_align_right" then
              align = bit.bor(align, Table.alignments.RIGHT)
            end
          end
          tbl:add_column(headers[i], align)
        end
      end
    end

    -- Parse rows
    if node:type() == "pipe_table_row" and not string.find(vim.treesitter.get_node_text(node, bufnr), "^%s*|") then
      break
    end

    if node:type() == "pipe_table_row" then
      local row = {}
      for cell_node in node:iter_children() do
        if cell_node:type() == "pipe_table_cell" then
          table.insert(row, Parser._trim(vim.treesitter.get_node_text(cell_node, bufnr)))
        end
      end

      local success, err = pcall(tbl.add_row, tbl, row)
      if not success then
        error("Error in line " .. node:range() + 1 .. ". " .. err, 0)
      end
    end
    -- set table range (number of rows + heading + delimiter row)
    tbl.range.to = tbl.range.from + #tbl.rows + 2
  end
  return tbl
end

---@private
---@param str string
---@return string
function Parser._trim(str)
  return str:match "^%s*(.-)%s*$"
end

return Parser
