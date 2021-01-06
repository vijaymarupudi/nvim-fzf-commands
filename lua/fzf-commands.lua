local M = {}

local function run_module(name)
  return function(...)
    require(name)(...)
  end
end


M.files = run_module("fzf-commands.files")
M.helptags = run_module("fzf-commands.helptags")

return M
