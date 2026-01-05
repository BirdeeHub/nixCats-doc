{
  lib,
  stdenv,
  nixCats,
  runLuaCommand,
  nixdoc,
  lua5_2,
  nixosOptionsDoc,
  ...
}: let
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
  in "${(nixosOptionsDoc { inherit (eval'd) options; }).optionsJSON}/share/doc/nixos/options.json";
in runLuaCommand "gen_web_component" (lua5_2.withPackages (ps: with ps; [ cjson ])).interpreter {
  nativeBuildInputs = [ nixdoc.packages.${stdenv.hostPlatform.system}.default ];
  passthru = {
    templates = lib.pipe nixCats.utils.templates [
      builtins.attrNames
      (map (v: lib.nameValuePair "templates.${v}" "./nixCats_templates.html#${lib.toLower v}"))
      builtins.listToAttrs
    ];
  };
} /*lua*/ ''
  sh.escape_args = true
  sh.mkdir("-p", out)
  local utils_json = tostring(sh.nixdoc {
    j = true,
    category = "utils",
    description = "nixCats.utils set documentation",
    prefix = "nixCats",
    file = "${nixCats}/utils/default.nix"
  })
  local hm_json = os.read_file "${optionsDoc true}"
  local nixos_json = os.read_file "${optionsDoc false}"
  local tags_json = "{\n" .. tostring(
    sh.awk([[{printf "  "} NR > 1 {printf ", "} {sub(/\.txt$/, ".html", $2); print "\"" $1 "\": \"./" $2 "\""}]], "${nixCats}/nixCatsHelp/tags")
  ) .. "\n}"

  local cjson = require('cjson.safe')

  local result = drv.templates
  for k, v in pairs(cjson.decode(tags_json)) do
    result[k] = v .. "#" .. k
  end
  for _, v in ipairs(cjson.decode(utils_json).entries) do
    result["utils."..v.name] = "./nixCats_utils.html#function-library-nixCats.utils." .. v.name
  end

  local hm_json = cjson.decode(hm_json)
  local nixos_json = cjson.decode(nixos_json)
  hm_json["_module.args"] = nil
  nixos_json["_module.args"] = nil

  local function link_strip(name)
    return string.lower(name:gsub("[^%w%.]", ""))
  end
  for k, _ in pairs(hm_json) do
    result["home-manager."..k] = "./nixCats_hm_options.html#" .. link_strip(k)
  end
  for k, _ in pairs(nixos_json) do
    result["nixos."..k] = "./nixCats_nixos_options.html#" .. link_strip(k)
  end

  os.write_file({}, out .. "/suggestions.json", cjson.encode(result))
  sh.cp("${./vim-help.js}", out .. "/vim-help.js")
''
