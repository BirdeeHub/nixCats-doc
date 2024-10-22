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
    # nixCats.url = "git+file:/home/birdee/Projects/nixCats-nvim?dir=nix";
    mkdncss = {
      url = "github:sindresorhus/github-markdown-css";
      # url = "github:jez/pandoc-markdown-css-theme";
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
      nixCats.utils.baseBuilder ./. {
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
          pandocGen() {
            local pan_in=$1
            local pan_out=$2
            local pan_title=$3
            ${pkgs.pandoc}/bin/pandoc --standalone --template ${./md/github-markdown-dark.html} "$(realpath "$pan_in")" -o "$pan_out" -V title="$pan_title"
          }
          mkdir -p $out
          # use nvim headless and the config to generate html from nvim docs
          ${genvim}/bin/genvim --headless --cmd "lua vim.g.nixCats_doc_out = [[$out]]; vim.g.nixCats_doc_src = [[$src]]"
          # get a basic github theme css from github for markdown pandoc-generated pages
          cp ${mkdncss}/github-markdown-dark.css $out/github-markdown-dark.css
          pandocGen ${readmePath} $out/index.html "NIX CATEGORIES FOR NVIM"

          # all pages that arent from the main nixCats repo
          pandocGen ${./md/TOC.md} $out/TOC.html "nixCats.org TOC"
        '';
      };
    in {
      # we built the drv. Now we have to get it out of the store. Instead of installing the drv,
      # we install a script that copies the contents of the drv to a specified directory
      default = pkgs.writeShellScriptBin "replaceNixCatsDocs" ''
        finaloutpath=''${1:-"."}
        mkdir -p "$finaloutpath"
        cp -rvf ${docsite}/* "$finaloutpath"
        chmod -R 750 "$finaloutpath"
        find "$finaloutpath" -type f ! -iname "*.sh" -exec chmod 640 {} +
      '';

      # for debug purposes, the nvim drv used to gen the docs
      # but told not to die on errors in the config.
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
