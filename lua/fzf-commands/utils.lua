local M = {}

M.api = {
  __index = function(self, item)
    self[item] = vim.api["nvim_" .. item]
    return self[item]
  end
}

setmetatable(M.api, M.api)

M.fn = vim.fn

function M.helpers()
  return M.fn, M.api
end

function M.normalize_opts(opts)
  if not opts then opts = {} end
  if not opts.fzf then opts.fzf = require"fzf".fzf end
  return opts
end

return M
