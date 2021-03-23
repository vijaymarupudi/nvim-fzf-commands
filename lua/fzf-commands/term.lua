local function make_color_ansi(color_of_256)
  return "\x1b[38;5;" .. tostring(color_of_256) .. "m"
end

local term = {}

term.reset = "\x1b[0m"
term.bold = "\x1b[1m"
term.teal = make_color_ansi(35)

return term
