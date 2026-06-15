{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur-repo-override.url = "git+file:///home/ilya/nur-repository";
  inputs.firefox.url = "github:nix-community/flake-firefox-nightly";

  outputs = inputs: let
    inherit (inputs.nixpkgs) lib;

    hosts = [
      {
        hostname = "asus-x421da";
        system = "x86_64-linux";
      }
      {
        hostname = "ms-7c94";
        system = "x86_64-linux";
      }
      {
        hostname = "beelink-ser5";
        system = "x86_64-linux";
      }
    ];

    forAllSystems = f: lib.genAttrs (lib.unique (map (host: host.system) hosts)) f;
    forAllHosts = f: lib.listToAttrs (map (host: lib.nameValuePair host.hostname (f host)) hosts);
  in let
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
  in {
    nixosConfigurations = forAllHosts ({ hostname, system }: lib.${system}.nixosSystem {
      inherit system;
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs system hostname; };
    });
  };
}
