local M = {}

local function run_module(name)
  return function(...)
    require(name)(...)
  end
end

M.files = run_module("fzf-commands.files")
M.helptags = run_module("fzf-commands.helptags")
M.bufferpicker = run_module("fzf-commands.bufferpicker")
M.manpicker = run_module("fzf-commands.manpicker")
M.rg = run_module("fzf-commands.rg")
M.colorschemes = run_module("fzf-commands.colorschemes")

return M
