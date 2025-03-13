Generates [nixcats.org](https://nixcats.org), the documentation site for [nixCats-nvim](https://github.com/BirdeeHub/nixCats-nvim), via neovim's TOhtml for in-editor help files and pandoc for readme and table of contents.
```bash
nix run --no-write-lock-file github:BirdeeHub/nixCats-doc -- "$OUTPATH"

nix run --no-write-lock-file --override-input nixCats /path/to/local/nixCats-nvim github:BirdeeHub/nixCats-doc -- "$OUTPATH"

nix run --refresh --no-write-lock-file github:BirdeeHub/nixCats-doc -- "$OUTPATH"

nix run --refresh --no-write-lock-file --override-input nixCats /path/to/local/nixCats-nvim github:BirdeeHub/nixCats-doc -- "$OUTPATH"
```

or in a github action

```yaml
name: update-website
on:
  workflow_dispatch: # allows manual triggering
  repository_dispatch: # or triggering from another repo
    types: [update-nixcats-website]

jobs:
  lockfile:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.PAT }}
      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@main
      - name: Update Site
        run: |
          nix run --refresh --show-trace --no-write-lock-file github:BirdeeHub/nixCats-doc -- "$(realpath .)"
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git add .
          git commit -m "update site with changes"
          git push
```
