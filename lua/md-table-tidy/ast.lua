local Ast = {}

---@class TableTidy.Ast
---@field bufnr integer
Ast.__index = Ast

---@return TableTidy.Ast
function Ast.new(bufnr)
  return setmetatable({
    bufnr = bufnr or vim.api.nvim_get_current_buf(),
  }, Ast)
end

---@private
---@return vim.treesitter.LanguageTree?, TSNode
function Ast:_get_root()
  local parser = vim.treesitter.get_parser(self.bufnr)
  local tree = parser:parse()[1]
  return parser, tree:root()
end

---@return TSNode?
function Ast:get_closest_table_node(node)
  local _, root = self:_get_root()
  while node do
    if node:type() == "pipe_table" then
      return node
    end
    -- in treesitter markdown grammar nodes with type (inline) are special and always has root level
    -- https://github.com/tree-sitter-grammars/tree-sitter-markdown/issues/74
    if node:type() == "inline" then
      ---@diagnostic disable-next-line
      node = root:named_node_for_range { node:range() }
    end
    if node then
      node = node:parent()
    end
  end
  return nil
end

return Ast
