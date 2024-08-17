{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim?dir=nix";
    mkdncss = {
      url = "github:sindresorhus/github-markdown-css";
      flake = false;
    };
  };
  outputs = { nixpkgs, nixCats, mkdncss, ... }@inputs: let
    forSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    packages = forSys (system: let
      pkgs = import nixpkgs { inherit system; };
      docsite = let
        genvim = let
          categoryDefinitions = { pkgs, settings, categories, name, ... }: {
            startupPlugins = {
              general = with pkgs.vimPlugins; [
                onedark-nvim
                (nvim-treesitter.withPlugins ( plugins: with plugins; [
                  vimdoc
                  vim
                  luadoc
                  todotxt
                  nix
                  lua
                  bash
                ]))
              ];
            };
          };
          packageDefinitions = {
            genvim = {pkgs , ... }: {
              settings = {};
              categories = {
                general = true;
              };
            };
          };
        in
        nixCats.utils.baseBuilder ./. {
          inherit nixpkgs system;
        } categoryDefinitions packageDefinitions "genvim";

        helpPath = if builtins.pathExists "${nixCats}/nixCatsHelp" then "${nixCats}/nixCatsHelp" else "${nixCats}/nix/nixCatsHelp";
        readmePath = if builtins.pathExists "${nixCats}/../README.md" then "${nixCats}/../README.md" else "${nixCats}/README.md";
      in
      pkgs.stdenv.mkDerivation {
        name = "genNixCatsDocs";
        src = helpPath;
        buildPhase = ''
          export HOME=$(mktemp -d)
          mkdir -p $out
          ${genvim}/bin/genvim --headless --cmd "lua vim.g.nixCats_doc_out = [[$out]]" --cmd "lua vim.g.nixCats_doc_src = [[$src]]"
          ${pkgs.pandoc}/bin/pandoc --standalone --template ${./github-markdown-dark.html} "$(realpath "${readmePath}")" -o $out/index.html -V title="NIX CATEGORIES FOR NVIM"
          ${pkgs.pandoc}/bin/pandoc --standalone --template ${./github-markdown-dark.html} "$(realpath "${./TOC.md}")" -o $out/TOC.html -V title="nixCats.org TOC"
          cp ${mkdncss}/github-markdown-dark.css $out/github-markdown-dark.css
        '';
      };
    in {
      default = pkgs.writeShellScriptBin "replaceNixCatsDocs" ''
        finaloutpath=''${1:-"."}
        mkdir -p "$finaloutpath"
        cp -rf ${docsite}/* "$finaloutpath"
        chmod +w $finaloutpath/*.html
        chmod +w $finaloutpath/*.css
      '';
    });
  };
}
