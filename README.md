# Ticktock

A neovim plugin help you manage tasks.

Task datas are stored in [SQLite](https://www.sqlite.org/index.html) database for persistence.

> This plugin is designed to running on Linux / MacOS.
>
> If you want to manage tasks on the terminal, have a try with [taskcli](https://github.com/0x00-ketsu/taskcli).

![ticktock](./_assets/demo.png)

## Features

- Auto save task after edited, triggered by `InsertLeave`.
- Preview task.

## Requirements

<details>
<summary>sqlite3</summary>

Ensure you have `sqlite3` installed locally. (if you are on `Mac` it might be installed already)

**Windows**

[Download precompiled](https://www.sqlite.org/download.html) and set `let g:sqlite_clib_path = path/to/sqlite3.dll` (note: `/`)

**Linux**

- Arch

```shell
sudo pacman -S sqlite
```

- Debian and Ubuntu

```shell
sudo apt-get install sqlite3 libsqlite3-dev
```

- AlmaLinux and CentOS

```shell
sudo dnf install sqlite sqlite-devel
```

</details>

## Installation

[Packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
  '0x00-ketsu/ticktock.nvim',
  requires = {'kkharji/sqlite.lua'},
  config = function()
    require('ticktock').setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the setup section below
    },
  end
}
```

## Setup

Following defaults:

```lua
view = {
  menu = {
    position = 'left', -- one of 'left', 'right'
    width = 35,
    keys = {
      open = {'o', '<CR>'}, -- open and swith to Task View
      preview = 'p' -- preview Task View
      -- next = 'j', -- next item
      -- previous = 'k' -- preview item
    }
  },
  task = {
    keys = {
      create = 'n', -- create new task
      edit = 'e', -- edit task
      complete = 'gc', -- complete task
      delete = 'gd', -- delete task
      refresh = 'r', -- refresh task list
      hover = 'K' -- show task detail in float window
    }
  }
}
```

## Commands

- `:TTOpen`: open ticktock view.
- `:TTClose`: close ticktock view.

## API

- Get todo task(s) count

  `vim.g.tt_todo_count` (variable type is `number`)

  e.g.

  ```lua
  local has_todo = vim.g.tt_todo_count > 0 and true or false
  local todo = has_todo and '📆' or ''
  ```

## License

MIT
