local TsUtils = require "nvim-treesitter.ts_utils"
local Table = require "md-table-tidy.table"

---@class TableTidy.Parser
local Parser = {}
Parser.__index = Parser

---@return TableTidy.Table
function Parser.parse()
  local bufnr = vim.api.nvim_get_current_buf()
  local tblNode = Parser.closest "pipe_table"
  local headers = {}
  if tblNode then
    local tbl = Table:new()
    tbl.range.from = tblNode:range()
    for node in tblNode:iter_children() do
      if node:type() == "ERROR" then
        error("Table parsing error", 0)
      end

      -- Parse header
      if node:type() == "pipe_table_header" then
        for cellNode in node:iter_children() do
          if cellNode:type() == "pipe_table_cell" then
            table.insert(headers, Parser.trim(vim.treesitter.get_node_text(cellNode, bufnr)))
          end
        end
      end

      -- Parse delimiter
      if node:type() == "pipe_table_delimiter_row" then
        for i, cellNode in ipairs(node:named_children()) do
          if cellNode:type() ~= "|" then
            -- using bitwise mask for calculate alignment
            -- default:00 right:01 left:10 center:11
            local align = Table.alignments.DEFAULT
            for delimiterNode in cellNode:iter_children() do
              if delimiterNode:type() == "pipe_table_align_left" then
                align = bit.bor(align, Table.alignments.LEFT)
              end
              if delimiterNode:type() == "pipe_table_align_right" then
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
        for cellNode in node:iter_children() do
          if cellNode:type() == "pipe_table_cell" then
            table.insert(row, Parser.trim(vim.treesitter.get_node_text(cellNode, bufnr)))
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
  error("Table under cursor not found", 0)
end

---@private
---@param str string
---@return string
function Parser.trim(str)
  return str:match "^%s*(.-)%s*$"
end

---@private
---@param targetType string
---@return TSNode|nil
function Parser.closest(targetType)
  local tree = vim.treesitter.get_parser()
  if tree then
    tree:parse()
  end
  local node = TsUtils.get_node_at_cursor()
  while node do
    if node:type() == targetType then
      return node
    end
    -- in treesitter markdown grammar nodes with type (inline) are special and always has root level
    -- https://github.com/tree-sitter-grammars/tree-sitter-markdown/issues/74
    if node:type() == "inline" then
      ---@diagnostic disable-next-line
      node = tree:named_node_for_range { node:range() }
    end
    if node then
      node = node:parent()
    end
  end
  return nil
end

return Parser
