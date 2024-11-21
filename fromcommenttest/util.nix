{ APPNAME
, nixCats
, nixdoc
, lib
, system
, writeShellScriptBin
, ...
}: let
  docfile = "${nixCats}/utils/default.nix";
in
writeShellScriptBin APPNAME ''
  ${nixdoc.packages.${system}.default}/bin/nixdoc --category "utils" --description "nixCats.utils set documentation" --file ${docfile} --prefix "nixCats"
''
