Generates [nixcats.org](https://nixcats.org), the documentation site for [nixCats-nvim](https://github.com/BirdeeHub/nixCats-nvim), via neovim's TOhtml for in-editor help files and pandoc for readme and table of contents.

```bash
nix run github:BirdeeHub/nixCats-doc -- $OUTPATH

nix run file --override-input nixCats /path/to/local/nixCats-nvim github:BirdeeHub/nixCats-doc -- $OUTPATH

./test.sh $OUTPATH /path/to/local/nixCats-nvim

./test.sh $OUTPATH
```
