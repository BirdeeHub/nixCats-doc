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
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    # nixCats.url = "git+file:/home/birdee/Projects/nixCats-nvim?branch=dev";
    mkdncss = {
      # url = "github:jez/pandoc-markdown-css-theme";
      url = "github:sindresorhus/github-markdown-css";
      flake = false;
    };
    nixdoc.url = "github:nix-community/nixdoc";
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

      # NOTE: this is the pandoc command currently being used
      pandocCMD = pkgs.writeShellScript "pandocCMD" ''
        export PATH="${nixpkgs.lib.makeBinPath (with pkgs; [ coreutils pandoc ])}:$PATH"
        do_copy=$1 nix_out=$2
        pan_in=$3 pan_out=$4 pan_title=$5
        $(exit "$do_copy") && {
          cp ${mkdncss}/github-markdown-dark.css $nix_out/github-markdown-dark.css
        } || true
        pandoc --standalone \
          --template ${./md/github-markdown-dark.html} \
          -V title="$pan_title" \
          -o "$pan_out" \
          "$(realpath "$pan_in")"
      '';
      # don't mind this, just trying out other themes
      # url = "github:jez/pandoc-markdown-css-theme";
      pandocCMDtest = pkgs.writeShellScript "pandocCMD" ''
        export PATH="${nixpkgs.lib.makeBinPath (with pkgs; [ coreutils pandoc haskellPackages.pandoc-sidenote ])}:$PATH"
        do_copy=$1 nix_out=$2
        pan_in=$3 pan_out=$4 pan_title=$5
        $(exit "$do_copy") && {
          mkdir -p $nix_out/css && \
          cp ${mkdncss}/public/css/* $nix_out/css
        } || true
        pandoc --katex \
          --from markdown+tex_math_single_backslash \
          --filter pandoc-sidenote \
          --to html5+smart \
          --template ${./md/template.html5} \
          --css="./css/theme.css" \
          --css="./css/skylighting-solarized-theme.css" \
          --toc \
          --wrap=none \
          -V pagetitle="$pan_title" \
          --output "$pan_out" \
          "$(realpath "$pan_in")"
      '';
      GenCatHMdoc = pkgs.callPackage ./fromcommenttest/mod.nix ({ APPNAME = "GenCatHMdoc"; isHomeManager = true; } // inputs);
      GenCatModDoc = pkgs.callPackage ./fromcommenttest/mod.nix ({ APPNAME = "GenCatModDoc"; isHomeManager = false; } // inputs);
      GenCatUtilDoc = pkgs.callPackage ./fromcommenttest/util.nix ({ APPNAME = "GenCatUtilDoc"; } // inputs);

      docsite = pkgs.stdenv.mkDerivation {
        name = "genNixCatsDocs";
        src = "${nixCats}/nixCatsHelp";
        buildPhase = /* bash */ ''
          export HOME=$(mktemp -d)
          do_copy=0
          pandocGen() {
            ${pandocCMD} "$do_copy" "$out" "$@"
            do_copy=1
          }

          # use nvim headless and the config to generate html from nvim docs
          ${genvim}/bin/genvim --headless --cmd "lua vim.g.nixCats_doc_out = [[$out]]; vim.g.nixCats_doc_src = [[$src]]"

          # run pandoc on the readme
          pandocGen "${nixCats}/README.md" "$out/index.html" "NIX CATEGORIES FOR NVIM"

          # run pandoc on all pages that arent from the main nixCats repo
          pandocGen "${./md/TOC.md}" "$out/TOC.html" "nixCats.org TOC"
          
          TEMPFILE=$(mktemp)
          ${GenCatUtilDoc}/bin/GenCatUtilDoc > $TEMPFILE
          pandocGen "$TEMPFILE" "$out/nixCats_utils.html" "nixCats.utils API"
          ${GenCatHMdoc}/bin/GenCatHMdoc > $TEMPFILE
          pandocGen "$TEMPFILE" "$out/nixCats_hm_options.html" "nixCats home-manager options"
          ${GenCatModDoc}/bin/GenCatModDoc > $TEMPFILE
          pandocGen "$TEMPFILE" "$out/nixCats_nixos_options.html" "nixCats nixos options"
        '';
      };

      tovimdoc = pkgs.writeShellScriptBin "tovimdoc" ''
        OUTDIR="''${1:-"."}"
        pandoccmd () {
          ${pkgs.panvimdoc}/bin/panvimdoc --toc false --project-name "nixCats" --input-file "$1"
        }
        TEMPDIR="$(mktemp -d)"
        mkdir -p "$TEMPDIR"
        mkdir -p "$TEMPDIR/doc"
        TEMPFILE="$TEMPDIR/temp.md"
        cd "$TEMPDIR"
        ${GenCatUtilDoc}/bin/GenCatUtilDoc > $TEMPFILE
        pandoccmd "$TEMPFILE"
        ${GenCatHMdoc}/bin/GenCatHMdoc > $TEMPFILE
        pandoccmd "$TEMPFILE"
        ${GenCatModDoc}/bin/GenCatModDoc > $TEMPFILE
        pandoccmd "$TEMPFILE"
        mkdir -p "$OUTDIR"
        cp "$TEMPDIR/doc/"* "$OUTDIR"
      '';
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
      inherit GenCatHMdoc GenCatModDoc GenCatUtilDoc tovimdoc;

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
