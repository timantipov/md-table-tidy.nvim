local Ast = require "md-table-tidy.ast"
local Parser = require "md-table-tidy.parser"
local Render = require "md-table-tidy.render"

---@class TableTidy
local M = {}

---@type TableTidy.Config
M.config = {
  padding = 1,
  key = "<leader>tt",
}

M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("TableTidy", { clear = true }),
    pattern = "markdown",
    callback = function(args)
      local bufnr = args.buf
      M.register_user_commands(bufnr)
      M.register_keymap(bufnr)
    end,
  })
end

M.register_user_commands = function(bufnr)
  vim.api.nvim_buf_create_user_command(
    bufnr,
    "TableTidy",
    M.table_tidy,
    { desc = "Format markdown table under cursor" }
  )
end

M.register_keymap = function(bufnr)
  vim.keymap.set("n", M.config.key, M.table_tidy, {
    buffer = bufnr,
    silent = true,
  })
end

M.table_tidy = function()
  local node = Ast:get_closest_table_node(vim.treesitter.get_node())
  if node then
    M._format(node)
    return
  end
  vim.notify("Table under cursor not found", vim.log.levels.WARN, { title = "md-table-tidy" })
end

---@private
---@param node TSNode
function M._format(node)
  local tbl = Parser.parse(vim.api.nvim_get_current_buf(), node)
  local lines = Render:new({ padding = M.config.padding }):render(tbl)
  vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), tbl.range.from, tbl.range.to, true, lines)
end

return M
