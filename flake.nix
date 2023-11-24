{
  inputs = {
    nixpkgs.url = "nixpkgs/release-23.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (system: let
      overlays = [];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
      inherit (pkgs.stdenv) mkDerivation;
    in rec {
      packages = rec {
        images = mkDerivation {
          name = "tf-map-images";
          version = "0.1.0";

          src = ./images;

          nativeBuildInputs = with pkgs; [xcftools imagemagick];
          buildPhase = ''
            make
          '';
          installPhase = ''
            cp -r dist $out
          '';
        };
        maps = mkDerivation rec {
          name = "tf-maps";
          version = "0.1.0";

          src = ./data;

          buildPhase = "";
          installPhase = ''
            mkdir $out
            cp boundaries.json $out/boundaries.json
            cp -r ${images} $out/images
          '';
        };
        default = maps;
      };
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          vips
          xcftools
        ];
      };
    });
}
