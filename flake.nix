{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim?dir=nix";
    mkdncss = {
      url = "github:sindresorhus/github-markdown-css";
      flake = false;
    };
  };
  outputs = { nixpkgs, ... }@inputs: let
    forSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    packages = forSys (system: { default = import ./. inputs system; });
  };
}
