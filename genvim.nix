{ nixpkgs, nixCats, ... }: finalsystem: let
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
  inherit nixpkgs;
  system = finalsystem;
} categoryDefinitions packageDefinitions "genvim"
