{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur-repo-override.url = "git+file:///home/ilya/nur-repository";
  inputs.mozilla.url = "github:mozilla/nixpkgs-mozilla";

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
