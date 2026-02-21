---@class TableTidy.Ast
---@field bufnr integer
---@field parser vim.treesitter.LanguageTree
local Ast = {}

Ast.__index = Ast

local QUERY_TABLES = vim.treesitter.query.parse("markdown", [[ (pipe_table) @table ]])

---@param bufnr integer?
---@return TableTidy.Ast
function Ast.new(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return setmetatable({
    bufnr = bufnr,
    parser = vim.treesitter.get_parser(bufnr, "markdown"),
  }, Ast)
end

---@private
---@return TSTree
function Ast:_get_tree()
  return self.parser:parse()[1]
end

---@return TSNode?
function Ast:get_closest_table_node(node)
  local tree = self:_get_tree()
  local root = tree:root()
  while node do
    if node:type() == "pipe_table" then
      return node
    end
    -- in treesitter markdown grammar nodes with type (inline) are special and always has root level
    -- https://github.com/tree-sitter-grammars/tree-sitter-markdown/issues/74
    if node:type() == "inline" then
      local sr, sc, er, ec = node:range()
      node = root:named_descendant_for_range(sr, sc, er, ec)
    end
    if node then
      node = node:parent()
    end
  end
  return nil
end

---@return (fun(end_line: integer|nil): integer, TSNode, vim.treesitter.query.TSMetadata, TSQueryMatch, TSTree):
function Ast:get_table_nodes()
  return QUERY_TABLES:iter_captures(self:_get_tree():root(), self.bufnr, 0, -1)
end

return Ast
