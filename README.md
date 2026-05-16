# TexCount
Plugin that wraps the `texcount` utility to check the frequency of the words used in a
$\LaTeX$ project.

## Requirements
- [`texcount`](https://app.uio.no/ifi/texcount/) installed and available in your `$PATH`
- [`ripgrep`](https://github.com/BurntSushi/ripgrep) (`rg`) for occurrence search

## Features
- Color-coded highlights based on word frequency.
- Jump to any occurrence of a word directly from the frequency window.
- Add/remove words from a per-project ignore list.

## Setup
### Install
- lazy:
```lua
{
  "MarcosLopezM/texcount.nvim",
  ft = { "tex", "plaintex" },
  config = function()
    require("texcount").setup({
      min_freq = 2, -- minimum frequency to display a word
      keymaps = {
        run    = "<leader>tc",
        add    = "<leader>ta",
        delete = "<leader>td",
      },
    })
  end,
}
```

## Commands
| Command                | Description                               |
|------------------------|-------------------------------------------|
| `:TexCount`            | Run texcount on the current file          |
| `:TexCountAddIgnore`   | Add word under cursor to the ignore list  |
| `:TexCountDeleteIgnore`| Remove word under cursor from ignore list |

## Keymaps (inside the frequency window)
| Key    | Action                              |
|--------|-------------------------------------|
| `t`    | Toggle between top 15 and all words |
| `i`    | Show the words been ignored         |
| `<CR>` | Jump to word occurrence             |
| `q`    | Close window                        |
| `<Esc>`| Close window                        |

## Ignore list
Words can be ignored globally or per project. TexCount looks for an `ignore.txt` file
in the current working directory first, falling back to `~/.local/share/nvim/ignore.txt`.
