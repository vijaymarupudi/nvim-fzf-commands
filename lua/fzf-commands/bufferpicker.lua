local action = require "fzf.actions".action
local utils = require "fzf-commands.utils"
local term = require "fzf-commands.term"

local fn, api = utils.helpers()

local function getbufnumber(line)
  return tonumber(string.match(line, "%[(%d+)"))
end

local function getfilename(line)
  return string.match(line, "%[.*%] (.+)")
end

return function(options)

    local act = action(function (items, fzf_lines, cols)
      -- only preview first item
      local item = items[1]
      local buf = getbufnumber(item)
      if api.buf_is_loaded(buf) then
        return api.buf_get_lines(buf, 0, fzf_lines, false)
      else
        local name = getfilename(item)
        if fn.filereadable(name) ~= 0 then
          return fn.readfile(name, "", fzf_lines)
        end
        return "UNLOADED: " .. name
      end
    end)

  coroutine.wrap(function ()
    options = utils.normalize_opts(options)
    opts = string.format([[--ansi --preview=%s]], act)
    opts = opts .. " --expect=ctrl-t,ctrl-s,ctrl-v"

    local items = {}

    for _, bufhandle in ipairs(api.list_bufs()) do


      local additional_info = ""
      if api.buf_get_option(bufhandle, "modified") then
        additional_info = additional_info .. "+"
      end
      if not api.buf_is_loaded(bufhandle) then
        additional_info = additional_info .. "u"
      end

      local name = fn.bufname(bufhandle)

      if #name == 0 then
        name = "[No Name]"
      end

      -- for Terminal buffer, cleanup name
      if api.buf_get_option(bufhandle, "buftype") == "terminal" then
        -- b:term_title comes from nvim, see 'terminal'
        name = term.teal .. "Term: " ..
          term.reset .. api.buf_get_var(bufhandle, "term_title")
      end

      local item_string = string.format("[%s] %s", term.teal .. tostring(bufhandle) .. additional_info .. term.reset, name)

      table.insert(items, item_string)
      -- table.insert(items, string.format("%s\t%s", bufhandle .. additional_info, name))
    end

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

    local cmd

    if lines[1] == "" then
      cmd = ""
    elseif lines[1] == "ctrl-t" then
      cmd = "tab split | "
    elseif lines[1] == "ctrl-v" then
      cmd = "vertical split | "
    elseif lines[1] == "ctrl-s" then
      cmd = "split | "
    end

    item = lines[2]
    local buf = getbufnumber(item)
    vim.cmd(cmd .. "b " .. tostring(buf))
  end)()
end
