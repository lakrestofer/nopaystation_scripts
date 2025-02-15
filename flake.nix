# This flake was initially generated by fh, the CLI for FlakeHub (version 0.1.21)
{
  # A helpful description of your flake
  description = "content agnostic spaced repetition";

  # Flake inputs
  inputs = {
    pkg2zip.url = "git@github.com:lakrestofer/pkg2zip";
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
  };

  # Flake outputs that other flakes can use
  outputs =
    {
      self,
      flake-schemas,
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        inputs.flake-root.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
      ];
      flake = {
        # Schemas tell Nix about the structure of your flake's outputs
        schemas = flake-schemas.schemas;
      };
      systems = [
        "x86_64-linux"
      ];
      perSystem =
        {
          pkgs,
          self',
          system,
          config,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ ];
            config = { };
          };
          flake-root.projectRootFile = "flake.nix"; # Not necessary, as flake.nix is the default
          devShells.default = pkgs.mkShell {
            inputsFrom = [ config.flake-root.devShell ]; # Provides $FLAKE_ROOT in dev shell
            packages = with pkgs; [
              curl
              (python3.withPackages (
                p: with p; ([
                  lxml
                ])
              ))
            ];
            env = {
              LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.libz
              ];
            };
          };
          packages = {
            pkg2zip = builtins.fetchTarball {
              url = "https://github.com/lusid1/pkg2zip/archive/refs/tags/2.6.tar.gz";
              sha256 = "";

            };
          };
        };
    };
}
