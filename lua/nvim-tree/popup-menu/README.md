## File Management Menu [WIP]
A simple popup menu UI for NvimTreeExplorer.

As now the only two options that work for sure is ```copy_path``` and ```copy_name```.

My personal idea is to let the user choose the title of options to be displayed and connect them to an actions to be executed on current node.
At this point is possible to bind only actions that come from ``nvim-tree.actions.mappings``.
You can customize via a table in setup function like:

```lua
setup {
  menu = {
    actions = {
      ['title_of_options'] = 'actions_to_exec',
      titleOfOptions = 'actions_to_exec'
    }
  }
}
```
I hope that you can understand mostly from comment how this things work.
The team behind NvimTree have a good docs and comment so you can try to figure out how the actual actions execution work.

I keep working on this, you can always open an issue on THIS specific branch and I try my best to answer.
