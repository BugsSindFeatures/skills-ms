{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  outputs = {
    self,
    nixpkgs,
    poetry2nix,
    ...
  }: let
    defaultSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    eachDefaultSystem = f:
      builtins.listToAttrs (map (system: {
          name = system;
          value = f system;
        })
        defaultSystems);
  in {
    packages = eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      inherit (poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryApplication;
    in {
      default = mkPoetryApplication {
        projectDir = ./.;
        python = pkgs.python311;
        doCheck = false;
      };

      courses = ./config/courses;
    });

    nixosModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: let
      settingsFormat = pkgs.formats.keyValue {};
    in {
      options.academy.backend.skills = with lib; {
        enable = mkEnableOption "Bootstrap Academy Skills Microservice";
        environmentFiles = mkOption {
          type = types.listOf types.path;
        };
        settings = mkOption {
          inherit (settingsFormat) type;
        };
      };

      config = let
        cfg = config.academy.backend.skills;
      in
        lib.mkIf cfg.enable {
          systemd.services = {
            academy-skills = {
              wantedBy = ["multi-user.target"];
              serviceConfig = {
                User = "academy-skills";
                Group = "academy-skills";
                DynamicUser = true;
                EnvironmentFile = cfg.environmentFiles ++ [(settingsFormat.generate "config" cfg.settings)];
              };
              preStart = ''
                cd ${lib.fileset.toSource {
                  root = ./.;
                  fileset = lib.fileset.unions [
                    ./alembic
                    ./alembic.ini
                  ];
                }}
                ${self.packages.${pkgs.system}.default}/bin/alembic upgrade head
              '';
              script = ''
                ${self.packages.${pkgs.system}.default}/bin/api
              '';
            };
          };
        };
    };

    devShells = eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          python311
          poetry
          poethepoet
          pyright
          yt-dlp
        ];
        shellHook = ''
          poe setup
          source .venv/bin/activate
        '';
      };
    });
  };
}