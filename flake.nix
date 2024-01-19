{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur-repo-override.url = "git+file:///home/ilya/nur-repository";
  inputs.mozilla.url = "github:mozilla/nixpkgs-mozilla";
  inputs.passwords.url = "path:/etc/nixos/passwords";

  outputs = inputs: let
    inherit (inputs.nixpkgs) lib;

    hosts = [
      {
        hostname = "nixos";
        system = "x86_64-linux";
      }
    ];

    forAllSystems = f: lib.genAttrs (lib.unique (map (host: host.system) hosts)) f;
    forAllHosts = f: lib.listToAttrs (map (host: lib.nameValuePair host.hostname (f host)) hosts);
  in (inputs: let
    inherit (inputs) lib;

    pkgs = forAllSystems (system: import inputs.nixpkgs.${system} {
      inherit system;

      config = {
        allowUnfree = true;
        oraclejdk.accept_license = true;
        joypixels.acceptLicense = true;
      };

      overlays = [
        (self: super: {
          nur = import inputs.nur {
            nurpkgs = super;
            pkgs = super;
            repoOverrides = {
              ilya-fedin = import inputs.nur-repo-override {};
            };
          };
        })
        inputs.mozilla.overlays.firefox
        inputs.nur-no-pkgs.${system}.repos.ilya-fedin.overlays.portal
      ];
    });
  in {
    nixosConfigurations = forAllHosts ({ hostname, system }: lib.${system}.nixosSystem {
      inherit system;
      pkgs = pkgs.${system};
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs system hostname; };
    });

    legacyPackages = pkgs;
  }) (inputs // rec {
    nixpkgs = forAllSystems (system: (import inputs.nixpkgs {
      inherit system;
      overlays = [];
    }).applyPatches {
      name = "nixpkgs";
      src = inputs.nixpkgs;
      patches = [ ./allow-no-password.patch ];
    });

    lib = forAllSystems (system: ((import (nixpkgs.${system} + "/flake.nix")).outputs {
      self = nixpkgs.${system};
    }).lib);

    nur-no-pkgs = forAllSystems (system: import inputs.nur {
      nurpkgs = import nixpkgs.${system} {
        inherit system;
        overlays = [];
      };

      repoOverrides = {
        ilya-fedin = import inputs.nur-repo-override {};
      };
    });
  });
}
