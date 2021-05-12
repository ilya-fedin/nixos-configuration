{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nur.url = "github:nix-community/NUR";

  inputs.nur-repo-override = {
    url = "path:/home/ilya/nur-repository";
    flake = false;
  };

  inputs.hardware-configuration = {
    url = "path:hardware-configuration.nix";
    flake = false;
  };

  inputs.passwords = {
    url = "path:passwords.nix";
    flake = false;
  };

  outputs = { self, nixpkgs, nur, nur-repo-override, hardware-configuration, passwords }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs; };
    };
  };
}
