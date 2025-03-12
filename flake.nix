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
      HMdoc = pkgs.callPackage ./gen_docs/mod.nix ({ isHomeManager = true; } // inputs);
      ModDoc = pkgs.callPackage ./gen_docs/mod.nix ({ isHomeManager = false; } // inputs);
      UtilDoc = pkgs.callPackage ./gen_docs/util.nix inputs;
      TemplateDoc = pkgs.callPackage ./gen_docs/templates.nix inputs;
      WebComponents = pkgs.callPackage ./components inputs;

      docsite = pkgs.runCommandNoCC "genNixCatsDocs" {} ''
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
        ${genvim}/bin/genvim --headless --cmd "lua vim.g.nixCats_doc_src = [[${nixCats}/nixCatsHelp]]; vim.g.nixCats_doc_out = [[$out]]"

        # fix link at the top of the readme
        TEMPFILE=$(mktemp)
        sed '1,5s|\[nixCats\](https://nixcats.org)|[nixCats](https://github.com/BirdeeHub/nixCats-nvim)|' '${nixCats}/README.md' > "$TEMPFILE"

        # run pandoc on the readme
        pandocGen "$TEMPFILE" "$out/index.html" "NIX CATEGORIES FOR NVIM"
        rm -f "$TEMPFILE"

        # run pandoc on all pages that arent from the main nixCats repo
        pandocGen '${./md/TOC.md}' "$out/TOC.html" "nixCats.org TOC"

        pandocGen2 ${UtilDoc} "$out/nixCats_utils.html" "nixCats.utils API"
        pandocGen2 ${HMdoc} "$out/nixCats_hm_options.html" "nixCats home-manager options"
        pandocGen2 ${ModDoc} "$out/nixCats_nixos_options.html" "nixCats nixos options"
        pandocGen2 ${TemplateDoc} "$out/nixCats_templates.html" "nixCats templates"

        cp -r ${WebComponents}/* $out/
      '';

      # maybe one day I can get this to work
      tovimdoc = pkgs.runCommandNoCC "tovimdoc" {} ''
        pandoccmd () {
          ${pkgs.panvimdoc}/bin/panvimdoc --toc false --dedup-subheadings true --project-name "$2" --input-file "$1"
        }
        TEMPDIR="$(mktemp -d)"
        mkdir -p "$TEMPDIR"
        mkdir -p "$TEMPDIR/doc"
        cd "$TEMPDIR"
        pandoccmd ${UtilDoc} "nixCats.utils"
        pandoccmd ${HMdoc} "nixCats.home-manager"
        pandoccmd ${ModDoc} "nixCats.nixos"
        pandoccmd ${TemplateDoc} "nixCats templates"
        mkdir -p "$out"
        cp -r "$TEMPDIR/doc/"* "$out"
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

      # generated markdown
      inherit HMdoc ModDoc UtilDoc TemplateDoc;

      # this makes a fun web component that emulates vim :help search
      inherit WebComponents;

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
