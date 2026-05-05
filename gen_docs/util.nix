{ nixCats
, nixdoc
, runCommand
, ...
}: let
  docfile = "${nixCats}/utils/default.nix";
in
runCommand "GenCatUtilDoc" {} ''
  cat ${./utilnote.md} > $out
  echo >> $out
  ${nixdoc}/bin/nixdoc --category "utils" --description "nixCats.utils set documentation" --file ${docfile} --prefix "nixCats" >> $out
''
