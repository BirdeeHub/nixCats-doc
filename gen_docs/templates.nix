{ nixCats
, luajit
, writeTextFile
, ...
}: with builtins; let
  templates = nixCats.utils.n2l.toLua (mapAttrs (n: v: {
    inherit (v) path description;
    name = n;
  }) nixCats.utils.templates);
in writeTextFile {
  name = "GenCatTemplateDoc";
  text = /*lua*/ ''
    #!${luajit.interpreter}
    package.preload["nixinfo"] = function()
      return { nixCats = "${nixCats}", templates = ${templates} }
    end
    dofile("${./templateMDgen.lua}")
  '';
  executable = true;
}
