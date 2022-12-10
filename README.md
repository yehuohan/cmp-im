# cmp-im

Input Method source.


## Setup

```lua
require('cmp_im').setup {
  enable = false,
  tables = { },
  format = function(key, text) return vim.fn.printf('%-15S %s', text, key) end,
  maxn = 8,
}
```


## Tables

- https://github.com/ZSaberLv0/ZFVimIM#db-samples
- https://kgithub.com/fcitx/fcitx-table-extra
- https://kgithub.com/fcitx/fcitx-table-data
