{ APPNAME
, nixCats
, nixdoc
, system
, writeShellScriptBin
, ...
}: let
  docfile = "${nixCats}/utils/default.nix";
in
writeShellScriptBin APPNAME ''
  cat <<EOF
  # Welcome to nixCats!

  If you are new to nixCats, check out the [installation documentation](https://nixcats.org/nixCats_installation.html)!

  The nixCats.utils set is the entire interface of nixCats.

  It requires no dependencies, or arguments to access this set.

  Most importantly it exports the main builder function, [utils.baseBuilder](#function-library-nixCats.utils.baseBuilder).

  The flake and expression based [templates](https://nixcats.org/nixCats_templates.html) show how to call this function directly, and use some of the other functions in this set.

  The modules use the main builder function internally and install the result.

  It also contains the functions for creating modules,
  along with various other utilities for working with the nix side of neovim or nixCats that you may want to use.

  EOF
  ${nixdoc.packages.${system}.default}/bin/nixdoc --category "utils" --description "nixCats.utils set documentation" --file ${docfile} --prefix "nixCats"
''
