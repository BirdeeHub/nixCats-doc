{ system, inputs, ... }: let
  inherit (inputs) nixCats nixpkgs;
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
} categoryDefinitions packageDefinitions "genvim"
