self: super: {
  nur = import (fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    nurpkgs = super;
    pkgs = super;
    repoOverrides = {
      ilya-fedin = import /home/ilya/nur-repository {
        pkgs = super;
      };
    };
  };
}
