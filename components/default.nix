{
  lib,
  system,
  nixCats,
  runCommandNoCC,
  nixdoc,
  writeTextFile,
  luajit,
  nixosOptionsDoc,
  ...
}: let
  templates = lib.pipe nixCats.utils.templates [
    builtins.attrNames
    (map (v: lib.nameValuePair "templates.${v}" "./nixCats_templates.html#${lib.toLower v}"))
    builtins.listToAttrs
    nixCats.utils.n2l.toLua
  ];
  luaEnv = luajit.withPackages (lp: with lp; [ cjson inspect ]);
  luascript = writeTextFile {
    name = "json_gen_lua";
    text = /*lua*/ ''
      #!${luaEnv.interpreter}
      package.preload["nixinfo"] = function()
        return { templates = ${templates} }
      end
      dofile("${./gen.lua}")
    '';
    executable = true;
  };
  optionsDoc = isHomeManager: let
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
  in nixosOptionsDoc { inherit (eval'd) options; };
  nix-doc = "${nixdoc.packages.${system}.default}/bin/nixdoc";
in runCommandNoCC "tag_json_gen" {} ''
  TEMPDIR=$(mktemp -d)
  mkdir -p "$TEMPDIR"
  cleanup() {
    rm -rf "$TEMPDIR" || true
  }
  trap cleanup EXIT
  ${nix-doc} -j --category "utils" --description "nixCats.utils set documentation" --prefix "nixCats" --file ${nixCats}/utils/default.nix > $TEMPDIR/utils.json
  cp ${(optionsDoc true).optionsJSON}/share/doc/nixos/options.json $TEMPDIR/HM.json
  cp ${(optionsDoc false).optionsJSON}/share/doc/nixos/options.json $TEMPDIR/nixos.json
  echo "{" > $TEMPDIR/tags.json
  awk '{printf "  "} NR > 1 {printf ", "} {sub(/\.txt$/, ".html", $2); print "\"" $1 "\": \"./" $2 "\""}' ${nixCats}/nixCatsHelp/tags >> $TEMPDIR/tags.json
  echo "}" >> $TEMPDIR/tags.json
  ${luascript} $TEMPDIR $out
  rm -rf "$TEMPDIR" || true
''
