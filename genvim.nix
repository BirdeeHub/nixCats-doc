{ nixpkgs, nixCats, ... }: finalsystem: let
  inherit (nixCats) utils;
  luaPath = ./.;
  extra_pkg_config = {};
  dependencyOverlays = [ ];
  categoryDefinitions = { pkgs, settings, categories, name, ... }@packageDef: {
    startupPlugins = {
      general = with pkgs.vimPlugins; [
        onedark-nvim
        # TODO: get it to properly do todo-comments-nvim without doing ALL grammars
        # (nvim-treesitter.withPlugins ( plugins: with plugins; [ vimdoc nix lua bash ]))
        nvim-treesitter.withAllGrammars
        todo-comments-nvim
      ];
    };
  };
  packageDefinitions = {
    genvim = {pkgs , ... }: {
      settings = {
        wrapRc = true;
      };
      categories = {
        general = true;
      };
    };
  };
  defaultPackageName = "genvim";
in
utils.baseBuilder luaPath {
  system = finalsystem;
  inherit nixpkgs dependencyOverlays extra_pkg_config;
} categoryDefinitions packageDefinitions defaultPackageName
