# Welcome to nixCats!

If you are new to nixCats, check out the [installation documentation](./nixCats_installation.html)!

The nixCats.utils set is the entire interface of nixCats.

It requires no dependencies, or arguments to access this set.

Most importantly it exports the main builder function, [utils.baseBuilder](#function-library-nixCats.utils.baseBuilder).

The flake and expression based [templates](./nixCats_templates.html) show how to call this function directly,
and use some of the other functions in this set to construct various flake outputs.

The modules use the main builder function internally and install the result.

It also contains the functions for creating modules,
along with various other utilities for working with the nix side of Neovim or nixCats that you may want to use.

---

