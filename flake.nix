{
  description = "Management cli of github:gw31415/dotfiles";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        dot-drv = pkgs.stdenvNoCC.mkDerivation {
          name = "dot";
          paths = with pkgs; [
            fish
          ];
          dontUnpack = true;
          src = ./.;
          installPhase = ''
            mkdir -p $out
            cp -r $src/bin $out/bin
          '';
        };
        dot-install-drv = pkgs.writeShellScriptBin "dot-install" (builtins.readFile ./dot-install);
      in
      {
        ########################################
        # Package sets
        ########################################
        packages = {
          default = dot-drv;
        };
        apps = rec {
          dot = flake-utils.lib.mkApp { drv = dot-drv; };
          install = flake-utils.lib.mkApp { drv = dot-install-drv; };
          default = dot;
        };
      }
    );
}
