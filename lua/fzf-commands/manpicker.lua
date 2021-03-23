local utils = require "fzf-commands.utils"

return function()
  coroutine.wrap(function (options)
    options = utils.normalize_opts(options)
    local choices = options.fzf("man -k .", "--tiebreak begin --nth 1,2 --expect=ctrl-v,ctrl-s,ctrl-t") 
    if choices then

      local split_cmd = ""

      if choices[1] == "ctrl-t" then split_cmd = "tab " end
      if choices[1] == "ctrl-v" then split_cmd = "vertical " end

      local split_items = vim.split(choices[2], " ")
      local manpagename = split_items[1]
      local chapter = string.match(split_items[2], "%((.+)%)")
      local cmd = string.format("Man %s %s", chapter, manpagename)
      vim.cmd(split_cmd .. cmd)
    end
  end)()
end
