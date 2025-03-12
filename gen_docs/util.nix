{ nixCats
, nixdoc
, system
, writeShellScript
, ...
}: let
  docfile = "${nixCats}/utils/default.nix";
in
writeShellScript "GenCatUtilDoc" ''
  cat ${./utilnote.md}
  echo
  ${nixdoc.packages.${system}.default}/bin/nixdoc --category "utils" --description "nixCats.utils set documentation" --file ${docfile} --prefix "nixCats"
''
