{ config, lib, pkgs, inputs, system, ... }:

let
  passwords = import inputs.passwords;

  nur-no-pkgs = import inputs.nur {
    nurpkgs = import inputs.nixpkgs {
      inherit system;
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
in

with lib;
{
  imports = attrValues nur-no-pkgs.repos.ilya-fedin.modules;

  nixpkgs.config = {
    allowUnfree = true;
    oraclejdk.accept_license = true;
    joypixels.acceptLicense = true;
  };

  nixpkgs.overlays = [
    nurOverlay
    (import inputs.mozilla)
    nur-no-pkgs.repos.ilya-fedin.overlays.portal
  ];

  system.replaceRuntimeDependencies = [
    {
      original = pkgs.glibcLocales;
      replacement = config.i18n.glibcLocales;
    }
  ];

  nix.package = pkgs.nixUnstable;
  nix.nixPath = mkForce [
    "nixpkgs=/etc/static/nixpkgs"
    "nixos-config=/etc/nixos/configuration.nix"
    "nixpkgs-overlays=/etc/nixos/overlays-compat"
  ];
  nix.settings.cores = 9;
  nix.settings.trusted-users = [ "root" "@wheel" ];
  nix.registry.self.flake = inputs.self;
  nix.extraOptions = ''
    sandbox = false
    experimental-features = nix-command flakes
  '';

  nix.settings.substituters = [
    "https://ilya-fedin.cachix.org"
  ];

  nix.settings.trusted-public-keys = [
    "ilya-fedin.cachix.org-1:QveU24a5ePPMh82mAFSxLk1P+w97pRxqe9rh+MJqlag="
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-partlabel/swap"; }
  ];

  boot.loader.unifiedKernelImage.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [ "mitigations=off" "nowatchdog" "nmi_watchdog=0" "quiet" "rd.systemd.show_status=auto" "rd.udev.log_priority=3" ];
  boot.kernelModules = [ "kvm-amd" "bfq" ];

  boot.initrd.includeDefaultModules = false;
  boot.initrd.availableKernelModules = [ "sd_mod" "nvme" "ext4" "i8042" "atkbd" "amdgpu" ];
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

  hardware.firmware = with pkgs; [ linux-firmware ];
  hardware.bluetooth.enable = true;
  hardware.usbWwan.enable = true;

  hardware.opengl.enable = true;
  hardware.opengl.package = pkgs.nur.repos.ilya-fedin.mesa-drivers-amd;

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

  environment.etc.nixpkgs.source = inputs.nixpkgs;

  environment.systemPackages = with pkgs; [
    file
    psmisc
    inetutils
    pciutils
    usbutils
    micro
    adapta-backgrounds
    adapta-gtk-theme
    adapta-kde-theme
    git
    neofetch
    libsForQt5.qtstyleplugin-kvantum
    (lowPrio libsForQt514.qt5ct)
    yakuake
    go-mtpfs
    latest.firefox-beta-bin
    ark
    dolphin
    kate
    konsole
    okteta
    okular
    spectacle
    vlc
    gimp
    wget
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
    ix
    nur.repos.ilya-fedin.silver
    dfeet
    bustle
    qemu_kvm
    (gnome3.gnome-boxes.override {
      qemu = qemu_kvm;
      qemu-utils = qemu-utils.override {
        qemu = qemu_kvm;
      };
    })
    neochat
    p7zip
    vscode-fhs
  ];

  environment.defaultPackages = [];

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

  systemd.services.polkit.restartIfChanged = false;
  systemd.services.NetworkManager-wait-online.wantedBy = mkForce [];

  systemd.user.services.xrandr-scale = {
    description = "Scale the screen with xrandr";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --scale 1.5";
      Type = "oneshot";
    };
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
    map to guest = bad user
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
    UseBridges = true;
    ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/obfs4proxy";
    Bridge = "obfs4 137.220.35.35:443 75B34B8458A1C93714BFF9393E09F7CBC04A2F59 cert=GglhKh0UwOjkfQPN0aH3gs8ZdnE6T4qU9uU/fmiYbJ69Dpk4nxS9o82UBnAxVZJytOulfA iat-mode=0";
  };

  services.teamviewer.enable = true;

  services.gnome.at-spi2-core.enable = mkForce false;
  services.gnome.gnome-keyring.enable = mkForce false;
  services.gvfs.package = pkgs.gvfs;
  services.flatpak.enable = true;

  xdg.icons.icons = with pkgs; [
    papirus-icon-theme
    (getBin breeze-qt5)
  ];

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
    media-session.enable = false;
    wireplumber.enable = true;
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

  services.xserver.desktopManager.mate.enable = true;
  environment.mate.excludePackages = with pkgs; with mate; [
    caja
    engrampa
    atril
    mate-netbook
    mate-themes
    mate-icon-theme
    mate-user-guide
    mate-terminal
    pluma
    yelp
  ];

  fonts.fonts = with pkgs; [
    nur.repos.ilya-fedin.exo2
    nur.repos.ilya-fedin.cascadia-code-powerline
    unifont
    symbola
    joypixels
    nur.repos.ilya-fedin.nerd-fonts-symbols
  ];

  fonts.enableDefaultFonts = false;

  fonts.fontconfig.hinting.enable = false;
  fonts.fontconfig.subpixel.rgba = "none";
  fonts.fontconfig.subpixel.lcdfilter = "none";

  fonts.fontconfig.crOSMaps = true;

  fonts.fontconfig.defaultFonts.sansSerif = [ "Exo 2" "Symbols Nerd Font" ];
  fonts.fontconfig.defaultFonts.serif = [ "Tinos Nerd Font" ];
  fonts.fontconfig.defaultFonts.monospace = [ "Cascadia Code PL" "Symbols Nerd Font" ];
  fonts.fontconfig.defaultFonts.emoji = [ "JoyPixels" ];

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
