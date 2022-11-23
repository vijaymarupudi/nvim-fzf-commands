local fzf = require "fzf".fzf

local utils = require "fzf-commands.utils"

local fn, api = utils.helpers()

local function files(opts)

  opts = utils.normalize_opts(opts)
  local command
  if fn.executable("fd") == 1 then
    command = "fd --color always -t f -L" 
  else
    -- tail to get rid of current directory from the results
    command = "find . -type f -printf '%P\n' | tail +2"
  end

  local preview
  if fn.executable("bat") == 1 then
    -- 5 is the number that prevents overflow of the preview window when using
    -- bat
    preview = ('bash -c %s "$0"'):format(fn.shellescape('bat --line-range=:$(($FZF_PREVIEW_LINES - 5)) --color always -- "$0"'))
  else
    preview = "head -n $FZF_PREVIEW_LINES -- \"$0\""
  end

  -- We use bash to do math on the environment variable, so
  -- let's make sure this command runs in bash
  preview = "bash -c " .. fn.shellescape(preview) .. " {}"

  coroutine.wrap(function ()
    local choices = opts.fzf(command,
      ("--ansi --preview=%s --expect=ctrl-s,ctrl-t,ctrl-v --multi"):format(
        fn.shellescape(preview)))

    if not choices then return end

    local vimcmd
    if choices[1] == "ctrl-t" then
      vimcmd = "tabnew"
    elseif choices[1] == "ctrl-v" then
      vimcmd = "vnew"
    elseif choices[1] == "ctrl-s" then
      vimcmd = "new"
    else
      vimcmd = "e"
    end

    for i=2,#choices do
      vim.cmd(vimcmd .. " " .. fn.fnameescape(choices[i]))
    end
    
  end)()
end

return files

