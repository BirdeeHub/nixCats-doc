{ isHomeManager ? false
, nixCats
, lib
, nixosOptionsDoc
, runCommandNoCC
, ...
}: let
  eval'd = lib.evalModules {
    modules = [
      { _module.check = false; }
      (import "${nixCats}/utils/mkOpts.nix" {
        inherit isHomeManager;
        defaultPackageName = "<defaultPackageName>";
      })
    ];
    specialArgs = { inherit lib; };
  };
  optionsDoc = nixosOptionsDoc { inherit (eval'd) options; };
in
runCommandNoCC (if isHomeManager then "GenCatHMdoc" else "GenCatModDoc") {} ''
  cat ${optionsDoc.optionsCommonMark} > $out
  echo >> $out
  cat ${./modulefootnote.md} >> $out
''
