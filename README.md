# npm-runner.nvim

A Neovim plugin to manage npm scripts without leaving your editor. It allows you to run, stop, and toggle the output of your npm scripts in a dedicated window.

![npm-runner.nvim screenshot](https://neovim.io/images/showcase/terminal-telescope.png)

## Features

- Run multiple npm scripts concurrently.
- Each script runs in its own dedicated log window.
- Customizable colors for the winbar title of each script.
- Configurable height for the log windows.
- Stop and toggle the visibility of running scripts.
- List available scripts with `vim.ui.select`.

## Installation

Install the plugin with your favorite plugin manager.

### lazy.nvim

```lua
{
    'asif/npm-runner.nvim',
    config = function()
        require('npm-runner').setup({
            -- your custom config
        })
    end,
}
```

### packer.nvim

```lua
use {
    'asif/npm-runner.nvim',
    config = function()
        require('npm-runner').setup({
            -- your custom config
        })
    end,
}
```

### Conditional Loading for JS/TS Projects

If you want to load this plugin only for JavaScript or TypeScript projects, you can use the `root` property in `lazy.nvim`. This will make `lazy.nvim` check for the presence of a `package.json` file and only load the plugin if it's found.

```lua
{
    'asif/npm-runner.nvim',
    -- Conditionally load the plugin only when a package.json is found
    -- in the project root.
    root = {
        "package.json",
    },
    config = function()
        require('npm-runner').setup({
            -- your custom config
        })
    end,
}
```

## Configuration

The plugin comes with the following default configuration. You can override any of these options by passing them to the `setup` function.

```lua
require('npm-runner').setup({
    -- The default height of the log window
    height = 10,

    -- Whether the log window should take focus when it opens
    focus_on_open = true,

    -- Colors for the winbar titles of different scripts.
    -- These should be specified as hex color codes (e.g., "#RRGGBB").
    -- If a script name is not in this table, a random bright color will be used.
    colors = {
        dev = "#33FF33",
        build = "#3333FF",
        test = "#FFFF33",
        format = "#FF33FF",
    },
})
```

## Usage

The plugin provides the following commands:

- `:NpmRun [script_name]`
  - If you provide a `script_name`, it will run that script.
  - If you don't provide a `script_name`, it will open a `vim.ui.select` window to let you choose from the available scripts in your `package.json`.

- `:NpmRunStop <script_name>`
  - Stops a running script. This command has completion for running scripts, so you can press `<Tab>` to see the list of running scripts.

- `:NpmRunToggle <script_name>`
  - Toggles the visibility of the log window for a running script. This command also has completion for running scripts.