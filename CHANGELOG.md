# Changelog

## [1.16.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.15.0...nvim-tree-v1.16.0) (2026-02-28)


### Features

* add &lt;Del&gt; mapping ([ca8d82f](https://github.com/nvim-tree/nvim-tree.lua/commit/ca8d82fff26cb12ced239713e3222f4a9dcd0da0))
* add default &lt;Del&gt; mapping for api.fs.remove ([#3238](https://github.com/nvim-tree/nvim-tree.lua/issues/3238)) ([ca8d82f](https://github.com/nvim-tree/nvim-tree.lua/commit/ca8d82fff26cb12ced239713e3222f4a9dcd0da0))


### Bug Fixes

* **#3178:** handle Windows paths in ignore_dirs and add .zig-cache to defaults ([#3261](https://github.com/nvim-tree/nvim-tree.lua/issues/3261)) ([5499299](https://github.com/nvim-tree/nvim-tree.lua/commit/5499299746b95c49ef4fc89b30c29a79b577881f))
* **#3187:** prevent closing the last non-floating window when deleting files ([#3282](https://github.com/nvim-tree/nvim-tree.lua/issues/3282)) ([018a078](https://github.com/nvim-tree/nvim-tree.lua/commit/018a078c1e149bcd0c4e65c92aabb8e12501d769))
* **#3198:** add filesystem_watchers.max_events to handle runaway filesystem events on PowerShell ([#3232](https://github.com/nvim-tree/nvim-tree.lua/issues/3232)) ([c07ce43](https://github.com/nvim-tree/nvim-tree.lua/commit/c07ce43527e5f0242121f4eb1feb7ac0ecea8275))
* **#3248:** bookmark filter shows contents of marked directories ([#3249](https://github.com/nvim-tree/nvim-tree.lua/issues/3249)) ([5757bcf](https://github.com/nvim-tree/nvim-tree.lua/commit/5757bcf0447d22d8f78826bc5c59b28da2824c3b))
* **#3251:** pass git.timeout to all vim.system git calls ([#3277](https://github.com/nvim-tree/nvim-tree.lua/issues/3277)) ([e49b0d9](https://github.com/nvim-tree/nvim-tree.lua/commit/e49b0d9bfa70989cf8b5abf5557f51e6e57f68d6))
* **#3265:** rename module api.health to api.appearance, to avoid :checkhealth detection ([#3266](https://github.com/nvim-tree/nvim-tree.lua/issues/3266)) ([1df1960](https://github.com/nvim-tree/nvim-tree.lua/commit/1df1960d0e3a26643a4100f64fa03b991b9f4b85))
* **#3267:** renderer.icons.*_placement 'right_align' at the right hand edge, not the right of the name ([#3270](https://github.com/nvim-tree/nvim-tree.lua/issues/3270)) ([fa3c458](https://github.com/nvim-tree/nvim-tree.lua/commit/fa3c45875f9b1f56ace57711c6f2ac22484ed956))
* **#3281:** fix a bug when a view width of -1 is returned from a function ([#3283](https://github.com/nvim-tree/nvim-tree.lua/issues/3283)) ([c988e28](https://github.com/nvim-tree/nvim-tree.lua/commit/c988e289428d9202b28ba27479647033c7dd2956))
* allow 0 (unlimited) filesystem_watchers.max_events which is the new default, except for windows at 1000 ([#3279](https://github.com/nvim-tree/nvim-tree.lua/issues/3279)) ([87594aa](https://github.com/nvim-tree/nvim-tree.lua/commit/87594aa7c8808701b418b285e9adf690acead201))
* increase filesystem_watchers.max_events from 100 to 1000 ([#3263](https://github.com/nvim-tree/nvim-tree.lua/issues/3263)) ([0f4d2d6](https://github.com/nvim-tree/nvim-tree.lua/commit/0f4d2d6998dc324d54d6adce94186bee43725afb))
* restore bookmark filter for marked directories ([5757bcf](https://github.com/nvim-tree/nvim-tree.lua/commit/5757bcf0447d22d8f78826bc5c59b28da2824c3b))

## [1.15.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.14.0...nvim-tree-v1.15.0) (2026-01-11)


### Features

* **#1826:** add diagnostics.diagnostic_opts: vim.diagnostic.Opts will override diagnostics.severity and diagnostics.icons ([#3190](https://github.com/nvim-tree/nvim-tree.lua/issues/3190)) ([fefa335](https://github.com/nvim-tree/nvim-tree.lua/commit/fefa335f1c8f690eb668a1efd18ee4fc6d64cd3e))
* **#1851:** add bookmarks.persist, default path: vim.fn.stdpath("data") .. "/nvim-tree-bookmarks.json", disabled by default ([#3033](https://github.com/nvim-tree/nvim-tree.lua/issues/3033)) ([c89215d](https://github.com/nvim-tree/nvim-tree.lua/commit/c89215d6a1107a3c0c134750be48657ba8e6a9aa))
* **#3213:** add `view.width.lines_excluded` option ([776a5cd](https://github.com/nvim-tree/nvim-tree.lua/commit/776a5cdfac948b490e06f1d1d22c4cb986e40699))
* **#3213:** add view.width.lines_excluded option ([#3214](https://github.com/nvim-tree/nvim-tree.lua/issues/3214)) ([776a5cd](https://github.com/nvim-tree/nvim-tree.lua/commit/776a5cdfac948b490e06f1d1d22c4cb986e40699))
* add NvimTreeFilter filetype ([64e2192](https://github.com/nvim-tree/nvim-tree.lua/commit/64e2192f5250796aa4a7f33c6ad888515af50640))
* load command definitions at nvim startup ([#3211](https://github.com/nvim-tree/nvim-tree.lua/issues/3211)) ([1eda256](https://github.com/nvim-tree/nvim-tree.lua/commit/1eda2569394f866360e61f590f1796877388cb8a))
* load command definitions in `plugin` directory ([1eda256](https://github.com/nvim-tree/nvim-tree.lua/commit/1eda2569394f866360e61f590f1796877388cb8a))
* set filter input filetype to NvimTreeFilter ([#3207](https://github.com/nvim-tree/nvim-tree.lua/issues/3207)) ([64e2192](https://github.com/nvim-tree/nvim-tree.lua/commit/64e2192f5250796aa4a7f33c6ad888515af50640))
* use `add_trailing` also for symlink destination ([81ede55](https://github.com/nvim-tree/nvim-tree.lua/commit/81ede55c47528ff7c81b2a498fbee61b298c4e2f))


### Bug Fixes

* **#3226:** set &swapfile=false before setting tree buffer name, avoiding any potential collisions with a swapfile ([#3227](https://github.com/nvim-tree/nvim-tree.lua/issues/3227)) ([8298117](https://github.com/nvim-tree/nvim-tree.lua/commit/8298117311a1f23f039c278e4e4977ab80a15e33))
* api.tree.change_root_to_node on a file now changes directory to parent as per documentation ([#3228](https://github.com/nvim-tree/nvim-tree.lua/issues/3228)) ([b8b44b6](https://github.com/nvim-tree/nvim-tree.lua/commit/b8b44b6a2494d086a9177251a119f9daec6cace8))
* correctly assign extmarks to lines when computing tree window width in `grow` when `nvim-tree.view.width.lines_excluded` contains "root" ([e66994d](https://github.com/nvim-tree/nvim-tree.lua/commit/e66994d40db2d57c91bf9aeaee8bf7ab8b1131f6))
* incorrect window width when right_align icons present ([#3239](https://github.com/nvim-tree/nvim-tree.lua/issues/3239)) ([e66994d](https://github.com/nvim-tree/nvim-tree.lua/commit/e66994d40db2d57c91bf9aeaee8bf7ab8b1131f6))
* prevent NvimTree to be alternate buffer when tab open ([#3205](https://github.com/nvim-tree/nvim-tree.lua/issues/3205)) ([e397756](https://github.com/nvim-tree/nvim-tree.lua/commit/e397756d2a79d74314ea4cd3efc41300e91c0ff0))
* renderer.add_trailing applies to symlink destination ([#3217](https://github.com/nvim-tree/nvim-tree.lua/issues/3217)) ([81ede55](https://github.com/nvim-tree/nvim-tree.lua/commit/81ede55c47528ff7c81b2a498fbee61b298c4e2f))


### Performance Improvements

* **commands:** defer module loading ([#3210](https://github.com/nvim-tree/nvim-tree.lua/issues/3210)) ([68c67ad](https://github.com/nvim-tree/nvim-tree.lua/commit/68c67adfabfd1ce923839570507ef2e81ab8a408))

## [1.14.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.13.0...nvim-tree-v1.14.0) (2025-08-12)


### Features

* **#2685:** highlight git new tracked with NvimTreeGitFileNewHL ([#3176](https://github.com/nvim-tree/nvim-tree.lua/issues/3176)) ([0a52012](https://github.com/nvim-tree/nvim-tree.lua/commit/0a52012d611f3c1492b8d2aba363fabf734de91d))
* **#2789:** add optional function expand_until to api.tree.expand_all and api.node.expand ([#3166](https://github.com/nvim-tree/nvim-tree.lua/issues/3166)) ([1b876db](https://github.com/nvim-tree/nvim-tree.lua/commit/1b876db04903b93c78c97fd3f3dd85d59eeef5ff))
* **#2826:** allow only one window with nvim-tree buffer per tab ([#3174](https://github.com/nvim-tree/nvim-tree.lua/issues/3174)) ([dd2364d](https://github.com/nvim-tree/nvim-tree.lua/commit/dd2364d6802f7f57a98acb8b545ed484c6697626))
* **#3157:** add view.cursorlineopt ([#3158](https://github.com/nvim-tree/nvim-tree.lua/issues/3158)) ([8eb5e0b](https://github.com/nvim-tree/nvim-tree.lua/commit/8eb5e0bfd1c4da6efc03ab0c1ccf463dbaae831e))


### Bug Fixes

* **#3077:** deleting a directory containing symlinked directory will delete the contents of the linked directory ([#3168](https://github.com/nvim-tree/nvim-tree.lua/issues/3168)) ([10db694](https://github.com/nvim-tree/nvim-tree.lua/commit/10db6943cb40625941a35235eeb385ffdfbf827a))
* **#3157:** add view.cursorlineopt ([8eb5e0b](https://github.com/nvim-tree/nvim-tree.lua/commit/8eb5e0bfd1c4da6efc03ab0c1ccf463dbaae831e))
* **#3172:** live filter exception ([#3173](https://github.com/nvim-tree/nvim-tree.lua/issues/3173)) ([0a7fcdf](https://github.com/nvim-tree/nvim-tree.lua/commit/0a7fcdf3f8ba208f4260988a198c77ec11748339))
* invalid window id for popup info window ([#3147](https://github.com/nvim-tree/nvim-tree.lua/issues/3147)) ([d54a187](https://github.com/nvim-tree/nvim-tree.lua/commit/d54a1875a91e1a705795ea26074795210b92ce7f))
* **picker:** exclude full_name window id from the choice ([#3165](https://github.com/nvim-tree/nvim-tree.lua/issues/3165)) ([543ed3c](https://github.com/nvim-tree/nvim-tree.lua/commit/543ed3cac212dc3993ef9f042f6c0812e34ddd43))
* window picker ignore hidden window ([#3145](https://github.com/nvim-tree/nvim-tree.lua/issues/3145)) ([d87b41c](https://github.com/nvim-tree/nvim-tree.lua/commit/d87b41ca537e2131622d48a6c25ccf2fbe0e5d62))


### Performance Improvements

* **#3171:** cache toplevel for untracked ([#3185](https://github.com/nvim-tree/nvim-tree.lua/issues/3185)) ([4425136](https://github.com/nvim-tree/nvim-tree.lua/commit/442513648c6936e754c3308a1c58591a399493e5))
* **#3171:** use vim.system() instead of vim.fn.system() to execute git toplevel ([#3175](https://github.com/nvim-tree/nvim-tree.lua/issues/3175)) ([9a05b9e](https://github.com/nvim-tree/nvim-tree.lua/commit/9a05b9e9f928856ca23dbf876fab372003180c3f))


### Reverts

* **#3180, #3177:** invalid group or tabpage ([#3181](https://github.com/nvim-tree/nvim-tree.lua/issues/3181)) ([9b289ab](https://github.com/nvim-tree/nvim-tree.lua/commit/9b289abd6998e30fd24cbc9919e0b0cbed6364ce))
* **#3180, #3177:** resolve live filter failures ([#3183](https://github.com/nvim-tree/nvim-tree.lua/issues/3183)) ([a4699c0](https://github.com/nvim-tree/nvim-tree.lua/commit/a4699c0904103e7767334f6da05f5c2ea5514845))

## [1.13.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.12.0...nvim-tree-v1.13.0) (2025-06-14)


### Features

* **#3113:** add renderer.icons.folder_arrow_padding ([#3114](https://github.com/nvim-tree/nvim-tree.lua/issues/3114)) ([ea5097a](https://github.com/nvim-tree/nvim-tree.lua/commit/ea5097a1e2702b4827cb7380e7fa0bd6da87699c))
* **#3132:** add api.node.expand and api.node.collapse ([#3133](https://github.com/nvim-tree/nvim-tree.lua/issues/3133)) ([ae59561](https://github.com/nvim-tree/nvim-tree.lua/commit/ae595611fb2225f2041996c042aa4e4b8663b41e))


### Bug Fixes

* "Invalid buffer id" on closing nvim-tree window ([#3129](https://github.com/nvim-tree/nvim-tree.lua/issues/3129)) ([25d16aa](https://github.com/nvim-tree/nvim-tree.lua/commit/25d16aab7d29ca940a9feb92e6bb734697417009))
* **#2746:** background and right aligned icons in floating windows ([#3128](https://github.com/nvim-tree/nvim-tree.lua/issues/3128)) ([cbc3165](https://github.com/nvim-tree/nvim-tree.lua/commit/cbc3165e08893bb499da035c6f6f9d1512b57664))
* **#3117:** allow changing filename's casing ([bd54d1d](https://github.com/nvim-tree/nvim-tree.lua/commit/bd54d1d33c20d8630703b9842480291588dbad07))
* **#3117:** windows: change file/dir case ([#3135](https://github.com/nvim-tree/nvim-tree.lua/issues/3135)) ([bd54d1d](https://github.com/nvim-tree/nvim-tree.lua/commit/bd54d1d33c20d8630703b9842480291588dbad07))
* **#3122:** remove redundant vim.validate ([#3123](https://github.com/nvim-tree/nvim-tree.lua/issues/3123)) ([e7d1b7d](https://github.com/nvim-tree/nvim-tree.lua/commit/e7d1b7dadc62fe2eccc17d814354b0a5688621ce))
* **#3124:** fix icon padding for "right_align" placements, notably for dotfiles ([#3125](https://github.com/nvim-tree/nvim-tree.lua/issues/3125)) ([e4cd856](https://github.com/nvim-tree/nvim-tree.lua/commit/e4cd856ebf4fec51db10c69d63e43224b701cbce))
* **#3124:** prevent empty icons_right_align response from breaking padding ([e4cd856](https://github.com/nvim-tree/nvim-tree.lua/commit/e4cd856ebf4fec51db10c69d63e43224b701cbce))
* **#3134:** setting one glyph to "" no longer disables others ([#3136](https://github.com/nvim-tree/nvim-tree.lua/issues/3136)) ([ebcaccd](https://github.com/nvim-tree/nvim-tree.lua/commit/ebcaccda1c575fa19a8087445276e6671e2b9b37))
* **#3143:** actions.open_file.window_picker.exclude applies when not using window picker ([#3144](https://github.com/nvim-tree/nvim-tree.lua/issues/3144)) ([05d8172](https://github.com/nvim-tree/nvim-tree.lua/commit/05d8172ebf9cdb2d140cf25b75625374fbc3df7f))
* fixes [#3134](https://github.com/nvim-tree/nvim-tree.lua/issues/3134) ([ebcaccd](https://github.com/nvim-tree/nvim-tree.lua/commit/ebcaccda1c575fa19a8087445276e6671e2b9b37))
* invalid buffer issue ([25d16aa](https://github.com/nvim-tree/nvim-tree.lua/commit/25d16aab7d29ca940a9feb92e6bb734697417009))

## [1.12.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.11.0...nvim-tree-v1.12.0) (2025-04-20)


### Features

* add TreePreOpen event ([#3105](https://github.com/nvim-tree/nvim-tree.lua/issues/3105)) ([c24c047](https://github.com/nvim-tree/nvim-tree.lua/commit/c24c0470d9de277fbebecd718f33561ed7c90298))


### Bug Fixes

* **#3101:** when renderer.highlight_opened_files = "none" do not reload on BufUnload and BufReadPost ([#3102](https://github.com/nvim-tree/nvim-tree.lua/issues/3102)) ([5bea2b3](https://github.com/nvim-tree/nvim-tree.lua/commit/5bea2b37523a31288e0fcab42f3be5c1bd4516bb))
* explicitly set `border` to `"none"` in full name float ([#3094](https://github.com/nvim-tree/nvim-tree.lua/issues/3094)) ([c3c1935](https://github.com/nvim-tree/nvim-tree.lua/commit/c3c193594213c5e2f89ec5d7729cad805f76b256))
* reliably dispatch exactly one TreeOpen and TreeClose events ([#3107](https://github.com/nvim-tree/nvim-tree.lua/issues/3107)) ([3a63717](https://github.com/nvim-tree/nvim-tree.lua/commit/3a63717d3d332d8f39aaf65be7a0e4c2265af021))

## [1.11.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.10.0...nvim-tree-v1.11.0) (2025-02-22)


### Features

* **#1984:** add quit_on_open and focus opts to various api.node.open functions ([#3054](https://github.com/nvim-tree/nvim-tree.lua/issues/3054)) ([3281f33](https://github.com/nvim-tree/nvim-tree.lua/commit/3281f331f7f0bef13eb00fb2d5a9d28b2f6155a2))
* **#3037:** add API node.buffer.delete, node.buffer.wipe ([#3040](https://github.com/nvim-tree/nvim-tree.lua/issues/3040)) ([fee1da8](https://github.com/nvim-tree/nvim-tree.lua/commit/fee1da88972f5972a8296813f6c00d7598325ebd))


### Bug Fixes

* **#3045:** wipe scratch buffers for full name and show info popups ([#3050](https://github.com/nvim-tree/nvim-tree.lua/issues/3050)) ([fca0b67](https://github.com/nvim-tree/nvim-tree.lua/commit/fca0b67c0b5a31727fb33addc4d9c100736a2894))
* **#3059:** test for presence of new 0.11 API vim.hl.range ([#3060](https://github.com/nvim-tree/nvim-tree.lua/issues/3060)) ([70825f2](https://github.com/nvim-tree/nvim-tree.lua/commit/70825f23db61ecd900c4cfea169bffe931926a9d))
* arithmetic on nil value error on first git project open ([#3064](https://github.com/nvim-tree/nvim-tree.lua/issues/3064)) ([8052310](https://github.com/nvim-tree/nvim-tree.lua/commit/80523101f0ae48b7f1990e907b685a3d79776c01))
* stl and stlnc fillchars are hidden in window picker ([b699143](https://github.com/nvim-tree/nvim-tree.lua/commit/b69914325a945ee5157f0d21047210b42af5776e))
* window picker: hide fillchars: stl and stlnc ([#3066](https://github.com/nvim-tree/nvim-tree.lua/issues/3066)) ([b699143](https://github.com/nvim-tree/nvim-tree.lua/commit/b69914325a945ee5157f0d21047210b42af5776e))

## [1.10.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.9.0...nvim-tree-v1.10.0) (2025-01-13)


### Features

* **api:** add node.open.vertical_no_picker, node.open.horizontal_no_picker ([#3031](https://github.com/nvim-tree/nvim-tree.lua/issues/3031)) ([68fc4c2](https://github.com/nvim-tree/nvim-tree.lua/commit/68fc4c20f5803444277022c681785c5edd11916d))


### Bug Fixes

* **#3015:** dynamic width no longer truncates on right_align icons ([#3022](https://github.com/nvim-tree/nvim-tree.lua/issues/3022)) ([f7b76cd](https://github.com/nvim-tree/nvim-tree.lua/commit/f7b76cd1a75615c8d6254fc58bedd2a7304eb7d8))
* **#3018:** error when focusing nvim-tree when in terminal mode ([#3019](https://github.com/nvim-tree/nvim-tree.lua/issues/3019)) ([db8d7ac](https://github.com/nvim-tree/nvim-tree.lua/commit/db8d7ac1f524fc6f808764b29fa695c51e014aa6))
* **#3041:** use vim.diagnostic.get for updating diagnostics ([#3042](https://github.com/nvim-tree/nvim-tree.lua/issues/3042)) ([aae0185](https://github.com/nvim-tree/nvim-tree.lua/commit/aae01853ddbd790d1efd6ff04ff96cf38c02c95f))
* Can't re-enter normal mode from terminal mode ([db8d7ac](https://github.com/nvim-tree/nvim-tree.lua/commit/db8d7ac1f524fc6f808764b29fa695c51e014aa6))
* hijack directory "BufEnter", "BufNewFile" events are nested ([#3044](https://github.com/nvim-tree/nvim-tree.lua/issues/3044)) ([39bc630](https://github.com/nvim-tree/nvim-tree.lua/commit/39bc63081605c1d4b974131ebecaea11e8a8595f))
* view.width functions may return strings ([#3020](https://github.com/nvim-tree/nvim-tree.lua/issues/3020)) ([6b4be1d](https://github.com/nvim-tree/nvim-tree.lua/commit/6b4be1dc0cd4d5d5b8e8b56b510a75016e99746f))

## [1.9.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.8.0...nvim-tree-v1.9.0) (2024-12-07)


### Features

* **#2948:** add custom decorators, :help nvim-tree-decorators ([#2996](https://github.com/nvim-tree/nvim-tree.lua/issues/2996)) ([7a4ff1a](https://github.com/nvim-tree/nvim-tree.lua/commit/7a4ff1a516fe92a5ed6b79d7ce31ea4d8f341a72))


### Bug Fixes

* **#2954:** more efficient LSP updates, increase diagnostics.debounce_delay from 50ms to 500ms ([#3007](https://github.com/nvim-tree/nvim-tree.lua/issues/3007)) ([1f3ffd6](https://github.com/nvim-tree/nvim-tree.lua/commit/1f3ffd6af145af2a4930a61c50f763264922c3fe))
* **#2990:** Do not check if buffer is buflisted in diagnostics.update() ([#2998](https://github.com/nvim-tree/nvim-tree.lua/issues/2998)) ([28eac28](https://github.com/nvim-tree/nvim-tree.lua/commit/28eac2801b201f301449e976d7a9e8cfde053ba3))
* **#3009:** nvim &lt; 0.10 apply view options locally ([#3010](https://github.com/nvim-tree/nvim-tree.lua/issues/3010)) ([ca7c4c3](https://github.com/nvim-tree/nvim-tree.lua/commit/ca7c4c33cac2ad66ec69d45e465379716ef0cc97))
* **api:** correct argument types in `wrap_node` and `wrap_node_or_nil` ([#3006](https://github.com/nvim-tree/nvim-tree.lua/issues/3006)) ([f7c65e1](https://github.com/nvim-tree/nvim-tree.lua/commit/f7c65e11d695a084ca10b93df659bb7e68b71f9f))

## [1.8.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.7.1...nvim-tree-v1.8.0) (2024-11-09)


### Features

* **#2819:** add actions.open_file.relative_path, default enabled, following successful experiment ([#2995](https://github.com/nvim-tree/nvim-tree.lua/issues/2995)) ([2ee1c5e](https://github.com/nvim-tree/nvim-tree.lua/commit/2ee1c5e17fdfbf5013af31b1410e4a5f28f4cadd))
* **#2938:** add default filesystem_watchers.ignore_dirs = { "/.ccls-cache", "/build", "/node_modules", "/target", } ([#2940](https://github.com/nvim-tree/nvim-tree.lua/issues/2940)) ([010ae03](https://github.com/nvim-tree/nvim-tree.lua/commit/010ae0365aafd6275c478d932515d2e8e897b7bb))


### Bug Fixes

* **#2945:** stack overflow on api.git.reload or fugitive event with watchers disabled ([#2949](https://github.com/nvim-tree/nvim-tree.lua/issues/2949)) ([5ad8762](https://github.com/nvim-tree/nvim-tree.lua/commit/5ad87620ec9d1190d15c88171a3f0122bc16b0fe))
* **#2947:** root is never a dotfile, so that it doesn't propagate to children ([#2958](https://github.com/nvim-tree/nvim-tree.lua/issues/2958)) ([f5f6789](https://github.com/nvim-tree/nvim-tree.lua/commit/f5f67892996b280ae78b1b0a2d07c4fa29ae0905))
* **#2951:** highlights incorrect following cancelled pick ([#2952](https://github.com/nvim-tree/nvim-tree.lua/issues/2952)) ([1c9553a](https://github.com/nvim-tree/nvim-tree.lua/commit/1c9553a19f70df3dcb171546a3d5e034531ef093))
* **#2954:** resolve occasional tree flashing on diagnostics, set tree buffer options in deterministic order ([#2980](https://github.com/nvim-tree/nvim-tree.lua/issues/2980)) ([82ab19e](https://github.com/nvim-tree/nvim-tree.lua/commit/82ab19ebf79c1839d7351f2fed213d1af13a598e))
* **#2961:** windows: escape brackets and parentheses when opening file ([#2962](https://github.com/nvim-tree/nvim-tree.lua/issues/2962)) ([63c7ad9](https://github.com/nvim-tree/nvim-tree.lua/commit/63c7ad9037fb7334682dd0b3a177cee25c5c8a0f))
* **#2969:** After a rename, the node loses selection ([#2974](https://github.com/nvim-tree/nvim-tree.lua/issues/2974)) ([1403933](https://github.com/nvim-tree/nvim-tree.lua/commit/14039337a563f4efd72831888f332a15585f0ea1))
* **#2972:** error on :colorscheme ([#2973](https://github.com/nvim-tree/nvim-tree.lua/issues/2973)) ([6e5a204](https://github.com/nvim-tree/nvim-tree.lua/commit/6e5a204ca659bb8f2a564df75df2739edec03cb0))
* **#2976:** use vim.loop to preserve neovim 0.9 compatibility ([#2977](https://github.com/nvim-tree/nvim-tree.lua/issues/2977)) ([00dff48](https://github.com/nvim-tree/nvim-tree.lua/commit/00dff482f9a8fb806a54fd980359adc6cd45d435))
* **#2978:** grouped folder not showing closed icon ([#2979](https://github.com/nvim-tree/nvim-tree.lua/issues/2979)) ([120ba58](https://github.com/nvim-tree/nvim-tree.lua/commit/120ba58254835d412bbc91cffe847e9be835fadd))
* **#2981:** windows: root changed when navigating with LSP ([#2982](https://github.com/nvim-tree/nvim-tree.lua/issues/2982)) ([c22124b](https://github.com/nvim-tree/nvim-tree.lua/commit/c22124b37409bee6d1a0da77f4f3a1526f7a204d))
* symlink file icons rendered when renderer.icons.show.file = false, folder.symlink* was incorrectly rendered as folder.default|open ([#2983](https://github.com/nvim-tree/nvim-tree.lua/issues/2983)) ([2156bc0](https://github.com/nvim-tree/nvim-tree.lua/commit/2156bc08c982d3c4b4cfc2b8fd7faeff58a88e10))

## [1.7.1](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.7.0...nvim-tree-v1.7.1) (2024-09-30)


### Bug Fixes

* **#2794:** sshfs compatibility ([#2922](https://github.com/nvim-tree/nvim-tree.lua/issues/2922)) ([9650e73](https://github.com/nvim-tree/nvim-tree.lua/commit/9650e735baad0d39505f4cb4867a60f02858536a))
* **#2928:** nil explorer in parent move action ([#2929](https://github.com/nvim-tree/nvim-tree.lua/issues/2929)) ([0429f28](https://github.com/nvim-tree/nvim-tree.lua/commit/0429f286b350c65118d66b646775bf187936fa47))
* **#2930:** empty groups expanded on reload ([#2935](https://github.com/nvim-tree/nvim-tree.lua/issues/2935)) ([4520c03](https://github.com/nvim-tree/nvim-tree.lua/commit/4520c0355cc561830ee2cf90dc37a2a75abf7995))
* invalid explorer on open ([#2927](https://github.com/nvim-tree/nvim-tree.lua/issues/2927)) ([59a8a6a](https://github.com/nvim-tree/nvim-tree.lua/commit/59a8a6ae5e9d3eae99d08ab655d12fd51d5d17f3))


### Reverts

* **#2794:** sshfs compatibility ([#2920](https://github.com/nvim-tree/nvim-tree.lua/issues/2920)) ([8405ecf](https://github.com/nvim-tree/nvim-tree.lua/commit/8405ecfbd6bb08a94ffc9c68fef211eea56e8a3b))

## [1.7.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.6.1...nvim-tree-v1.7.0) (2024-09-21)


### Features

* **#2430:** use vim.ui.open as default system_open, for neovim 0.10+ ([#2912](https://github.com/nvim-tree/nvim-tree.lua/issues/2912)) ([03f737e](https://github.com/nvim-tree/nvim-tree.lua/commit/03f737e5744a2b3ebb4b086f7636a3399224ec0c))
* help closes on &lt;Esc&gt; and api.tree.toggle_help mappings ([#2909](https://github.com/nvim-tree/nvim-tree.lua/issues/2909)) ([b652dbd](https://github.com/nvim-tree/nvim-tree.lua/commit/b652dbd0e0489c5fbb81fbededf0d99029cd2f38))


### Bug Fixes

* **#2862:** windows path replaces backslashes with forward slashes ([#2903](https://github.com/nvim-tree/nvim-tree.lua/issues/2903)) ([45a93d9](https://github.com/nvim-tree/nvim-tree.lua/commit/45a93d99794fff3064141d5b3a50db98ce352697))
* **#2906:** resource leak on populate children ([#2907](https://github.com/nvim-tree/nvim-tree.lua/issues/2907)) ([a4dd5ad](https://github.com/nvim-tree/nvim-tree.lua/commit/a4dd5ad5c8f9349142291d24e0e6466995594b9a))
* **#2917:** fix root copy paths: Y, ge, gy, y ([#2918](https://github.com/nvim-tree/nvim-tree.lua/issues/2918)) ([b18ce8b](https://github.com/nvim-tree/nvim-tree.lua/commit/b18ce8be8f162eee0bc37addcfe17d7d019fcec7))
* safely close last tree window ([#2913](https://github.com/nvim-tree/nvim-tree.lua/issues/2913)) ([bd48816](https://github.com/nvim-tree/nvim-tree.lua/commit/bd4881660bf0ddfa6acb21259f856ba3dcb26a93))
* safely close tree window with pcall and debug logging ([bd48816](https://github.com/nvim-tree/nvim-tree.lua/commit/bd4881660bf0ddfa6acb21259f856ba3dcb26a93))

## [1.6.1](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.6.0...nvim-tree-v1.6.1) (2024-09-09)


### Bug Fixes

* **#2794:** sshfs compatibility ([#2893](https://github.com/nvim-tree/nvim-tree.lua/issues/2893)) ([2d6e64d](https://github.com/nvim-tree/nvim-tree.lua/commit/2d6e64dd8c45a86f312552b7a47eef2c8623a25c))
* **#2868:** windows: do not visit unenumerable directories such as Application Data ([#2874](https://github.com/nvim-tree/nvim-tree.lua/issues/2874)) ([2104786](https://github.com/nvim-tree/nvim-tree.lua/commit/210478677cb9d672c4265deb0e9b59d58b675bd4))
* **#2878:** nowrapscan prevents move from root ([#2880](https://github.com/nvim-tree/nvim-tree.lua/issues/2880)) ([4234095](https://github.com/nvim-tree/nvim-tree.lua/commit/42340952af598a08ab80579d067b6da72a9e6d29))
* **#2879:** remove unnecessary tree window width setting to prevent unnecessary :wincmd = ([#2881](https://github.com/nvim-tree/nvim-tree.lua/issues/2881)) ([d43ab67](https://github.com/nvim-tree/nvim-tree.lua/commit/d43ab67d0eb4317961c5e9d15fffe908519debe0))

## [1.6.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.5.0...nvim-tree-v1.6.0) (2024-08-10)


### Features

* **#2225:** add renderer.hidden_display to show a summary of hidden files below the tree ([#2856](https://github.com/nvim-tree/nvim-tree.lua/issues/2856)) ([e25eb7f](https://github.com/nvim-tree/nvim-tree.lua/commit/e25eb7fa83f7614bb23d762e91d2de44fcd7103b))
* **#2349:** add "right_align" option for renderer.icons.*_placement ([#2839](https://github.com/nvim-tree/nvim-tree.lua/issues/2839)) ([1d629a5](https://github.com/nvim-tree/nvim-tree.lua/commit/1d629a5d3f7d83d516494c221a2cfc079f43bc47))
* **#2349:** add "right_align" option for renderer.icons.*_placement ([#2846](https://github.com/nvim-tree/nvim-tree.lua/issues/2846)) ([48d0e82](https://github.com/nvim-tree/nvim-tree.lua/commit/48d0e82f9434691cc50d970898142a8c084a49d6))
* add renderer.highlight_hidden, renderer.icons.show.hidden and renderer.icons.hidden_placement for dotfile icons/highlights ([#2840](https://github.com/nvim-tree/nvim-tree.lua/issues/2840)) ([48a9290](https://github.com/nvim-tree/nvim-tree.lua/commit/48a92907575df1dbd7242975a04e98169cb3a115))


### Bug Fixes

* **#2859:** make sure window still exists when restoring options ([#2863](https://github.com/nvim-tree/nvim-tree.lua/issues/2863)) ([466fbed](https://github.com/nvim-tree/nvim-tree.lua/commit/466fbed3e4b61fcc23a48fe99de7bfa264a9fee8))

## [1.5.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.4.0...nvim-tree-v1.5.0) (2024-07-11)


### Features

* **#2127:** add experimental.actions.open_file.relative_path to open files with a relative path rather than absolute ([#2805](https://github.com/nvim-tree/nvim-tree.lua/issues/2805)) ([869c064](https://github.com/nvim-tree/nvim-tree.lua/commit/869c064721a6c2091f22c3541e8f0ff958361771))
* **#2598:** add api.tree.resize ([#2811](https://github.com/nvim-tree/nvim-tree.lua/issues/2811)) ([2ede0de](https://github.com/nvim-tree/nvim-tree.lua/commit/2ede0de67b47e89e2b4cb488ea3f58b8f5a8c90a))
* **#2799:** `filesystem_watchers.ignore_dirs` and `git.disable_for_dirs` may be functions ([#2800](https://github.com/nvim-tree/nvim-tree.lua/issues/2800)) ([8b2c5c6](https://github.com/nvim-tree/nvim-tree.lua/commit/8b2c5c678be4b49dff6a2df794877000113fd77b))
* **#2799:** filesystem_watchers.ignore_dirs and git.disable_for_dirs may be functions ([8b2c5c6](https://github.com/nvim-tree/nvim-tree.lua/commit/8b2c5c678be4b49dff6a2df794877000113fd77b))


### Bug Fixes

* **#2813:** macos: enable file renaming with changed capitalization ([#2814](https://github.com/nvim-tree/nvim-tree.lua/issues/2814)) ([abfd1d1](https://github.com/nvim-tree/nvim-tree.lua/commit/abfd1d1b6772540364743531cc0331e08a0027a9))
* **#2819:** experimental.actions.open_file.relative_path issue following change directory ([#2820](https://github.com/nvim-tree/nvim-tree.lua/issues/2820)) ([12a9a99](https://github.com/nvim-tree/nvim-tree.lua/commit/12a9a995a455d2c2466e47140663275365a5d2fc))

## [1.4.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.3.3...nvim-tree-v1.4.0) (2024-06-09)

### Notice

* Neovim 0.9 is now the minimum supported version; please upgrade to neovim release version 0.9 or 0.10.

### Reverts

* **#2781:** "refactor: replace deprecated use of vim.diagnostic.is_disabled()" ([#2784](https://github.com/nvim-tree/nvim-tree.lua/issues/2784)) ([517e4fb](https://github.com/nvim-tree/nvim-tree.lua/commit/517e4fbb9ef3c0986da7047f44b4b91a2400f93c))


### Miscellaneous Chores

* release 1.4.0 ([1cac800](https://github.com/nvim-tree/nvim-tree.lua/commit/1cac8005df6da484c97499247754afa59fef92db))

## [1.3.3](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.3.2...nvim-tree-v1.3.3) (2024-05-14)


### Bug Fixes

* nil access exception with git integration when changing branches ([#2774](https://github.com/nvim-tree/nvim-tree.lua/issues/2774)) ([340d3a9](https://github.com/nvim-tree/nvim-tree.lua/commit/340d3a9795e06bdd1814228de398cd510f9bfbb0))

## [1.3.2](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.3.1...nvim-tree-v1.3.2) (2024-05-12)


### Bug Fixes

* **#2758:** use nvim-webdevicons default file icon, not renderer.icons.glyphs.default, as per :help ([#2759](https://github.com/nvim-tree/nvim-tree.lua/issues/2759)) ([347e1eb](https://github.com/nvim-tree/nvim-tree.lua/commit/347e1eb35264677f66a79466bb5e3d111968e12c))
* **#2758:** use nvim-webdevicons default for default files ([347e1eb](https://github.com/nvim-tree/nvim-tree.lua/commit/347e1eb35264677f66a79466bb5e3d111968e12c))
* **#925:** handle newlines in file names ([#2754](https://github.com/nvim-tree/nvim-tree.lua/issues/2754)) ([64f61e4](https://github.com/nvim-tree/nvim-tree.lua/commit/64f61e4c913047a045ff90bd188dd3b54ee443cf))

## [1.3.1](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.3.0...nvim-tree-v1.3.1) (2024-04-25)


### Bug Fixes

* **#2535:** TextYankPost event sends vim.v.event ([#2734](https://github.com/nvim-tree/nvim-tree.lua/issues/2734)) ([d8d3a15](https://github.com/nvim-tree/nvim-tree.lua/commit/d8d3a1590a05b2d8b5eb26e2ed1c6052b1b47a77))
* **#2733:** escape trash path ([#2735](https://github.com/nvim-tree/nvim-tree.lua/issues/2735)) ([81eb8d5](https://github.com/nvim-tree/nvim-tree.lua/commit/81eb8d519233c105f30dc0a278607e62b20502fd))

## [1.3.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.2.0...nvim-tree-v1.3.0) (2024-03-30)


### Features

* add update_focused_file.exclude  ([#2673](https://github.com/nvim-tree/nvim-tree.lua/issues/2673)) ([e20966a](https://github.com/nvim-tree/nvim-tree.lua/commit/e20966ae558524f8d6f93dc37f5d2a8605f893e2))


### Bug Fixes

* **#2658:** change SpellCap groups to reduce confusion: ExecFile-&gt;Question, ImageFile->Question, SpecialFile->Title, Symlink->Underlined; add all other highlight groups to :NvimTreeHiTest ([#2732](https://github.com/nvim-tree/nvim-tree.lua/issues/2732)) ([0aca092](https://github.com/nvim-tree/nvim-tree.lua/commit/0aca0920f44b12a8383134bcb52da9faec123608))
* bookmark filter shows marked directory children ([#2719](https://github.com/nvim-tree/nvim-tree.lua/issues/2719)) ([2d97059](https://github.com/nvim-tree/nvim-tree.lua/commit/2d97059661c83787372c8c003e743c984ba3ac50))

## [1.2.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.1.1...nvim-tree-v1.2.0) (2024-03-24)


### Features

* add api.tree.toggle_enable_filters ([#2706](https://github.com/nvim-tree/nvim-tree.lua/issues/2706)) ([f7c09bd](https://github.com/nvim-tree/nvim-tree.lua/commit/f7c09bd72e50e1795bd3afb9e2a2b157b4bfb3c3))

## [1.1.1](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.1.0...nvim-tree-v1.1.1) (2024-03-15)


### Bug Fixes

* **#2395:** marks.bulk.move defaults to directory at cursor ([#2688](https://github.com/nvim-tree/nvim-tree.lua/issues/2688)) ([cfea5bd](https://github.com/nvim-tree/nvim-tree.lua/commit/cfea5bd0806aab41bef6014c6cf5a510910ddbdb))
* **#2705:** change NvimTreeWindowPicker cterm background from Cyan to more visible DarkBlue ([#2708](https://github.com/nvim-tree/nvim-tree.lua/issues/2708)) ([1fd9c98](https://github.com/nvim-tree/nvim-tree.lua/commit/1fd9c98960463d2d5d400916c0633b2df016941d))
* bookmark filter should include parent directory ([#2704](https://github.com/nvim-tree/nvim-tree.lua/issues/2704)) ([76b9810](https://github.com/nvim-tree/nvim-tree.lua/commit/76b98109f62caa12b2f1dff472060b2233ea2e90))

## [1.1.0](https://github.com/nvim-tree/nvim-tree.lua/compare/nvim-tree-v1.0.0...nvim-tree-v1.1.0) (2024-03-14)


### Features

* **#2630:** file renames can now create directories ([#2657](https://github.com/nvim-tree/nvim-tree.lua/issues/2657)) ([efafd73](https://github.com/nvim-tree/nvim-tree.lua/commit/efafd73efa9bc8c26282aed563ba0f01c7465b06))
* add api.fs.copy.basename, default mapping ge ([#2698](https://github.com/nvim-tree/nvim-tree.lua/issues/2698)) ([8f2a50f](https://github.com/nvim-tree/nvim-tree.lua/commit/8f2a50f1cd0c64003042364cf317c8788eaa6c8c))


### Bug Fixes

* **#2695:** git toplevel guard against missing paths ([#2696](https://github.com/nvim-tree/nvim-tree.lua/issues/2696)) ([3c4267e](https://github.com/nvim-tree/nvim-tree.lua/commit/3c4267eb5045fa86b67fe40c0c63d31efc801e77))
* searchcount exception on invalid search regex ([#2693](https://github.com/nvim-tree/nvim-tree.lua/issues/2693)) ([041dbd1](https://github.com/nvim-tree/nvim-tree.lua/commit/041dbd18f440207ad161503a384e7c82d575db66))

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
