{

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    unstable-pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    NixOS-WSL = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , unstable-pkgs
    , flake-utils
    , home-manager
    , NixOS-WSL
    , vscode-server
    }:
    let
      overlays = { config, lib, pkgs, ... }: {
        nixpkgs.overlays = [
          (final: prev: {
            unstable = import unstable-pkgs {
              system = final.system;
            };
          })
          (final: prev: {
            direnv = pkgs.stdenv.mkDerivation {
              name = "direnv-wrapped";
              src = prev.direnv;
              # Copy everything except for /share/fish
              # because that results in sourcing direnv twice
              installPhase = ''
                mkdir -p $out/share
                cp -r bin $out/bin
                cp -r share/man $out/share/man
              '';
            };
          })
        ];
      };
      nixosInputs = {
        imports = [
          overlays
          home-manager.nixosModules.home-manager
        ];
        home-manager.users.forrest.imports = [
          vscode-server.nixosModules.home
        ];
      };
    in
    {
      darwinModules.default = { ... }: {
        imports = [
          overlays
          home-manager.darwinModules.home-manager
          ./darwin
        ];
      };
      nixosConfigurations = {
        boimler = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixosInputs
            ./hosts/boimler
          ];
        };
        freeman = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixosInputs
            NixOS-WSL.nixosModules.wsl
            ./hosts/freeman
          ];
        };
        mariner = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixosInputs
            ./hosts/mariner
          ];
        };
      };
      templates.darwin = {
        path = ./darwin/template;
        description = "Base Mac configuration";
      };
    } // flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    });

}
