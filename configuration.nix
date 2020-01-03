let
  sources = import ./nix/sources.nix;

  passwords = import ./passwords.nix;

  overlays = [ (import ./overlays/nur.nix) ];

  pkgs = import sources.nixpkgs {
    overlays = overlays;
    config = {
      allowUnfree = true;
      oraclejdk.accept_license = true;
    };
  };

  inherit (pkgs) lib nur;
in

with lib;
{
  imports =
    [
      ./hardware-configuration.nix
    ] ++ attrValues nur.repos.ilya-fedin.modules;

  nixpkgs.overlays = overlays;
  nixpkgs.niv.enable = true;

  nix.nixPath = [ "nixpkgs-overlays=/etc/nixos/overlays-compat" ];
  nix.buildCores = 2;
  nix.trustedUsers = [ "root" "@wheel" ];

  boot.loader.systemd-boot.enable = true;

  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "intel_pstate=disable" "i915.fastboot=1" "i915.nuclear_pageflip=1" "mitigations=off" "nowatchdog" "nmi_watchdog=0" "quiet" "rd.systemd.show_status=auto" "rd.udev.log_priority=3" ];
  boot.kernelModules = [ "bfq" ];

  boot.initrd.availableKernelModules = mkForce [ "sd_mod" "ahci" "ext4" "i8042" "atkbd" "i915" ];
  boot.blacklistedKernelModules = [ "iTCO_wdt" "uvcvideo" ];

  boot.cleanTmpDir = true;
  boot.earlyVconsoleSetup = true;
  boot.consoleLogLevel = 3;

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.printk" = "3 3 3 3";
    "net.ipv4.conf.all.rp_filter" = 1;
  };

  powerManagement.powertop.enable = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  hardware.bluetooth.enable = true;
  hardware.usbWwan.enable = true;

  hardware.opengl.enable = true;
  hardware.opengl.s3tcSupport = true;
  hardware.opengl.useIrisDriver = true;

  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver
  ];

  hardware.sane.enable = true;
  hardware.sane.extraBackends = with pkgs; [
    hplipWithPlugin
  ];

  networking.hostName = "nixos";
  networking.dhcpcd.enable = false;

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;

  i18n = {
    consolePackages = with pkgs; [ terminus_font ];
    consoleFont = "ter-v16n";
    consoleKeyMap = "ru";
    defaultLocale = "ru_RU.UTF-8";
    supportedLocales = [ "ru_RU.UTF-8/UTF-8" ];
  };

  time.timeZone = "Europe/Saratov";

  environment.systemPackages = with pkgs; [
    file
    psmisc
    telnet
    pciutils
    usbutils
    micro
    qt5.qttools
    adapta-backgrounds
    adapta-gtk-theme
    adapta-kde-theme
    git
    neofetch
    papirus-icon-theme
    libsForQt5.qtstyleplugin-kvantum
    remmina
    sshfs
    yakuake
    go-mtpfs
    lm_sensors
    firefox-beta-bin
    okteta
    vscode
    vlc
    nfs-utils
    ntfs3g
    gimp
    wget
    iptables
    filezilla
    youtube-dl
    tdesktop
    vokoscreen
    qbittorrent
    quaternion
    plasma-integration
    p7zip
    unzip
    zip
    unrar
    gnome3.dconf-editor
    xclip
    htop
    kdeFrameworks.kglobalaccel
    kdeFrameworks.kwallet
    kwalletmanager
    ix
    nur.repos.ilya-fedin.silver
    steam-run
    oraclejdk8
    dfeet
    bustle
    samba
  ];

  environment.sessionVariables = rec {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "micro";
    VISUAL = EDITOR;
    SYSTEMD_EDITOR = EDITOR;
    LIBVA_DRIVER_NAME = "iHD";
  };

  programs.fish.enable = true;
  programs.ssh.askPassword = "${pkgs.ksshaskpass}/bin/ksshaskpass";
  programs.adb.enable = true;
  programs.qt5ct.enable = true;
  programs.system-config-printer.enable = false;

  programs.ssh.extraConfig = ''
    Host *
    ServerAliveInterval 100
  '';

  programs.nm-applet.enable = true;
  systemd.user.services.nm-applet.serviceConfig.ExecStart = mkForce "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";

  services.udev.optimalSchedulers = true;
  services.fstrim.enable = true;

  services.logind.killUserProcesses = true;
  services.earlyoom.enable = true;

  services.nscd.enable = false;
  services.dbus-broker.enable = true;

  services.resolved.enable = true;
  services.resolved.dnssec = "false";

  services.printing.enable = true;
  services.printing.startWhenNeeded = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    hplip
  ];

  services.avahi.enable = true;
  services.samba.enable = true;

  services.samba.extraConfig = ''
    workgroup = WORKGROUP
    guest account = ilya

    usershare path = /var/lib/samba/usershares
    usershare max shares = 100
    usershare allow guests = yes
    usershare owner only = yes
  '';

  services.tor.enable = true;
  services.tor.client.enable = true;

  services.tor.extraConfig = ''
    ExitNodes {ua}
  '';

  services.teamviewer.enable = true;

  services.gnome3.at-spi2-core.enable = mkForce false;
  services.gnome3.gnome-keyring.enable = mkForce false;
  services.flatpak.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-kde
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;

  networking.firewall.enable = false;
  networking.usePredictableInterfaceNames = false;

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;

  services.xserver.enable = true;
  services.xserver.dpi = 120;
  services.xserver.layout = "us,ru";
  services.xserver.useGlamor = true;
  services.xserver.libinput.enable = true;
  services.xserver.displayManager.xserverArgs = [ "-ac" ];

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoLogin.enable = true;
  services.xserver.displayManager.sddm.autoLogin.user = "ilya";
  security.pam.services.sddm.enableKwallet = true;

  services.xserver.desktopManager.mate.enable = true;

  fonts.fonts = with pkgs; [
    joypixels
  ];

  fonts.fontconfig.dpi = 120;
  fonts.fontconfig.subpixel.rgba = "none";

  fonts.fontconfig.crOSMaps = true;
  fonts.fontconfig.extraEmojiConfiguration = true;
  fonts.fontconfig.useNotoCjk = true;

  fonts.fontconfig.defaultFonts.sansSerif = [ "Roboto" ];
  fonts.fontconfig.defaultFonts.serif = [ "Roboto Slab" ];
  fonts.fontconfig.defaultFonts.monospace = [ "Cascadia Code" "FuraCode Nerd Font" ];
  fonts.fontconfig.defaultFonts.emoji = [ "JoyPixels" ];

  fonts.fontconfig.cascadiaCode.enableFallback = true;
  fonts.fontconfig.cascadiaCode.fallbackFont = "FuraCode Nerd Font";
  fonts.fontconfig.cascadiaCode.fallbackPackage = pkgs.nerdfonts;

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;

  users.users.root = {
    password = passwords.root;
  };

  users.users.ilya = {
    description = "Илья Федин";
    password = passwords.ilya;
    extraGroups = [ "wheel" "docker" "adbusers" "sambashare" ];
    uid = 1000;
    isNormalUser = true;
  };

  users.groups.sambashare = {};

  system.stateVersion = "unstable";
}
