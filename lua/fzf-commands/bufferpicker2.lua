local raw_fzf = require("fzf").raw_fzf
local action = require("fzf.actions").action
local fn, api = require("fzf-commands.utils").helpers()
local term = require("fzf-commands.term")

local function get_buffer_handle_list(options)
  local raw_buffer_handles = api.list_bufs()
  local buffer_handles = {}
  for _, handle in ipairs(raw_buffer_handles) do
    local listed_criteria = false
    local loaded_criteria = false
    if fn.buflisted(handle) == 1 or
       options.unlisted then
      listed_criteria = true
    end

    if api.buf_is_loaded(handle) or
       options.unloaded then
      loaded_criteria = true
    end

    if loaded_criteria and listed_criteria then
      table.insert(buffer_handles, handle)
    end
  end

  return buffer_handles
end

local function bufhandle_to_display_name(bufhandle)
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

  return string.format("[%s] %s", term.teal .. tostring(bufhandle) .. additional_info .. term.reset, name)
end

local function get_display_names(options)
  local bufhandles = get_buffer_handle_list(options)
  local display_names = {}
  for _, bufhandle in ipairs(bufhandles) do
    table.insert(display_names, bufhandle_to_display_name(bufhandle))
  end
  return display_names
end

local function display_name_to_bufhandle(display_name)
  return tonumber(string.match(display_name, "%[(%d+)"))
end

local function display_name_to_filename(display_name)
  return string.match(display_name, "%[.*%] (.+)")
end


local function win_run_shell(win, shell)

  local buf = api.win_get_buf(win)

  local term_chan = api.open_term(buf, {})

  fn.jobstart(shell, { on_stdout = function(chan, data, name)
    -- IMPORTANT: this condition prevents a race condition when
    -- the user has navigated away from the listing, but the
    -- preview command has not run yet
    if api.win_get_buf(win) == buf then
      for _, v in ipairs(data) do
        api.chan_send(term_chan, v .. "\r\n")
      end
    end
  end,
  stdout_buffered = true})

end

return function(options)

  -- options support keys 'direction', 'unlisted', 'unloaded', and 'height'
  coroutine.wrap(function ()

    if not options then options = {} end

    -- for previews of unloaded buffers
    local has_bat = fn.executable("bat") ~= 0

    -- preview win
    if options.direction == "top" then
      vim.cmd "topleft sp"
    else
      vim.cmd "botright sp"
    end

    local preview_win = api.get_current_win()
    if options.height then
      api.win_set_height(preview_win, options.height)
    end

    -- fzf win
    vim.cmd 'vnew'
    local fzf_win = api.get_current_win()
    api.buf_set_option(0, "buflisted", false)
    vim.cmd [[setlocal statusline=\ >\ Buffers]]


    -- preview action
    local preview = action(function (args)
      local bufhandle = display_name_to_bufhandle(args[1])

      -- show stuff
      if api.buf_is_loaded(bufhandle) then
        api.win_set_buf(preview_win, bufhandle)
      else
        local tmp_buf = api.create_buf(false, true)
        api.buf_set_option(tmp_buf, 'bufhidden', 'wipe')
        api.win_set_buf(preview_win, tmp_buf)
        local filename = api.buf_get_name(bufhandle)
        if #filename ~= 0 and vim.fn.filereadable(filename) ~= 0 then
          if has_bat then
            win_run_shell(preview_win, "bat --color always -pp " .. 
              "--line-range :" .. tostring(api.win_get_height(preview_win)) .. " " .. 
              vim.fn.shellescape(filename))
          else
            -- minus one for statusbar height
            win_run_shell("head " .. 
              "--lines=" .. tostring(api.win_get_height(preview_win) - 1) .. " " ..
              vim.fn.shellescape(filename))
          end
        else
          api.buf_set_text(tmp_buf, 0, 0, 0, 0, {"UNLOADED BUFFER"})
        end
      end

    end)

    local choices = raw_fzf(get_display_names(options), "--ansi " ..
      "--preview=" .. preview .. " " ..
      "--preview-window right:0 " ..
      "--expect=ctrl-s,ctrl-t,ctrl-v " ..
      "--multi")    

    api.win_close(preview_win, false) -- close the preview window
    local fzf_buf = api.win_get_buf(fzf_win)
    -- doing this instead of :bw! because it don't want the new buffer to
    -- inherit the minimal style of the fzf and preview buffer
    api.win_close(fzf_win, false)
    api.buf_delete(fzf_buf, { force = true })

    if not choices then
      return
    end

    local split_cmd
    if choices[1] == "" then
      split_cmd = nil
    elseif choices[1] == "ctrl-s" then
      split_cmd = ""
    elseif choices[1] == "ctrl-t" then
      split_cmd = "tab"
    elseif choices[1] == "ctrl-v" then
      split_cmd = "vertical"
    end

    for i=2,#choices do
      local buffer_num_str = tostring(display_name_to_bufhandle(choices[i]))
      if split_cmd then
        vim.cmd(split_cmd .. " sbuffer " .. buffer_num_str)
      else
        vim.cmd("b " .. buffer_num_str)
      end
    end
  end)()
end
