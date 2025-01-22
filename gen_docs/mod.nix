{ APPNAME
, isHomeManager ? false
, nixCats
, lib
, nixosOptionsDoc
, writeShellScriptBin
, ...
}: let
  eval'd = lib.evalModules {
    modules = [
      { _module.check = false; }
      (import "${nixCats}/utils/mkOpts.nix" {
        inherit isHomeManager;
        inherit (nixCats) utils;
        nclib = import "${nixCats}/utils/lib.nix";
        defaultPackageName = "<defaultPackageName>";
      })
    ];
    specialArgs = { inherit lib; };
  };
  optionsDoc = nixosOptionsDoc { inherit (eval'd) options; };
in
writeShellScriptBin APPNAME ''
  cat ${optionsDoc.optionsCommonMark}
  echo
  cat ${./modulefootnote.md}
''
