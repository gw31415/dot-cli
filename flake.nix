{
  description = "Management cli of github:gw31415/dotfiles";

  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      fenix,
      flake-utils,
      nixpkgs,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        toolchain = fenix.packages.${system}.fromToolchainFile {
          file = ./rust-toolchain.toml;
          sha256 = "18blq77d227zfgqwadk3zanlwlxp3i23pqpc11ck0yqf20p6dlgv";
        };
        dot =
          (
            (pkgs.makeRustPlatform {
              cargo = toolchain;
              rustc = toolchain;
            }).buildRustPackage
            {
              name = "dot";
              src = ./.;
              cargoLock.lockFile = ./Cargo.lock;
              nativeBuildInputs = with pkgs; [
                libgit2
                pkg-config
                openssl
              ];
            }
          ).overrideAttrs
            (old: {
              OPENSSL_DIR = "${pkgs.openssl.dev}";
              OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
            });
      in
      {
        ########################################
        # Package sets
        ########################################
        packages = {
          default = dot;
        };
        apps = rec {
          dot-app = flake-utils.lib.mkApp { drv = dot; };
          default = dot-app;
        };
      }
    );
}
