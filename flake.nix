{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur-repo-override.url = "path:/home/ilya/nur-repository";

  inputs.mozilla = {
    url = "github:mozilla/nixpkgs-mozilla";
    flake = false;
  };

  inputs.hardware-configuration = {
    url = "path:/etc/nixos/hardware-configuration.nix";
    flake = false;
  };

  inputs.passwords = {
    url = "path:/etc/nixos/passwords.nix";
    flake = false;
  };

  outputs = { self, nixpkgs, nur, mozilla, nur-repo-override, hardware-configuration, passwords }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs; };
    };

    defaultPackage.x86_64-linux = inputs.self.nixosConfigurations.nixos.config.system.build.toplevel;
    legacyPackages.x86_64-linux = (builtins.head (builtins.attrValues inputs.self.nixosConfigurations)).pkgs;
  };
}
