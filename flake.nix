{
  description = "An empty base flake with a devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix = {
      url = "github:nixos/nix?ref=2.19.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { self, nixpkgs, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;

        packages = {
          runner =
            let
              base = import (inputs.nix + "/docker.nix") {
                inherit pkgs;
                name = "nix-ci-base";
                maxLayers = 10;
                extraPkgs = with pkgs; [
                  nodejs
                ];
                nixConf = {
                  substituters = [
                    "https://cache.nixos.org/"
                    "https://nix-community.cachix.org"
                    # insert any other binary caches here
                  ];
                  trusted-public-keys = [
                    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                    # insert the public keys for those binary caches here
                  ];
                  # allow using the new flake commands in our workflows
                  experimental-features = [ "nix-command" "flakes" ];
                };
              };
            in
            pkgs.dockerTools.buildImage {
              name = "ghcr.io/eboskma/forgejo-nix-runner";
              tag = "latest";

              fromImage = base;

              copyToRoot = pkgs.buildEnv {
                name = "image-root";
                paths = [ pkgs.coreutils-full ];
                pathsToLink = [ "/bin" ];
              };
            };
        };

        devShells.default = with pkgs; mkShell { };
      };
    };
}
