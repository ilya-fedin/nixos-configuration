{ config, lib, pkgs, inputs, system, hostname, ... }:

with lib;
{
  imports = attrValues inputs.nur-no-pkgs.${system}.repos.ilya-fedin.modules;

  system.replaceRuntimeDependencies = [
    {
      original = pkgs.glibcLocales;
      replacement = config.i18n.glibcLocales;
    }
  ];

  nix.nixPath = mkForce [
    "nixpkgs=/etc/static/nixpkgs"
    "nixos-config=/etc/nixos/configuration.nix"
  ];
  nix.settings.cores = 9;
  nix.settings.trusted-users = [ "root" "@wheel" ];
  nix.registry.self.flake = inputs.self;
  nix.extraOptions = ''
    tarball-ttl = 604800
    experimental-features = nix-command flakes
  '';

  nur.ilya-fedin.cache.enable = true;

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

  boot.loader.systemd-boot.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_lqx;
  boot.kernelParams = [
    "zswap.enabled=1"
    "pcie_acs_override=downstream,multifunction"
    "amd_pstate=active"
    "mitigations=off"
    "panic=1"
    "nowatchdog"
    "nmi_watchdog=0"
    "quiet"
    "rd.systemd.show_status=auto"
    "rd.udev.log_priority=3"
  ];
  boot.kernelModules = [ "kvm-amd" "bfq" ];

  boot.initrd.includeDefaultModules = false;
  boot.initrd.availableKernelModules = [ "sd_mod" "nvme" "ahci" "ext4" "i8042" "atkbd" "xhci_pci" "usbhid" "amdgpu" ];
  boot.blacklistedKernelModules = [ "iTCO_wdt" "sp5100_tco" "uvcvideo" ];

  boot.tmp.cleanOnBoot = true;
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
  hardware.usb-modeswitch.enable = true;

  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  hardware.opengl.enable = true;

  hardware.sane.enable = true;
  hardware.sane.extraBackends = with pkgs; [
    nur.repos.ilya-fedin.hplipWithPlugin
    sane-airscan
  ];

  networking.hostName = hostname;
  networking.dhcpcd.enable = false;

  systemd.network.links."40-eth0" = {
    matchConfig.OriginalName = "eth0";
    linkConfig.WakeOnLan = "magic";
  };

  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = mkForce [];
  networking.networkmanager.unmanaged = [ "type:wifi" ];
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings.General.EnableNetworkConfiguration = true;
  networking.firewall.enable = false;
  networking.usePredictableInterfaceNames = false;

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

  environment.etc.nixpkgs.source = inputs.nixpkgs.${system};

  environment.systemPackages = with pkgs; [
    file
    psmisc
    inetutils
    pciutils
    usbutils
    micro
    adapta-gtk-theme
    adapta-kde-theme
    git
    libsForQt5.qtstyleplugin-kvantum
    remmina
    yakuake
    go-mtpfs
    latest.firefox-beta-bin
    ark
    dolphin
    kate
    kcalc
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
    gnome.dconf-editor
    xclip
    htop
    xsettingsd
    plasma5Packages.kio
    plasma5Packages.kio-extras
    plasma5Packages.dolphin-plugins
    plasma5Packages.kdegraphics-thumbnailers
    plasma5Packages.ffmpegthumbs
    plasma5Packages.kglobalaccel
    ix
    dfeet
    bustle
    qemu_kvm
    virt-manager
    gnome.gnome-boxes
    element-desktop
    p7zip
    vscode
    nur.repos.ilya-fedin.nixos-collect-garbage
  ];

  environment.defaultPackages = [];

  environment.sessionVariables = rec {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "micro";
    VISUAL = EDITOR;
    SYSTEMD_EDITOR = EDITOR;
    GTK_USE_PORTAL = "1";
    MOZ_DISABLE_CONTENT_SANDBOX = "1";
    CUPS_SERVER = "rpi4";
  };

  programs.command-not-found.dbPath = "${builtins.fetchTarball "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz"}/programs.sqlite";

  programs.fish.enable = true;

  programs.fish.shellInit = ''
    ${config.programs.direnv.package}/bin/direnv hook fish | source
  '';

  programs.fish.interactiveShellInit = with pkgs; ''
    eval (${coreutils}/bin/dircolors -c)
  '';

  programs.fish.promptInit = with pkgs; with nur.repos.ilya-fedin; let
    silverConfig = writeText "silver.toml" ''
      [[left]]
      name = "status"
      color.background = "black"
      color.foreground = "none"

      [[left]]
      name = "dir"
      color.background = "blue"
      color.foreground = "black"

      [[left]]
      name = "git"
      color.background = "green"
      color.foreground = "black"
    '';
  in ''
    function fish_greeting
        ${neofetch}/bin/neofetch
    end

    function fish_prompt
        env code=$status jobs=(count (jobs -p)) cmdtime={$CMD_DURATION} ${silver}/bin/silver -c ${silverConfig} lprint
    end
    function fish_right_prompt
        env code=$status jobs=(count (jobs -p)) cmdtime={$CMD_DURATION} ${silver}/bin/silver -c ${silverConfig} rprint
    end

    set -x VIRTUAL_ENV_DISABLE_PROMPT 1
  '';

  programs.ssh.askPassword = "${pkgs.ksshaskpass}/bin/ksshaskpass";
  programs.adb.enable = true;
  programs.direnv.enable = true;
  programs.system-config-printer.enable = false;

  programs.ssh.extraConfig = ''
    Host *
    ServerAliveInterval 100
  '';

  systemd.packages = with pkgs; [
    dconf
    iwgtk
  ];

  systemd.services.polkit.restartIfChanged = false;
  systemd.services.NetworkManager-wait-online.wantedBy = mkForce [];

  systemd.services.zswap = {
    description = "zswap";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo zstd > /sys/module/zswap/parameters/compressor
      echo z3fold > /sys/module/zswap/parameters/zpool
    '';
  };

  systemd.user.services.iwgtk.wantedBy = [ "graphical-session.target" ];

  services.ananicy.enable = true;
  services.ananicy.package = pkgs.ananicy-cpp;
  services.irqbalance.enable = true;
  services.udev.optimalSchedulers = true;
  services.fstrim.enable = true;
  services.logind.killUserProcesses = true;
  services.logind.extraConfig = "UserStopDelaySec=0";
  services.earlyoom.enable = true;
  services.journald.extraConfig = "SystemMaxUse=100M";
  services.resolved.enable = true;
  services.resolved.dnssec = "false";
  services.gnome.at-spi2-core.enable = mkForce false;
  services.gnome.gnome-keyring.enable = mkForce false;
  services.gvfs.enable = true;
  services.gvfs.package = pkgs.gvfs;
  services.flatpak.enable = true;
  services.sysprof.enable = true;

  services.dbus.implementation = "broker";
  services.dbus.packages = with pkgs; [
    dconf
  ];

  services.printing.enable = true;
  services.printing.startWhenNeeded = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    hplip
  ];

  services.openssh.enable = true;
  services.openssh.settings.X11Forwarding = true;

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.avahi.nssmdns6 = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.addresses = true;
  services.avahi.publish.domain = true;
  services.avahi.publish.userServices = true;

  services.samba.enable = true;
  services.samba.package = pkgs.sambaFull;
  services.samba.nsswins = true;
  services.samba-wsdd.enable = true;

  services.samba.extraConfig = ''
    workgroup = WORKGROUP
    map to guest = bad user
    guest account = ilya

    usershare path = /var/lib/samba/usershares
    usershare max shares = 100
    usershare allow guests = yes
    usershare owner only = yes
  '';

  services.yggdrasil.enable = true;
  services.yggdrasil.settings = {
    Peers = [
      tcp://194.177.21.156:5066
      tcp://46.151.26.194:60575
      tcp://195.211.160.2:5066
      tcp://188.226.125.64:54321
      tcp://78.155.207.12:32320
    ];
  } // inputs.passwords.yggdrasil-keys;

  services.tor.enable = true;
  services.tor.client.enable = true;
  services.tor.settings = {
    ExitNodes = "{ua}";
    UseBridges = true;
    ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/obfs4proxy";
    Bridge = "obfs4 137.220.35.35:443 75B34B8458A1C93714BFF9393E09F7CBC04A2F59 cert=GglhKh0UwOjkfQPN0aH3gs8ZdnE6T4qU9uU/fmiYbJ69Dpk4nxS9o82UBnAxVZJytOulfA iat-mode=0";
  };

  xdg.icons.icons = with pkgs; [
    papirus-icon-theme
    (getBin breeze-qt5)
  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    xdg-desktop-portal-kde
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.lxc.enable = true;
  virtualisation.lxd.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.onShutdown = "shutdown";
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.libvirtd.qemu.package = pkgs.qemu_kvm;
  virtualisation.libvirtd.qemu.ovmf.packages = [
    (pkgs.OVMF.override {
      secureBoot = true;
      tpmSupport = true;
    }).fd
  ];

  virtualisation.libvirtd.hooks.qemu.win10 = pkgs.writeShellScript "win10" ''
    if [ "$1" != "win10" ]; then
      exit
    fi

    case $2 in
      prepare)
        systemctl stop display-manager
        systemctl stop user@\*
        modprobe -r amdgpu
        ;;
      release)
        modprobe amdgpu
        systemctl start display-manager
        systemctl restart systemd-vconsole-setup
        ;;
      esac
  '';

  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  environment.etc."wireplumber/main.lua.d/51-alsa-custom.lua".text = ''
    rules = {
      {
        matches = {
          {
            { "device.name", "matches", "alsa_card.pci-0000_2d_00.1" },
          },
        },
        apply_properties = {
          ["api.alsa.use-acp"] = false,
        },
      },
      {
        matches = {
          {
            { "node.name", "matches", "alsa_output.pci-0000_2d_00.1.playback.*" },
          },
        },
        apply_properties = {
          ["session.suspend-timeout-seconds"] = 0,
        },
      },
    }

    for _,v in ipairs(rules) do
        table.insert(alsa_monitor.rules, v)
    end
  '';

  services.xserver.enable = true;
  services.xserver.layout = "us,ru";
  services.xserver.xkbOptions = "grp:win_space_toggle";
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.libinput.enable = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.wayland.enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "ilya";
  services.xserver.displayManager.defaultSession = "plasmawayland";

  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.desktopManager.plasma5.runUsingSystemd = true;
  services.xserver.desktopManager.plasma5.useQtScaling = true;
  services.xserver.desktopManager.plasma5.phononBackend = "vlc";

  fonts.packages = with pkgs; mkForce [
    nur.repos.ilya-fedin.exo2
    nur.repos.ilya-fedin.cascadia-code-powerline
    nur.repos.ilya-fedin.ttf-croscore
    carlito
    caladea
    unifont
    symbola
    joypixels
    nur.repos.ilya-fedin.nerd-fonts-symbols
  ];

  fonts.enableDefaultPackages = false;

  fonts.fontconfig.hinting.enable = false;
  fonts.fontconfig.subpixel.rgba = "none";
  fonts.fontconfig.subpixel.lcdfilter = "none";

  fonts.fontconfig.crOSMaps = true;

  fonts.fontconfig.defaultFonts.sansSerif = [ "Exo 2" "Symbols Nerd Font" ];
  fonts.fontconfig.defaultFonts.serif = [ "Tinos" "Symbols Nerd Font" ];
  fonts.fontconfig.defaultFonts.monospace = [ "Cascadia Code PL" "Symbols Nerd Font" ];
  fonts.fontconfig.defaultFonts.emoji = [ "JoyPixels" ];

  users.mutableUsers = false;
  users.defaultUserShell = pkgs.fish;

  users.users.root = {
    hashedPassword = "";
  };

  users.users.ilya = {
    description = "Илья Федин";
    hashedPassword = "";
    extraGroups = [
      "wheel"
      "audio"
      "dialout"
      "disk"
      "input"
      "kmem"
      "kvm"
      "render"
      "tty"
      "users"
      "video"
      "networkmanager"
      "docker"
      "lxd"
      "libvirtd"
      "vboxusers"
      "adbusers"
      "sambashare"
    ];
    uid = 1000;
    isNormalUser = true;
  };

  users.groups.sambashare = {};

  system.stateVersion = "21.05";
}
