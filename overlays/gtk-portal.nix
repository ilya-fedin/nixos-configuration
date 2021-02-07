self: super: {
  xdg-desktop-portal-gtk = super.xdg-desktop-portal-gtk.overrideAttrs(oldAttrs: {
    postInstall = ''
      substituteInPlace $out/share/xdg-desktop-portal/portals/gtk.portal \
        --replace "org.freedesktop.impl.portal.FileChooser;" ""
    '';
  });
}
