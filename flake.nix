{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur-repo-override.url = "git+file:///home/ilya/nur-repository";
  inputs.nur-repo-override.inputs.flake-compat.follows = "flake-compat";
  inputs.mozilla.url = "github:mozilla/nixpkgs-mozilla";

  inputs.flake-compat = {
    url = github:edolstra/flake-compat;
    flake = false;
  };

  inputs.passwords = {
    url = "file+file:///etc/nixos/passwords.nix";
    flake = false;
  };

  outputs = inputs: let
    system = "x86_64-linux";
    nixpkgs = (import ((import inputs.nixpkgs {
      inherit system;
      overlays = [];
    }).applyPatches {
      name = "nixpkgs";
      src = inputs.nixpkgs;
      patches = [ ./allow-no-password.patch ];
    } + "/flake.nix")).outputs { self = nixpkgs; };
  in rec {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs system; };
    };

    defaultPackage.${system} = nixosConfigurations.nixos.config.system.build.toplevel;
    legacyPackages.${system} = nixosConfigurations.nixos.pkgs;
  };
}
