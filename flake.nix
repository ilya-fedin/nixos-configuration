{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur-repo-override.url = "git+file:///home/ilya/nur-repository";

  inputs.mozilla = {
    url = "github:mozilla/nixpkgs-mozilla";
    flake = false;
  };

  inputs.passwords = {
    url = "path:/etc/nixos/passwords.nix";
    flake = false;
  };

  outputs = inputs: rec {
    nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs system; };
    };

    defaultPackage.x86_64-linux = nixosConfigurations.nixos.config.system.build.toplevel;
    legacyPackages.x86_64-linux = nixosConfigurations.nixos.pkgs;
  };
}
