{
  description = ''
    Useage:
    nix run --refresh --no-write-lock-file --show-trace .
    nix run --refresh --no-write-lock-file --show-trace . -- "$SOMEOUTPATH"

    generates an html + css site from the nixCats documentation
    to either the current directory or some other given path.
  '';
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
      genvim = let
        categoryDefinitions = { pkgs, settings, categories, name, ... }: {
          startupPlugins = {
            general = with pkgs.vimPlugins; [
              onedark-nvim
              (nvim-treesitter.withPlugins (plugins: with plugins; [
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
              killAfter = true;
              general = true;
            };
          };
        };
      in
      nixCats.utils.baseBuilder ./genvim {
        inherit nixpkgs system;
      } categoryDefinitions packageDefinitions "genvim";

      pkgs = import nixpkgs { inherit system; };
      isNixDir = builtins.pathExists "${nixCats}/nixCatsHelp";
      docsite = pkgs.stdenv.mkDerivation {
        name = "genNixCatsDocs";
        src = if isNixDir then "${nixCats}/nixCatsHelp" else "${nixCats}/nix/nixCatsHelp";
        buildPhase = let
          readmePath = if isNixDir then "${nixCats}/../README.md" else "${nixCats}/README.md";
        in /* bash */ ''
          export HOME=$(mktemp -d)
          mkdir -p $out
          ${genvim}/bin/genvim --headless --cmd "lua vim.g.nixCats_doc_out = [[$out]]; vim.g.nixCats_doc_src = [[$src]]"
          ${pkgs.pandoc}/bin/pandoc --standalone --template ${./md/github-markdown-dark.html} "$(realpath "${readmePath}")" -o $out/index.html -V title="NIX CATEGORIES FOR NVIM"
          ${pkgs.pandoc}/bin/pandoc --standalone --template ${./md/github-markdown-dark.html} "$(realpath "${./md/TOC.md}")" -o $out/TOC.html -V title="nixCats.org TOC"
          cp ${mkdncss}/github-markdown-dark.css $out/github-markdown-dark.css
        '';
      };
    in {
      default = pkgs.writeShellScriptBin "replaceNixCatsDocs" ''
        finaloutpath=''${1:-"."}
        mkdir -p "$finaloutpath"
        cp -rvf ${docsite}/* "$finaloutpath"
        chmod +w $finaloutpath/*.html
        chmod +w $finaloutpath/*.css
      '';

      genvim = genvim.override (prev: {
        packageDefinitions = {
          genvim = args: {
            settings = {};
            categories = {
              general = true;
              killAfter = false;
            };
          };
        };
      });
    });
  };
}
