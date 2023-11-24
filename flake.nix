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
      inherit (pkgs) writeText dockerTools;
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
        nginxConf = writeText "nginx.conf" ''
          user nobody nobody;
          daemon off;
          error_log /dev/stdout info;
          pid /dev/null;
          events {}
          http {
            include ${pkgs.nginx}/conf/mime.types;
            access_log /dev/stdout;
            server {
              listen 80;
              autoindex on;
              charset utf-8;

              location / {
                root ${maps};
              }
            }
          }
        '';
        docker = dockerTools.buildLayeredImage {
          name = "demostf/maps";
          tag = "latest";
          maxLayers = 5;
          contents = with pkgs; [
            nginx
            fakeNss
            (writeScriptBin "start-server" ''
              #!${runtimeShell}
              nginx -c ${nginxConf};
            '')
          ];

          extraCommands = ''
            mkdir -p var/log/nginx
            mkdir -p var/cache/nginx
            mkdir -p tmp
            chmod 1777 tmp
          '';

          config = {
            Cmd = ["start-server"];
            ExposedPorts = {
              "80/tcp" = {};
            };
          };
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
