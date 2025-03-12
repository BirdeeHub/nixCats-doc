{ nixCats
, nixdoc
, system
, runCommandNoCC
, ...
}: let
  docfile = "${nixCats}/utils/default.nix";
in
runCommandNoCC "GenCatUtilDoc" {} ''
  cat ${./utilnote.md} > $out
  echo >> $out
  ${nixdoc.packages.${system}.default}/bin/nixdoc --category "utils" --description "nixCats.utils set documentation" --file ${docfile} --prefix "nixCats" >> $out
''
