local uv = vim.loop
local utils = require "fzf-commands.utils"

local function readfilecb(path, callback)
  uv.fs_open(path, "r", 438, function(err, fd)
    if err then
      callback(err)
      return
    end
    uv.fs_fstat(fd, function(err, stat)
      if err then
        callback(err)
        return
      end
      uv.fs_read(fd, stat.size, 0, function(err, data)
        if err then
          callback(err)
          return
        end
        uv.fs_close(fd, function(err)
          if err then
            callback(err)
            return
          end
          return callback(nil, data)
        end)
      end)
    end)
  end)
end

local function readfile(name)
  local co = coroutine.running()
  readfilecb(name, function (err, data)
    coroutine.resume(co, err, data)
  end)
  local err, data = coroutine.yield()
  if err then error(err) end
  return data
end

local function deal_with_tags(tagfile, cb)
  local co = coroutine.running()
  coroutine.wrap(function ()
    local success, data = pcall(readfile, tagfile)
    if success then
      for i, line in ipairs(vim.split(data, "\n")) do
        local items = vim.split(line, "\t")
        -- escape codes for grey
        local tag = string.format("%s\t\27[0;37m%s\27[0m", items[1], items[2])
        local co = coroutine.running()
        cb(tag, function ()
          coroutine.resume(co)
        end)
        coroutine.yield()
      end
    end
    coroutine.resume(co)
  end)()
  coroutine.yield()
end

local fzf_function = function (cb)
      local runtimepaths = vim.api.nvim_list_runtime_paths()
      local total_done = 0
      for i, rtp in ipairs(runtimepaths) do
        local tagfile = table.concat({rtp, "doc", "tags"}, "/")
        -- wrapping to make all the file reading concurrent
        coroutine.wrap(function ()
          deal_with_tags(tagfile, cb)
          total_done = total_done + 1 
          if total_done == #runtimepaths then
            cb(nil)
          end
        end)()
      end
    -- cb(nil)
  end

return function()
  coroutine.wrap(function (opts)

      opts = utils.normalize_opts(opts)
      local result = opts.fzf(fzf_function, "--nth 1 --ansi --expect=ctrl-t,ctrl-s,ctrl-v") 
      if not result then
        return
      end
      local choice = vim.split(result[2], "\t")[1]
      local key = result[1]
      local windowcmd
      if key == "" or key == "ctrl-s" then
        windowcmd = ""
      elseif key == "ctrl-v" then
        windowcmd = "vertical"
      elseif key == "ctrl-t" then
        windowcmd = "tab"
      else
        print("Not implemented!")
        error("Not implemented!")
      end

      vim.cmd(string.format("%s h %s", windowcmd, choice))
  end)()
end 
