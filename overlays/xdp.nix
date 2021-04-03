self: super: {
  xdg-desktop-portal = super.xdg-desktop-portal.overrideAttrs(oldAttrs: {
    patches = oldAttrs.patches ++ [
      ./patches/fix-removing-directories.patch
    ];
  });
}
