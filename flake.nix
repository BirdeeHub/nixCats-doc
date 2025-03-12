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
    mkdncss = {
      url = "github:sindresorhus/github-markdown-css";
      flake = false;
    };
    mkdncss2 = {
      url = "github:jez/pandoc-markdown-css-theme";
      flake = false;
    };
    nixdoc.url = "github:nix-community/nixdoc";
  };
  outputs = { nixpkgs, nixCats, mkdncss, mkdncss2, ... }@inputs: let
    forSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    packages = forSys (system: let
      genvim = import ./genvim { inherit system inputs; };
      pkgs = import nixpkgs { inherit system; };

      pandocCMD = pkgs.writeShellScript "pandocCMD" ''
        export PATH="${nixpkgs.lib.makeBinPath (with pkgs; [ coreutils pandoc ])}:$PATH"
        do_copy=$1 nix_out=$2
        pan_in=$3 pan_out=$4 pan_title=$5
        $(exit "$do_copy") && {
          mkdir -p $nix_out/css && \
          cp -f ${mkdncss}/github-markdown-dark.css $nix_out/css/github-markdown-dark.css
        } || true
        pandoc --standalone \
          --template ${./md/github-markdown-dark.html} \
          -V title="$pan_title" \
          -o "$pan_out" \
          "$(realpath "$pan_in")"
      '';

      pandocCMD2 = pkgs.writeShellScript "pandocCMD" ''
        export PATH="${nixpkgs.lib.makeBinPath (with pkgs; [ coreutils pandoc haskellPackages.pandoc-sidenote ])}:$PATH"
        do_copy=$1 nix_out=$2
        pan_in=$3 pan_out=$4 pan_title=$5
        $(exit "$do_copy") && {
          mkdir -p $nix_out/css && \
          cp -f ${mkdncss2}/public/css/* $nix_out/css
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
      GenCatHMdoc = pkgs.callPackage ./gen_docs/mod.nix ({ APPNAME = "GenCatHMdoc"; isHomeManager = true; } // inputs);
      GenCatModDoc = pkgs.callPackage ./gen_docs/mod.nix ({ APPNAME = "GenCatModDoc"; isHomeManager = false; } // inputs);
      GenCatUtilDoc = pkgs.callPackage ./gen_docs/util.nix ({ APPNAME = "GenCatUtilDoc"; } // inputs);
      GenCatTemplateDoc = pkgs.callPackage ./gen_docs/templates.nix ({ APPNAME = "GenCatTemplateDoc"; } // inputs);
      GenComponents = pkgs.callPackage ./components inputs;

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
          do_copy_2=0
          pandocGen2() {
            ${pandocCMD2} "$do_copy_2" "$out" "$@"
            do_copy=1
          }

          # use nvim headless and the config to generate html from nvim docs
          ${genvim}/bin/genvim --headless --cmd "lua vim.g.nixCats_doc_out = [[$out]]; vim.g.nixCats_doc_src = [[$src]]"

          # fix link at the top of the readme
          TEMPFILE=$(mktemp)
          sed '1,5s|\[nixCats\](https://nixcats.org)|[nixCats](https://github.com/BirdeeHub/nixCats-nvim)|' "${nixCats}/README.md" > "$TEMPFILE"

          # run pandoc on the readme
          pandocGen "$TEMPFILE" "$out/index.html" "NIX CATEGORIES FOR NVIM"

          # run pandoc on all pages that arent from the main nixCats repo
          pandocGen "${./md/TOC.md}" "$out/TOC.html" "nixCats.org TOC"
          
          ${GenCatUtilDoc}/bin/GenCatUtilDoc > $TEMPFILE
          pandocGen2 "$TEMPFILE" "$out/nixCats_utils.html" "nixCats.utils API"
          ${GenCatHMdoc}/bin/GenCatHMdoc > $TEMPFILE
          pandocGen2 "$TEMPFILE" "$out/nixCats_hm_options.html" "nixCats home-manager options"
          ${GenCatModDoc}/bin/GenCatModDoc > $TEMPFILE
          pandocGen2 "$TEMPFILE" "$out/nixCats_nixos_options.html" "nixCats nixos options"
          ${GenCatTemplateDoc} > $TEMPFILE
          pandocGen2 "$TEMPFILE" "$out/nixCats_templates.html" "nixCats templates"
          rm -f "$TEMPFILE"

          cp -r ${GenComponents}/* $out/
        '';
      };

      # maybe one day I can get this to work
      tovimdoc = pkgs.writeShellScriptBin "tovimdoc" ''
        OUTDIR="''${1:-"."}"
        pandoccmd () {
          ${pkgs.panvimdoc}/bin/panvimdoc --toc false --dedup-subheadings true --project-name "$2" --input-file "$1"
        }
        TEMPDIR="$(mktemp -d)"
        mkdir -p "$TEMPDIR"
        mkdir -p "$TEMPDIR/doc"
        TEMPFILE="$TEMPDIR/temp.md"
        ogpath="$(pwd)"
        cd "$TEMPDIR"
        ${GenCatUtilDoc}/bin/GenCatUtilDoc > $TEMPFILE
        pandoccmd "$TEMPFILE" "nixCats.utils"
        ${GenCatHMdoc}/bin/GenCatHMdoc > $TEMPFILE
        pandoccmd "$TEMPFILE" "nixCats.home-manager"
        ${GenCatModDoc}/bin/GenCatModDoc > $TEMPFILE
        pandoccmd "$TEMPFILE" "nixCats.nixos"
        ${GenCatTemplateDoc}/bin/GenCatTemplateDoc > $TEMPFILE
        pandoccmd "$TEMPFILE" "nixCats templates"
        cd "$ogpath"
        mkdir -p "$OUTDIR"
        cp -r "$TEMPDIR/doc/"* "$OUTDIR"
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

      # these generate markdown to stdout
      inherit GenCatHMdoc GenCatModDoc GenCatUtilDoc GenCatTemplateDoc;

      # this makes a fun web component that emulates vim :help search
      inherit GenComponents;

      # maybe one day I can get this to work
      inherit tovimdoc;

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
