self: super:
with super.lib;
let
  # Import flake-compat
  flake-compat = import (fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/99f1c2157fba4bfe6211a321fd0ee43199025dbf.tar.gz";
    sha256 = "0x2jn3vrawwv9xp15674wjz9pixwjyj3j771izayl962zziivbx2";
  });
  # Get outputs
  outputs = (flake-compat {src = ./..;}).defaultNix.outputs;
  # then get the `nixpkgs.overlays` option.
  paths = outputs.nixosConfigurations.nixos.config.nixpkgs.overlays
  ;
in
foldl' (flip extends) (_: super) paths self
