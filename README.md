# todo.nvim

A simple todo list manager for neovim

## What Is Todo?

`todo.nvim` is a simple todo list manager for neovim. It allows you to create
and manage todo lists in a simple and efficient way. It is designed to be
simple. It primarily focuses on tasks per directory that you launch neovim in.

I created this to help track ideas as they pop up while allowing me to not
lose focus on the task at hand. I hope you find it useful as well.

## Usage

Using lua:

```lua
local todo = require('todo')
vim.keymap.set("n", "<leader>td", todo.toggle)
```

### Inside the todo buffer:

- Press `i` to enter insert mode and add a task. New lines will become tasks on exit or toggle.
- Press `dd` to delete a task. Press `j` and `k` to navigate tasks.
- Press enter to toggle a task as complete. You can also set the character between [ ] to `X` to mark a task as complete.

## Planned features

- [ ] Manage task groups
- [ ] Explore projects and task groups
- [ ] Track datetimes
- [ ] Better sorting and task cleanup
- [ ] Task Archiving
- [ ] Save marks for tasks
- [ ] Project level config to sort taks by incomplete first on save
- [ ] Global config to sort tasks by incomplete first
