local action = require("fzf.actions").action
local utils = require("fzf-commands.utils")
local fn, api = utils.helpers()

local function get_colorschemes()
  local colorscheme_vim_files = fn.globpath(vim.o.rtp, "colors/*.vim", true, true)
  local colorschemes = {}
  for _, colorscheme_file in ipairs(colorscheme_vim_files) do
    local colorscheme = fn.fnamemodify(colorscheme_file, ":t:r")
    table.insert(colorschemes, colorscheme)
  end
  return colorschemes
end

local function get_current_colorscheme()
  if vim.g.colors_name then
    return vim.g.colors_name
  else
    return 'default'
  end
end

return function(opts)

  opts = utils.normalize_opts(opts)

  coroutine.wrap(function ()
    local preview_function = action(function (args)
      if args then
        local colorscheme = args[1]
        vim.cmd("colorscheme " .. colorscheme)
      end
    end)

    local current_colorscheme = get_current_colorscheme()
    local current_background = vim.o.background
    local choices = opts.fzf(get_colorschemes(), "--preview=" .. preview_function .. " --preview-window right:0") 
    if not choices then
      vim.o.background = current_background
      vim.cmd("colorscheme " .. current_colorscheme)
      vim.o.background = current_background
    else
      vim.cmd("colorscheme" .. choices[1])
    end
  end)()

end
