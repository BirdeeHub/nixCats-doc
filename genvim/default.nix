{ pkgs, inputs, ... }: let
  inherit (inputs) nixCats;
  categoryDefinitions = { pkgs, settings, categories, name, ... }: {
    startupPlugins = {
      general = with pkgs.vimPlugins; [
        {
          plugin = onedark-nvim;
          pre = true;
          type = "lua";
          config = /*lua*/ ''
            -- dark, darker, cool, deep, warm, warmer, light
            require('onedark').setup { style = 'darker', }
            require('onedark').load()
            vim.cmd.colorscheme('onedark')
          '';
        }
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
      categories = {
        killAfter = true;
        general = true;
      };
    };
  };
in
nixCats.utils.baseBuilder ./. {
  inherit pkgs;
} categoryDefinitions packageDefinitions "genvim"
