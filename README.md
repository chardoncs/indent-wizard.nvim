# indent-wizard.nvim

Simple indentation configuration and guessing plugin for Neovim

## Install

### Manual

```lua
require("indent-wizard").setup()
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "chardoncs/indent-wizard.nvim",
  opts = {},
}
```

## Configuration

### Default configuration

This snippet is about default config. You don't need to copypasta it.

```lua
require("indent-wizard").setup {
  -- Auto guess and set buffer-wise indentation for each buffer
  auto_guess = true,
  scan = {
    -- How many lines of sample in a file should be used for indentation guessing.
    --
    -- NOTE: 0-indented lines are ignored.
    line_count = 60,
    -- How many lines should be skipped.
    --
    -- If the number is between 0~1, indent-wizard will regard it
    -- as percentage of total lines.
    offset = 0,
  },
  -- Default settings
  defaults = {
    -- Nothing by default
  },
}
```

### Fallback indentations

Here is how fallback settings (`defaults`) looks like:

```lua
require("indent-wizard").setup {
  defaults = {
    -- Global settings, will be applied to `vim.opt`
    {
      -- All options are optional
      options = {
        tabstop = 8,
        softtabstop = 4,
        shiftwidth = 4,
        expandtab = true,
        smartindent = true,
      },
    },
    -- Filetype-wise settings, will be applied to `vim.bo`
    {
      ft = "go",
      options = {
        shiftwidth = 4,
        expandtab = false,
      },
    },
    {
      -- Or multiple filetypes
      ft = ["c", "cpp", "rust", "zig"],
      options = {
        shiftwidth = 4,
        expandtab = false,
      },
    },
  },
}
```
