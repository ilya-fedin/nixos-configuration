{ config, inputs, ... }:

let
  passwords = import inputs.passwords;

  nixpkgsConfig = {
    allowUnfree = true;
    oraclejdk.accept_license = true;
    joypixels.acceptLicense = true;
  };

  nur-no-pkgs = import inputs.nur {
    nurpkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [];
    };

    repoOverrides = {
      ilya-fedin = import inputs.nur-repo-override {};
    };
  };

  nurOverlay = self: super: {
    nur = import inputs.nur {
      nurpkgs = super;
      pkgs = super;
      repoOverrides = {
        ilya-fedin = import inputs.nur-repo-override {
          pkgs = super;
        };
      };
    };
  };

  overlays = [
    nurOverlay
    (import inputs.mozilla)
    nur-no-pkgs.repos.ilya-fedin.overlays.portal
  ];

  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config = nixpkgsConfig;
    overlays = overlays;
  };

  inherit (pkgs) lib nur;
in

with lib;
{
  imports = [
    (import inputs.hardware-configuration)
  ] ++ attrValues nur.repos.ilya-fedin.modules;

  nixpkgs.config = nixpkgsConfig;
  nixpkgs.overlays = overlays;

  nix.package = pkgs.nixUnstable;
  nix.nixPath = mkForce [
    "nixpkgs=/etc/nixpkgs"
    "nixos-config=/etc/nixos/configuration.nix"
    "nixpkgs-overlays=/etc/nixos/overlays-compat"
  ];
  nix.buildCores = 9;
  nix.trustedUsers = [ "root" "@wheel" ];
  nix.registry.self.flake = inputs.self;
  nix.extraOptions = ''
    sandbox = false
    experimental-features = nix-command flakes
  '';

  nix.binaryCaches = [
    "https://ilya-fedin.cachix.org"
  ];

  nix.binaryCachePublicKeys = [
    "ilya-fedin.cachix.org-1:QveU24a5ePPMh82mAFSxLk1P+w97pRxqe9rh+MJqlag="
  ];

  boot.loader.unifiedKernelImage.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [ "mitigations=off" "nowatchdog" "nmi_watchdog=0" "quiet" "rd.systemd.show_status=auto" "rd.udev.log_priority=3" ];
  boot.kernelModules = [ "bfq" ];

  boot.initrd.availableKernelModules = mkForce [ "sd_mod" "nvme" "ext4" "i8042" "atkbd" "amdgpu" ];
  boot.blacklistedKernelModules = [ "iTCO_wdt" "uvcvideo" ];

  boot.cleanTmpDir = true;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

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
    sane-airscan
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

  environment.etc.nixpkgs.source = pkgs.path;

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
    latest.firefox-beta-bin
    ark
    dolphin
    kate
    konsole
    okteta
    okular
    spectacle
    vlc
    nfs-utils
    ntfs3g
    gimp
    wget
    iptables
    filezilla
    youtube-dl
    nur.repos.ilya-fedin.kotatogram-desktop
    vokoscreen-ng
    qbittorrent
    libarchive
    unzip
    zip
    unrar
    gnome3.dconf-editor
    xclip
    htop
    plasma5Packages.kio
    plasma5Packages.kio-extras
    plasma5Packages.dolphin-plugins
    plasma5Packages.kdegraphics-thumbnailers
    plasma5Packages.ffmpegthumbs
    plasma5Packages.kglobalaccel
    plasma5Packages.kwallet
    kwalletmanager
    ix
    nur.repos.ilya-fedin.silver
    dfeet
    bustle
    samba
    qemu
    libvirt
    gnome3.gnome-boxes
    zstd
    neochat
    vscodium
    p7zip
  ];

  environment.sessionVariables = rec {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "micro";
    VISUAL = EDITOR;
    SYSTEMD_EDITOR = EDITOR;
    QT_STYLE_OVERRIDE = "kvantum";
    MOZ_DISABLE_CONTENT_SANDBOX = "1";
  };

  programs.fish.enable = true;
  programs.ssh.askPassword = "${pkgs.ksshaskpass}/bin/ksshaskpass";
  programs.adb.enable = true;
  programs.system-config-printer.enable = false;

  programs.ssh.extraConfig = ''
    Host *
    ServerAliveInterval 100
  '';

  programs.nm-applet.enable = true;
  programs.qt5ct.enable = true;

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
  services.avahi.nssmdns = true;

  services.samba.enable = true;
  services.samba.nsswins = true;

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

  services.gnome.at-spi2-core.enable = mkForce false;
  services.gnome.gnome-keyring.enable = mkForce false;
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
  virtualisation.virtualbox.host.enableExtensionPack = true;

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
    mate-netbook caja engrampa pluma atril
  ];

  fonts.fonts = with pkgs; [
    nur.repos.ilya-fedin.exo2
    joypixels
    (nerdfonts.override {
      fonts = [
        "Arimo"
      ];
    })
  ];

  fonts.fontconfig.hinting.enable = false;
  fonts.fontconfig.subpixel.rgba = "none";
  fonts.fontconfig.subpixel.lcdfilter = "none";

  fonts.fontconfig.crOSMaps = true;
  fonts.fontconfig.useNotoCjk = true;

  fonts.fontconfig.defaultFonts.sansSerif = [ "Exo 2" "Arimo Nerd Font" ];
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
    extraGroups = [ "wheel" "dialout" "networkmanager" "docker" "lxd" "vboxusers" "adbusers" "sambashare" ];
    uid = 1000;
    isNormalUser = true;
  };

  users.groups.sambashare = {};

  system.stateVersion = "21.05";
}
