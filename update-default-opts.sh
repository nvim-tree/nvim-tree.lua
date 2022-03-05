#!/bin/sh

# scrapes DEFAULT_OPTS from nvim-tree.lua and updates: README.md, nvim-tree-lua.txt, bug_report.yml
# uses leading/trailing spaces hack for yml and help, as we cannot leave comments / invisibles in text blocks

begin="BEGIN_DEFAULT_OPTS"
end="END_DEFAULT_OPTS"

# scrape, indented at 2
sed -n -e "/${begin}/,/${end}/{ /${begin}/d; /${end}/d; p; }" lua/nvim-tree.lua > /tmp/DEFAULT_OPTS.2.lua

# indent some more
sed -e "s/^  /      /" /tmp/DEFAULT_OPTS.2.lua > /tmp/DEFAULT_OPTS.6.lua
sed -e "s/^  /          /" /tmp/DEFAULT_OPTS.2.lua > /tmp/DEFAULT_OPTS.10.lua

# README.md indented at 2
sed -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_OPTS.2.lua
        }; /${end}/p; d }" README.md > /tmp/README.md
mv /tmp/README.md README.md

# help, indented at 6
begin="^    require'nvim-tree'.setup {        $"
end="^    }        $"
sed -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_OPTS.6.lua
        s/  /aoeu/g; }; /${end}/p; d }" doc/nvim-tree-lua.txt > /tmp/nvim-tree-lua.txt
mv /tmp/nvim-tree-lua.txt doc/nvim-tree-lua.txt

# bug_report.yml indented at 10
begin="^        require'nvim-tree'.setup {        $"
end="^        }        $"
sed -e "/${begin}/,/${end}/{ /${begin}/{p; r /tmp/DEFAULT_OPTS.10.lua
        }; /${end}/p; d }" .github/ISSUE_TEMPLATE/bug_report.yml > /tmp/bug_report.yml
mv /tmp/bug_report.yml .github/ISSUE_TEMPLATE/bug_report.yml

