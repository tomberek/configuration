{
  description = "Tsurf";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # inputs.nixpkgs.url = "/home/tom/nixpkgs";
  # inputs.flox.url = "github:flox/nixos-module/tng";
  # inputs.devenv.url = "github:cachix/devenv/v0.5";

  outputs = { self, nixpkgs, nixos-hardware  }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };

#  pkgs // { devenv = devenv.x86_64-linux.packages;}
#  overlays = [
# ( final: prev: {
#     devenv = devenv.x86_64-linux.packages;
# }
# ];

in {
    nixosConfigurations.tframe2 = nixpkgs.lib.nixosSystem 
{
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
      ];
    };
    nixosConfigurations.tframe = nixpkgs.lib.nixosSystem 
{
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.framework-11th-gen-intel
        # flox.nixosModule

        ./configuration.nix
        ./hardware-configuration.nix

        ({ lib, ... }: {
          nix.registry.nixpkgs.flake = nixpkgs;
          #boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
        })
      ];
    };
  };
}
