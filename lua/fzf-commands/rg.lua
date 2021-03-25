local utils = require "fzf-commands.utils"

local fn, api = utils.helpers()

local function open_file(window_cmd, filename, row, col)
  vim.cmd(window_cmd .. " ".. vim.fn.fnameescape(filename))
  api.win_set_cursor(0, {tonumber(row), tonumber(col) - 1})
  -- center the window
  vim.cmd "normal! zz"
end

return function(pattern, opts)

  opts = utils.normalize_opts(opts)
  coroutine.wrap(function ()
    local rgcmd = "rg --vimgrep --no-heading " ..
      "--color ansi " .. fn.shellescape(pattern)
    local choices = opts.fzf(rgcmd, "--multi --ansi --expect=ctrl-t,ctrl-s,ctrl-v")
    if not choices then return end

    local window_cmd

    if choices[1] == "" then
      window_cmd = "e"
    elseif choices[1] == "ctrl-v" then
      window_cmd = "vsp"
    elseif choices[1] == "ctrl-t" then
      window_cmd = "tabnew"
    elseif choices[1] == "ctrl-s" then
      window_cmd = "sp"
    end

    for i=2,#choices do
      choice = choices[i]
      local parsed_content = {string.match(choice, "(.-):(%d+):(%d+):.*")}
      local filename = parsed_content[1]
      local row = parsed_content[2]
      local col = parsed_content[3]
      open_file(window_cmd, filename, row, col)
    end
  end)()
end
