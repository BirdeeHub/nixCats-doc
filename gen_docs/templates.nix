{ nixCats
, luajit
, writeTextFile
, runCommandNoCC
, ...
}: with builtins; let
  templates = nixCats.utils.n2l.toLua (mapAttrs (name: v: {
    inherit (v) description;
    inherit name;
  }) nixCats.utils.templates);
  genlua = writeTextFile {
    name = "GenTemplateDocsLua";
    text = /*lua*/ ''
      #!${luajit.interpreter}
      package.preload["templates_nix"] = function()
        return ${templates}
      end
      dofile("${./templateMDgen.lua}")
    '';
    executable = true;
  };
in runCommandNoCC "GenCatTemplateDoc" {} ''
  ${genlua} $out
''
