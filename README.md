Generates [nixcats.org](https://nixcats.org), the documentation site for [nixCats-nvim](https://github.com/BirdeeHub/nixCats-nvim), via neovim's TOhtml for in-editor help files and pandoc for readme and table of contents.
```bash
nix run --no-write-lock-file github:BirdeeHub/nixCats-doc # -- "$OUTPATH"

nix run --no-write-lock-file --override-input nixCats /path/to/local/nixCats-nvim github:BirdeeHub/nixCats-doc # -- "$OUTPATH"

nix run --refresh --no-write-lock-file github:BirdeeHub/nixCats-doc # -- "$OUTPATH"

nix run --refresh --no-write-lock-file --override-input nixCats /path/to/local/nixCats-nvim github:BirdeeHub/nixCats-doc # -- "$OUTPATH"
```
