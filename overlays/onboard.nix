self: super: {
  onboard = super.onboard.overrideAttrs(oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ super.libappindicator-gtk3 ];
  });
}

