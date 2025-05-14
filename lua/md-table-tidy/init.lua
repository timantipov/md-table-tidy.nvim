local packages = {
  "md-table-tidy.table",
  "md-table-tidy.column",
  "md-table-tidy.utils",
  "md-table-tidy.render",
  "md-table-tidy.parser",
}
for _, p in ipairs(packages) do
  package.loaded[p] = nil
end
--
---@class TableTidy.Config
---@field padding integer
---@field key string

---@class TableTidy
---@field config TableTidy.Config
local M = {}

---@type TableTidy.Config
M.config = {
  padding = 1,
  key = "<leader>tt",
}

M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      M.register_user_commands()
      vim.schedule(M.register_keymap)
    end,
  })
end

M.register_user_commands = function()
  vim.api.nvim_buf_create_user_command(
    vim.api.nvim_get_current_buf(),
    "TableTidy",
    M.fmt,
    { desc = "Format markdown table under cursor" }
  )
end

M.register_keymap = function()
  vim.keymap.set("n", M.config.key, ":TableTidy<cr>", { buffer = vim.api.nvim_get_current_buf(), silent = true })
end

M.fmt = function()
  local success, tbl = pcall(require("md-table-tidy.parser").parse)
  if not success then
    vim.notify(tostring(tbl), vim.log.levels.WARN, { title = "md-table-tidy" })
    return
  end
  local lines = require("md-table-tidy.render"):new({ padding = M.config.padding }):render(tbl)
  vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), tbl.range.from, tbl.range.to, true, lines)
end

M.fmt()

return M
