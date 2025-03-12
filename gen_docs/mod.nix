{ isHomeManager ? false
, nixCats
, lib
, nixosOptionsDoc
, writeShellScript
, ...
}: let
  eval'd = lib.evalModules {
    modules = [
      { _module.check = false; }
      (import "${nixCats}/utils/mkOpts.nix" {
        inherit isHomeManager;
        nclib = import "${nixCats}/utils/lib.nix";
        defaultPackageName = "<defaultPackageName>";
      })
    ];
    specialArgs = { inherit lib; };
  };
  optionsDoc = nixosOptionsDoc { inherit (eval'd) options; };
in
writeShellScript (if isHomeManager then "GenCatHMdoc" else "GenCatModDoc") ''
  cat ${optionsDoc.optionsCommonMark}
  echo
  cat ${./modulefootnote.md}
''
