# nvim-fzf-commands

A repository for commands using the
[`nvim-fzf`](https://github.com/vijaymarupudi/nvim-fzf) library.

This is a work in progress, contributions welcome!

## Table of contents

* [Usage](#usage)
* [Commands](#commands)
* [Configuration](#configuration)
* [Contribution notes](#contribution-notes)

## Usage

This repository exports lua functions for the user to bind to vim
commands or keybindings.

**Example**

```vim
noremap <leader>f <cmd>lua require("fzf-commands").files()<cr>
" or
command! Files lua require("fzf-commands").files()
" or with configuration
noremap <leader>f <cmd>lua require("fzf-commands").files({ fzf = custom_fzf_function })<cr>
```

## Commands

These are keys of `require("fzf-commands")`. For eg.:
`require('fzf-commands').files()`

`files()`: Open files in the current vim directory

* List files (using [`fd`](https://github.com/sharkdp/fd) if available,
  otherwise `find`)
* Preview (using [`bat`](https://github.com/sharkdp/bat) if available,
  otherwise `head`)
* Supports opening multi files
* Can open files in the same window, in a [vertical] split, or in a new
  tab (`enter`, `ctrl-s`, `ctrl-v`, `ctrl-t`).

![](gifs/files.gif)

`helptags()`: Open neovim help files

* Can open files in the same window, in a [vertical] split, or in a new
  tab (`enter`, `ctrl-s`, `ctrl-v`, `ctrl-t`).

![](gifs/helptags.gif)

`bufferpicker()`: Pick between buffers to switch to them or open in a
  split.

* Preview the buffers
* Can open files in the same window, in a [vertical] split, or in a new
  tab (`enter`, `ctrl-s`, `ctrl-v`, `ctrl-t`).

![](gifs/bufferpicker.gif)


`manpicker()`: Open a manpage using nvim's `Man`.

* Can open files in the same window, in a [vertical] split, or in a new
  tab (`enter`, `ctrl-s`, `ctrl-v`, `ctrl-t`).

![](gifs/manpicker.gif)

## Configuration

All commands support a custom fzf function that manages opening windows
and running fzf.

**Example**

```lua
function my_custom_fzf(contents, options)
  vim.cmd("vnew")
  local results = require("fzf").raw_fzf(contents, options)
  vim.cmd("bw!")
  return results
end
require("fzf-commands").files({ fzf = my_custom_fzf })
```

or


```vim
" vertical fzf
lua << EOF
  function my_custom_fzf(contents, options)
    vim.cmd("vnew")
    local results = require("fzf").raw_fzf(contents, options)
    vim.cmd("bw!")
    return results
  end
EOF
command! Files lua require("fzf-commands").files({ fzf = my_custom_fzf })
```

For other configuration, please see command specific documentation.

## Contribution notes

**Contributions welcome!**

* Any improvements (previews, bindings) to existing commands welcome!
* Any commands relevant to vim or common unix tools welcome!
* Issues welcome for edge cases or need for configurability.
  Configuration should only be added if the user needs it.
* Commands must be asynchronous at all costs for UI speed reasons.
* A gif demonstrating the command would be appreciated.
* All commands should take an fzf configuration option that provides the
  fzf command to use instead of the default `nvim_fzf.fzf` function.
