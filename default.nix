{ nixpkgs, nixCats, ... }@inputs: system: let
  genvim = import ./genvim.nix inputs system;
  pkgs = import nixpkgs { inherit system; };
  helpPath = if builtins.pathExists "${nixCats}/nixCatsHelp" then "${nixCats}/nixCatsHelp" else "${nixCats}/nix/nixCatsHelp";
  readmePath = if builtins.pathExists "${nixCats}/../README.md" then "${nixCats}/../README.md" else "${nixCats}/README.md";
  docsbuilt = pkgs.stdenv.mkDerivation {
    name = "genNixCatsDocs";
    src = helpPath;
    buildPhase = ''
      export HOME=$(mktemp -d)
      mkdir -p $out
      ${genvim}/bin/genvim --headless --cmd "lua vim.g.nixCats_doc_out = [[$out]]" --cmd "lua vim.g.nixCats_doc_src = [[$src]]"
      ${pkgs.pandoc}/bin/pandoc --standalone --template ${./github-markdown-dark.html} "$(realpath "${readmePath}")" -o $out/index.html -V title="NIX CATEGORIES FOR NVIM"
      ${pkgs.pandoc}/bin/pandoc --standalone --template ${./github-markdown-dark.html} "$(realpath "${./TOC.md}")" -o $out/TOC.html -V title="nixCats.org TOC"
      cp ${./github-markdown-dark.css} $out/github-markdown-dark.css
    '';
  };
in
pkgs.writeShellScriptBin "replaceNixCatsDocs" ''
  finaloutpath=''${1:-"."}
  mkdir -p "$finaloutpath"
  cp -rf ${docsbuilt}/* "$finaloutpath"
  chmod +w $finaloutpath/*.html
  chmod +w $finaloutpath/*.css
''
