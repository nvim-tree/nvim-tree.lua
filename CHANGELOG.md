# Changelog

## [1.0.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v0.100.0...nvim-tree-v1.0.0) (2024-02-18)


### Features

* **#2654:** filters.custom may be a function ([#2655](https://github.com/nvim-tree/nvim-tree.lua/issues/2655)) ([4a87b8b](https://github.com/nvim-tree/nvim-tree.lua/commit/4a87b8b46b4a30107971871df3cb7f4c30fdd5d0))


### Miscellaneous Chores

* release 1.0.0 ([#2678](https://github.com/nvim-tree/nvim-tree.lua/issues/2678)) ([d16246a](https://github.com/nvim-tree/nvim-tree.lua/commit/d16246a7575538f77e9246520449b99333c469f7))

## [0.100.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v0.99.0...nvim-tree-v0.100.0) (2024-02-11)


### Features

* **#1389:** api: recursive node navigation for git and diagnostics ([#2525](https://github.com/nvim-tree/nvim-tree.lua/issues/2525)) ([5d13cc8](https://github.com/nvim-tree/nvim-tree.lua/commit/5d13cc8205bce4963866f73c50f6fdc18a515ffe))
* **#2415:** add :NvimTreeHiTest ([#2664](https://github.com/nvim-tree/nvim-tree.lua/issues/2664)) ([b278fc2](https://github.com/nvim-tree/nvim-tree.lua/commit/b278fc25ae0fc95e4808eb5618f07fc2522fd2b3))
* **#2415:** colour and highlight overhaul, see :help nvim-tree-highlight-overhaul ([#2455](https://github.com/nvim-tree/nvim-tree.lua/issues/2455)) ([e9c5abe](https://github.com/nvim-tree/nvim-tree.lua/commit/e9c5abe073a973f54d3ca10bfe30f253569f4405))
* add node.open.toggle_group_empty, default mapping L ([#2647](https://github.com/nvim-tree/nvim-tree.lua/issues/2647)) ([8cbb1db](https://github.com/nvim-tree/nvim-tree.lua/commit/8cbb1db8e90b62fc56f379992e622e9f919792ce))


### Bug Fixes

* **#2415:** disambiguate highlight groups, see :help nvim-tree-highlight-overhaul ([#2639](https://github.com/nvim-tree/nvim-tree.lua/issues/2639)) ([d9cb432](https://github.com/nvim-tree/nvim-tree.lua/commit/d9cb432d2c8d8fa9267ddbd7535d76fe4df89360))
* **#2415:** fix NvimTreeIndentMarker highlight group: FileIcon-&gt;FolderIcon ([e9ac136](https://github.com/nvim-tree/nvim-tree.lua/commit/e9ac136a3ab996aa8e4253253521dcf2cb66b81b))
* **#2415:** highlight help header and mappings ([#2669](https://github.com/nvim-tree/nvim-tree.lua/issues/2669)) ([39e6fef](https://github.com/nvim-tree/nvim-tree.lua/commit/39e6fef85ac3bb29532b877aa7c9c34911c661af))
* **#2415:** nvim 0.8 highlight overhaul support, limited to only show highest highlight precedence ([#2642](https://github.com/nvim-tree/nvim-tree.lua/issues/2642)) ([f39f7b6](https://github.com/nvim-tree/nvim-tree.lua/commit/f39f7b6fcd3865ac2146de4cb4045286308f2935))
* **#2415:** NvimTreeIndentMarker highlight group: FileIcon-&gt;FolderIcon ([#2656](https://github.com/nvim-tree/nvim-tree.lua/issues/2656)) ([e9ac136](https://github.com/nvim-tree/nvim-tree.lua/commit/e9ac136a3ab996aa8e4253253521dcf2cb66b81b))
* **#2624:** open file from docked floating window ([#2627](https://github.com/nvim-tree/nvim-tree.lua/issues/2627)) ([f24afa2](https://github.com/nvim-tree/nvim-tree.lua/commit/f24afa2cef551122b8bd53bb2e4a7df42343ce2e))
* **#2632:** occasional error stack when locating nvim-tree window ([#2633](https://github.com/nvim-tree/nvim-tree.lua/issues/2633)) ([48b1d86](https://github.com/nvim-tree/nvim-tree.lua/commit/48b1d8638fa3726236ae22e0e48a74ac8ea6592a))
* **#2637:** show buffer modified icons and highlights ([#2638](https://github.com/nvim-tree/nvim-tree.lua/issues/2638)) ([7bdb220](https://github.com/nvim-tree/nvim-tree.lua/commit/7bdb220d0fe604a77361e92cdbc7af1b8a412126))
* **#2643:** correctly apply linked highlight groups in tree window ([#2653](https://github.com/nvim-tree/nvim-tree.lua/issues/2653)) ([fbee8a6](https://github.com/nvim-tree/nvim-tree.lua/commit/fbee8a69a46f558d29ab84e96301425b0501c668))
* allow highlight overrides for DEFAULT_DEFS: NvimTreeFolderIcon, NvimTreeWindowPicker ([#2636](https://github.com/nvim-tree/nvim-tree.lua/issues/2636)) ([74525ac](https://github.com/nvim-tree/nvim-tree.lua/commit/74525ac04760bf0d9fec2bf51474d2b05f36048e))
* bad column offset when using full_name ([#2629](https://github.com/nvim-tree/nvim-tree.lua/issues/2629)) ([75ff64e](https://github.com/nvim-tree/nvim-tree.lua/commit/75ff64e6663fc3b23c72dca32b2f838acefe7c8a))
* passing nil as window handle in view.get_winnr ([48b1d86](https://github.com/nvim-tree/nvim-tree.lua/commit/48b1d8638fa3726236ae22e0e48a74ac8ea6592a))

## 0.99.0 (2024-01-01)


### Features

* **#1850:** add "no bookmark" filter ([#2571](https://github.com/nvim-tree/nvim-tree.lua/issues/2571)) ([8f92e1e](https://github.com/nvim-tree/nvim-tree.lua/commit/8f92e1edd399f839a23776dcc6eee4ba18030370))
* add kind param to vim.ui.select function calls ([#2602](https://github.com/nvim-tree/nvim-tree.lua/issues/2602)) ([dc839a7](https://github.com/nvim-tree/nvim-tree.lua/commit/dc839a72a6496ce22ebd3dd959115cf97c1b20a0))
* add option to skip gitignored files on git navigation ([#2583](https://github.com/nvim-tree/nvim-tree.lua/issues/2583)) ([50f30bc](https://github.com/nvim-tree/nvim-tree.lua/commit/50f30bcd8c62ac4a83d133d738f268279f2c2ce2))


### Bug Fixes

* **#2519:** Diagnostics Not Updated When Tree Not Visible ([#2597](https://github.com/nvim-tree/nvim-tree.lua/issues/2597)) ([96a783f](https://github.com/nvim-tree/nvim-tree.lua/commit/96a783fbd606a458bcce2ef8041240a8b94510ce))
* **#2609:** help toggle ([#2611](https://github.com/nvim-tree/nvim-tree.lua/issues/2611)) ([fac4900](https://github.com/nvim-tree/nvim-tree.lua/commit/fac4900bd18a9fa15be3d104645d9bdef7b3dcec))
* hijack_cursor on update focused file and vim search ([#2600](https://github.com/nvim-tree/nvim-tree.lua/issues/2600)) ([02ae523](https://github.com/nvim-tree/nvim-tree.lua/commit/02ae52357ba4da77a4c120390791584a81d15340))
