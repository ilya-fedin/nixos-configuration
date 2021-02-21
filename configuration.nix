{ config, ... }:

let
  sources = import ./nix/sources.nix;

  passwords = import ./passwords.nix;

  overlays = [
    (import ./overlays/nur.nix)
    (import ./overlays/gtk-portal.nix)
  ];

  pkgs = import sources.nixpkgs {
    overlays = overlays;
    config = {
      allowUnfree = true;
      oraclejdk.accept_license = true;
      joypixels.acceptLicense = true;
    };
  };

  inherit (pkgs) lib nur;

  addToXDGDirs = p: ''
    if [ -d "${p}/share/gsettings-schemas/${p.name}" ]; then
      export XDG_DATA_DIRS=$XDG_DATA_DIRS''${XDG_DATA_DIRS:+:}${p}/share/gsettings-schemas/${p.name}
    fi
    if [ -d "${p}/lib/girepository-1.0" ]; then
      export GI_TYPELIB_PATH=$GI_TYPELIB_PATH''${GI_TYPELIB_PATH:+:}${p}/lib/girepository-1.0
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}${p}/lib
    fi
  '';
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
  nix.buildCores = 9;
  nix.trustedUsers = [ "root" "@wheel" ];

  boot.loader.systemd-boot.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [ "mitigations=off" "nowatchdog" "nmi_watchdog=0" "quiet" "rd.systemd.show_status=auto" "rd.udev.log_priority=3" ];
  boot.kernelModules = [ "bfq" ];

  boot.initrd.availableKernelModules = mkForce [ "sd_mod" "nvme" "ext4" "i8042" "atkbd" "i915" ];
  boot.blacklistedKernelModules = [ "iTCO_wdt" "uvcvideo" ];

  boot.cleanTmpDir = true;
  boot.consoleLogLevel = 3;

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.printk" = "3 3 3 3";
    "net.ipv4.conf.all.rp_filter" = 1;
  };

  powerManagement.cpuFreqGovernor = "schedutil";

  hardware.bluetooth.enable = true;
  hardware.usbWwan.enable = true;

  hardware.opengl.enable = true;

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
    defaultLocale = "ru_RU.UTF-8";
    supportedLocales = [ "ru_RU.UTF-8/UTF-8" ];
  };

  console = {
    packages = with pkgs; [ terminus_font ];
    font = "ter-v16n";
    keyMap = "ru";
    earlySetup = true;
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
    (getBin breeze-qt5)
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
    ark
    okteta
    vlc
    nfs-utils
    ntfs3g
    gimp
    wget
    iptables
    filezilla
    youtube-dl
    kotatogram-desktop
    vokoscreen
    qbittorrent
    libarchive
    unzip
    zip
    unrar
    gnome3.dconf-editor
    xclip
    htop
    plasma5Packages.kio
    plasma5Packages.kglobalaccel
    plasma5Packages.kwallet
    kwalletmanager
    ix
    nur.repos.ilya-fedin.silver
    steam-run
    dfeet
    bustle
    samba
    qemu
    libvirt
    gnome3.gnome-boxes
    zstd
  ];

  environment.sessionVariables = rec {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "micro";
    VISUAL = EDITOR;
    SYSTEMD_EDITOR = EDITOR;
    QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
    QT_STYLE_OVERRIDE = "kvantum";
    MOZ_DISABLE_CONTENT_SANDBOX = "1";
    TDESKTOP_DISABLE_TRAY_COUNTER = "1";
  };

  environment.extraInit = ''
    ${addToXDGDirs pkgs.gnome3.gnome-settings-daemon}
  '';

  programs.fish.enable = true;
  programs.ssh.askPassword = "${pkgs.ksshaskpass}/bin/ksshaskpass";
  programs.adb.enable = true;
  programs.system-config-printer.enable = false;

  programs.ssh.extraConfig = ''
    Host *
    ServerAliveInterval 100
  '';

  programs.nm-applet.enable = true;

  programs.vscode.enable = true;
  programs.vscode.user = "ilya";
  programs.vscode.homeDir = "/home/ilya";
  programs.vscode.extensions = with pkgs.vscode-extensions; [
    ms-vscode.cpptools
  ];

  systemd.services.polkit = {
    restartIfChanged = false;
  };

  services.udev.optimalSchedulers = true;
  services.fstrim.enable = true;

  services.logind.killUserProcesses = true;
  services.earlyoom.enable = true;

  services.dbus-broker.enable = true;

  services.resolved.enable = true;
  services.resolved.dnssec = "false";

  services.printing.enable = true;
  services.printing.startWhenNeeded = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    hplip
  ];

  services.openssh.enable = true;
  services.openssh.forwardX11 = true;

  services.avahi.enable = true;
  services.samba.enable = true;

  services.samba.extraConfig = ''
    workgroup = WORKGROUP
    server min protocol = NT1
    client min protocol = NT1
    ntlm auth = yes
    guest account = ilya

    usershare path = /var/lib/samba/usershares
    usershare max shares = 100
    usershare allow guests = yes
    usershare owner only = yes
  '';

  services.yggdrasil.enable = true;

  services.yggdrasil.config = {
    Peers = [
      tcp://194.177.21.156:5066
      tcp://46.151.26.194:60575
      tcp://195.211.160.2:5066
      tcp://188.226.125.64:54321
      tcp://78.155.207.12:32320
    ];
  } // passwords.yggdrasil-keys;

  services.tor.enable = true;
  services.tor.client.enable = true;

  services.tor.settings = {
    ExitNodes = "{ua}";
  };

  services.teamviewer.enable = true;

  services.gnome3.at-spi2-core.enable = mkForce false;
  services.gnome3.gnome-keyring.enable = mkForce false;
  services.flatpak.enable = true;

  xdg.portal.enable = true;
  xdg.portal.gtkUsePortal = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    xdg-desktop-portal-kde
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;

  virtualisation.lxd.enable = true;
  security.apparmor.enable = mkForce false;

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.package = pkgs.virtualboxWithExtpack;

  networking.firewall.enable = false;
  networking.usePredictableInterfaceNames = false;

  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.xserver.enable = true;
  services.xserver.layout = "us,ru";
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.libinput.enable = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "ilya";
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --scale 1.5
  '';

  security.pam.services.sddm.enableKwallet = true;

  services.xserver.desktopManager.mate.enable = true;
  environment.mate.excludePackages = with pkgs.mate; [
    mate-netbook
  ];

  fonts.fonts = with pkgs; [
    joypixels
  ];

  fonts.fontconfig.subpixel.rgba = "none";

  fonts.fontconfig.crOSMaps = true;
  fonts.fontconfig.useNotoCjk = true;

  fonts.fontconfig.defaultFonts.sansSerif = [ "Exo 2" ];
  fonts.fontconfig.defaultFonts.serif = [ "Roboto Slab" ];
  fonts.fontconfig.defaultFonts.monospace = [ "Cascadia Code" "FiraCode Nerd Font" ];
  fonts.fontconfig.defaultFonts.emoji = [ "JoyPixels" ];

  fonts.fontconfig.cascadiaCode.enableFallback = true;
  fonts.fontconfig.cascadiaCode.fallbackFont = "FiraCode Nerd Font";
  fonts.fontconfig.cascadiaCode.fallbackPackage = pkgs.nerdfonts.override {
    fonts = [
      "FiraCode"
    ];
  };

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;

  users.users.root = {
    password = passwords.root;
  };

  users.users.ilya = {
    description = "Илья Федин";
    password = passwords.ilya;
    extraGroups = [ "wheel" "docker" "lxd" "vboxusers" "adbusers" "sambashare" ];
    uid = 1000;
    isNormalUser = true;
  };

  users.groups.sambashare = {};

  system.stateVersion = "20.03";
}
