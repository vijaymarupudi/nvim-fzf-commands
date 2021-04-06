local utils = require "fzf-commands.utils"
local action = require "fzf.actions".action

local fn, api = utils.helpers()

local function open_file(window_cmd, filename, row, col)
  vim.cmd(window_cmd .. " ".. vim.fn.fnameescape(filename))
  api.win_set_cursor(0, {row, col - 1})
  -- center the window
  vim.cmd "normal! zz"
end

local function parse_vimgrep_line(line)
  local parsed_content = {string.match(line, "(.-):(%d+):(%d+):.*")}
  local filename = parsed_content[1]
  local row = tonumber(parsed_content[2])
  local col = tonumber(parsed_content[3])
  return {
    filename = filename,
    row = row,
    col = col
  }
end

local has_bat = vim.fn.executable("bat")


local function get_preview_line_range(parsed, fzf_lines)
  local line_start = parsed.row - (fzf_lines / 2)
  if line_start < 1 then
    line_start = 1
  else
    line_start = math.floor(line_start)
  end

  -- the minus one prevents an off by one error, because these are line INCLUSIVE
  local line_end = math.floor(parsed.row + (fzf_lines / 2)) - 1

  return line_start, line_end 
end

local function bat_preview(parsed, fzf_lines)
  local line_start, line_end = get_preview_line_range(parsed, fzf_lines)
  local cmd = "bat --style=numbers --color always " .. vim.fn.shellescape(parsed.filename) ..
    " --highlight-line " .. tostring(parsed.row) ..
    " --line-range " .. tostring(line_start) .. ":" .. tostring(line_end)
  return vim.fn.system(cmd)
end

local function head_tail_preview(parsed, fzf_lines)
  local line_start, line_end = get_preview_line_range(parsed, fzf_lines)
  local output =  vim.fn.systemlist("tail --lines=+" .. tostring(line_start) .. " " .. vim.fn.shellescape(parsed.filename) .. 
    "| head -n " .. tostring(line_end - line_start))

  local row_index = parsed.row - (line_start - 1) 
  output[row_index] = "\x1B[1m\x1B[30m\x1B[47m" .. output[row_index] .. "\x1B[0m"
  return output
end

local preview_action = action(function (lines, fzf_lines)
  fzf_lines = tonumber(fzf_lines)
  local line = lines[1]
  local parsed = parse_vimgrep_line(line)
  if has_bat then
    return bat_preview(parsed, fzf_lines)
  else
    return head_tail_preview(parsed, fzf_lines)
  end
end)


return function(pattern, opts)

  opts = utils.normalize_opts(opts)
  coroutine.wrap(function ()
    local rgcmd = "rg --vimgrep --no-heading " ..
      "--color ansi " .. fn.shellescape(pattern)
    local choices = opts.fzf(rgcmd, "--multi --ansi --expect=ctrl-t,ctrl-s,ctrl-v " .. "--preview " .. preview_action)
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
      local choice = choices[i]
      local parsed_content = parse_vimgrep_line(choice)
      open_file(window_cmd,
        parsed_content.filename,
        parsed_content.row,
        parsed_content.col)
    end
  end)()
end
