
---

# A note about `<defaultPackageName>`:

The nixCats modules are created by the
[utils.mkNixosModules](./nixCats_utils.html#function-library-nixCats.utils.mkNixosModules)
and 
[utils.mkHomeModules](./nixCats_utils.html#function-library-nixCats.utils.mkHomeModules)
functions.

The string you pass as `defaultPackageName` to the function is used as the prefix for the module options.

If you wish to customize the module namespace further,
you may provide a list of strings as `moduleNamespace` to the function and set it to any arbitrary attribute path

The module offered by the base [nixCats flake](https://github.com/BirdeeHub/nixCats-nvim/blob/main/flake.nix) has set `defaultPackageName` to `nixCats`
