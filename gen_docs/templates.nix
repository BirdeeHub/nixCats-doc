{ APPNAME
, nixCats
, nixdoc
, system
, writeShellScriptBin
, ...
}: let
  docfile = "${nixCats}/templates/default.nix";
in
writeShellScriptBin APPNAME ''
  ${nixdoc.packages.${system}.default}/bin/nixdoc --category "templates" --description "nixCats.templates set documentation" --file ${docfile} --prefix "nixCats"
''
