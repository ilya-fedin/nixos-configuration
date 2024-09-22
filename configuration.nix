{ config, lib, pkgs, inputs, system, hostname, ... }:

with lib;
{
  imports = [
    inputs.chaotic.nixosModules.default
  ] ++ attrValues inputs.nur-no-pkgs.${system}.repos.ilya-fedin.modules;

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
  nix.settings.cores = if hostname == "asus-x421da"
    then 9
    else if hostname == "ms-7c94"
    then 33
    else if hostname == "beelink-ser5"
    then 13
    else null;
  nix.settings.trusted-users = [ "root" "@wheel" ];
  nix.registry.self.flake = inputs.self;
  nix.extraOptions = ''
    tarball-ttl = 604800
    experimental-features = nix-command flakes
  '';

  nur.ilya-fedin.cache.enable = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
    };
  } // optionalAttrs (hostname == "beelink-ser5") {
    "/srv/nfs/media" = {
      device = "/media";
      fsType = "none";
      options = [ "bind,x-systemd.automount" ];
    };

    "/srv/nfs/videos" = {
      device = "/home/ilya/videos";
      fsType = "none";
      options = [ "bind,x-systemd.automount" ];
    };
  };

  swapDevices = optional (hostname == "asus-x421da" || hostname == "ms-7c94") {
    device = "/dev/disk/by-partlabel/swap";
  };

  boot.loader.systemd-boot.enable = true;

  boot.kernelPackages = inputs.chaotic.packages.${system}.linuxPackages_cachyos;
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
  boot.kernelModules = [ "kvm-amd" "bfq" ]
    ++ optional (hostname == "beelink-ser5") "vhci-hcd"
    ++ optional (hostname == "asus-x421da") "cpufreq_conservative";

  boot.initrd.includeDefaultModules = false;
  boot.initrd.availableKernelModules = [ "sd_mod" "ext4" "amdgpu" ]
   ++ optionals (hostname == "asus-x421da" || hostname == "beelink-ser5") [ "nvme" ]
   ++ optionals (hostname == "ms-7c94") [ "ahci" ]
   ++ optionals (hostname == "asus-x421da") [ "i8042" "atkbd" ]
   ++ optionals (hostname == "ms-7c94" || hostname == "beelink-ser5") [ "xhci_pci" "usbhid" ];
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
  hardware.ksm.enable = true;
  hardware.bluetooth.enable = true;
  hardware.usb-modeswitch.enable = true;

  hardware.logitech.wireless = optionalAttrs (hostname == "ms-7c94") {
    enable = true;
    enableGraphical = true;
  };

  hardware.graphics.enable = true;

  hardware.sane.enable = true;
  hardware.sane.extraBackends = with pkgs; [
    nur.repos.ilya-fedin.hplipWithPlugin
    sane-airscan
  ];

  services.saned = optionalAttrs (hostname == "beelink-ser5") {
    enable = true;
    extraConfig = "0.0.0.0/0";
  };

  networking.hostName = hostname;
  networking.dhcpcd.enable = false;

  systemd.network.links = optionalAttrs (hostname == "ms-7c94" || hostname == "beelink-ser5") {
    "40-eth0" = {
      matchConfig.OriginalName = "eth0";
      linkConfig.WakeOnLan = "magic";
    };
  };

  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = mkForce [];
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;
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

  environment.etc = {
    nixpkgs.source = inputs.nixpkgs.${system};
  };

  environment.systemPackages = with pkgs; [
    file
    psmisc
    inetutils
    pciutils
    usbutils
    micro
    git
    htop
    ix
    config.boot.kernelPackages.usbip
    nur.repos.ilya-fedin.nixos-collect-garbage
  ] ++ optionals (hostname == "asus-x421da" || hostname == "ms-7c94") ([
    adapta-gtk-theme
    adapta-kde-theme
    papirus-icon-theme
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    kdePackages.yakuake
    kdePackages.kcalc
    okteta
    remmina
    go-mtpfs
    haruna
    krita
    wget
    nur.repos.ilya-fedin.kotatogram-desktop-with-patched-qt
    qbittorrent
    libarchive
    unzip
    zip
    unrar
    xclip
    xsettingsd
    d-spy
    bustle
    qemu_kvm
    virt-manager
    element-desktop
    p7zip
    vscode
    jamesdsp
  ] ++ config.programs.firefox.nativeMessagingHosts.packages);

  environment.defaultPackages = [];

  environment.sessionVariables = rec {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "${pkgs.micro}/bin/micro";
    VISUAL = EDITOR;
    SYSTEMD_EDITOR = EDITOR;
  } // optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    GTK_USE_PORTAL = "1";
    MOZ_DISABLE_CONTENT_SANDBOX = "1";
    CUPS_SERVER = "beelink-ser5";
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

  programs.firefox = {
    enable = true;
    package = pkgs.latest.firefox-beta-bin;
    languagePacks = [ "ru" ];
    nativeMessagingHosts.packages = with pkgs; [
      firefoxpwa
      vdhcoapp
    ];
  };

  systemd.packages = with pkgs; optionals (hostname == "asus-x421da" || hostname == "ms-7c94") [
    dconf
  ] ++ optionals (hostname == "beelink-ser5") [
    udevil
    qbittorrent-nox
  ];

  systemd.services = {
    polkit.restartIfChanged = false;
    NetworkManager-wait-online.wantedBy = mkForce [];

    zswap = {
      description = "zswap";
      wantedBy = [ "sysinit.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        echo zstd > /sys/module/zswap/parameters/compressor
        echo z3fold > /sys/module/zswap/parameters/zpool
      '';
    };
  } // optionalAttrs (hostname == "beelink-ser5") {
    "devmon@ilya" = {
      environment = {
        PATH = mkForce "/run/current-system/sw/bin:${pkgs.udevil}/bin";
      };
      overrideStrategy = "asDropin";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = "";
      };
    };

    "qbittorrent-nox@ilya" = {
      overrideStrategy = "asDropin";
      serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      wantedBy = [ "multi-user.target" ];
    };

    node-red.path = [ "/run/wrappers" config.system.path ];

    PowerTunnel = {
      serviceConfig = {
        ExecStart = let
          PowerTunnel = pkgs.fetchurl {
            url = "https://github.com/krlvm/PowerTunnel/releases/download/v2.5.2/PowerTunnel.jar";
            name = "PowerTunnel.jar";
            sha256 = "sha256-UlA2b/wi+zZsjRXR2qjqidh9uHS83YLOgHX3A4Wfzn0=";
          };
        in "${pkgs.jre}/bin/java -jar ${PowerTunnel}";
        WorkingDirectory = "/var/lib/PowerTunnel";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

  systemd.tmpfiles.rules = optional (hostname == "beelink-ser5") "d /var/lib/PowerTunnel 0700 root root - -";

  services.irqbalance.enable = true;
  services.udev.optimalSchedulers = true;
  services.udev.packages = [
    (pkgs.runCommand "bitbox02-udev" {} ''
      mkdir -p $out/etc/udev/rules.d
      printf "SUBSYSTEM==\"usb\", TAG+=\"uaccess\", TAG+=\"udev-acl\", SYMLINK+=\"bitbox02_%%n\", ATTRS{idVendor}==\"03eb\", ATTRS{idProduct}==\"2403\"\n" > $out/etc/udev/rules.d/53-hid-bitbox02.rules && printf "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{idVendor}==\"03eb\", ATTRS{idProduct}==\"2403\", TAG+=\"uaccess\", TAG+=\"udev-acl\", SYMLINK+=\"bitbox02_%%n\"\n" > $out/etc/udev/rules.d/54-hid-bitbox02.rules
      printf "SUBSYSTEM==\"usb\", TAG+=\"uaccess\", TAG+=\"udev-acl\", SYMLINK+=\"dbb%%n\", ATTRS{idVendor}==\"03eb\", ATTRS{idProduct}==\"2402\"\n" > $out/etc/udev/rules.d/51-hid-digitalbitbox.rules && printf "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{idVendor}==\"03eb\", ATTRS{idProduct}==\"2402\", TAG+=\"uaccess\", TAG+=\"udev-acl\", SYMLINK+=\"dbbf%%n\"\n" > $out/etc/udev/rules.d/52-hid-digitalbitbox.rules
    '')
  ];
  services.udev.extraRules = optionalString (hostname == "beelink-ser5") ''
    # UDISKS_FILESYSTEM_SHARED
    # ==1: mount filesystem to a shared directory (/media/VolumeName)
    # ==0: mount filesystem to a private directory (/run/media/$USER/VolumeName)
    # See udisks(8)
    ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"
  '';
  services.fstrim.enable = true;
  services.logind.killUserProcesses = true;
  services.logind.extraConfig = "UserStopDelaySec=0";
  services.earlyoom.enable = true;
  services.journald.extraConfig = "SystemMaxUse=100M";
  services.resolved.enable = true;
  services.resolved.dnssec = "false";
  security.polkit.enable = true;
  security.polkit.extraConfig = optionalString (hostname == "beelink-ser5") ''
    polkit.addRule(function(action, subject) {
      var YES = polkit.Result.YES;
      var permission = {
        // required for udisks1:
        "org.freedesktop.udisks.filesystem-mount": YES,
        "org.freedesktop.udisks.luks-unlock": YES,
        "org.freedesktop.udisks.drive-eject": YES,
        "org.freedesktop.udisks.drive-detach": YES,
        // required for udisks2:
        "org.freedesktop.udisks2.filesystem-mount": YES,
        "org.freedesktop.udisks2.encrypted-unlock": YES,
        "org.freedesktop.udisks2.eject-media": YES,
        "org.freedesktop.udisks2.power-off-drive": YES,
        // required for udisks2 if using udiskie from another seat (e.g. systemd):
        "org.freedesktop.udisks2.filesystem-mount-other-seat": YES,
        "org.freedesktop.udisks2.filesystem-unmount-others": YES,
        "org.freedesktop.udisks2.encrypted-unlock-other-seat": YES,
        "org.freedesktop.udisks2.encrypted-unlock-system": YES,
        "org.freedesktop.udisks2.eject-media-other-seat": YES,
        "org.freedesktop.udisks2.power-off-drive-other-seat": YES
      };
      if (subject.isInGroup("wheel")) {
        return permission[action.id];
      }
    });
  '';
  security.sudo.extraRules = optional (hostname == "beelink-ser5") {
    users = [ "node-red" ];
    commands = [
      {
        command = "ALL";
        options = [ "NOPASSWD" ] ++ config.security.sudo.defaultOptions;
      }
    ];
  };
  services.udisks2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = hostname != "asus-x421da";
  services.tlp = optionalAttrs (hostname == "asus-x421da") {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_BAT = "conservative";
      CPU_BOOST_ON_AC = "1";
      CPU_BOOST_ON_BAT = "0";
    };
  };
  services.gnome.at-spi2-core.enable = mkForce false;
  services.gnome.gnome-keyring.enable = mkForce false;
  services.gvfs.enable = hostname == "asus-x421da" || hostname == "ms-7c94";
  services.gvfs.package = pkgs.gvfs;
  services.flatpak.enable = hostname == "asus-x421da" || hostname == "ms-7c94";

  services.dbus.implementation = "broker";
  services.dbus.packages = with pkgs; optionals (hostname == "asus-x421da" || hostname == "ms-7c94") [
    dconf
  ];

  services.printing.enable = true;
  services.printing.startWhenNeeded = hostname == "asus-x421da" || hostname == "ms-7c94";
  services.printing.listenAddresses = optional (hostname == "beelink-ser5") "*:631";
  services.printing.defaultShared = hostname == "beelink-ser5";
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
    server min protocol = NT1
    client min protocol = NT1
    ntlm auth = yes
    map to guest = bad user
    guest account = ilya
  '' + optionalString (hostname == "asus-x421da" || hostname == "ms-7c94") ''
    usershare path = /var/lib/samba/usershares
    usershare max shares = 100
    usershare allow guests = yes
    usershare owner only = yes
  '' + optionalString (hostname == "beelink-ser5") ''
    [media]
    path = /media
    available = yes
    browsable = yes
    public = yes
    writable = yes
    create mask = 0777
    directory mask = 0777

  [videos]
    path = /home/ilya/videos
    available = yes
    browsable = yes
    public = yes
    writable = yes
    create mask = 0777
    directory mask = 0777

  [PS2]
    path = /home/ilya/PS2
    available = yes
    browsable = yes
    public = yes
    writable = yes
    create mask = 0777
    directory mask = 0777
  '';

  services.nfs.server.enable = hostname == "beelink-ser5";
  services.nfs.server.exports = optionalString (hostname == "beelink-ser5") ''
    /srv/nfs     *(rw,sync,crossmnt,fsid=0)
    /srv/nfs/media *(rw,sync,all_squash,insecure,anonuid=1000,anongid=1000)
    /srv/nfs/videos *(rw,sync,all_squash,insecure,anonuid=1000,anongid=1000)
  '';

  services.rpcbind.enable = hostname == "beelink-ser5";
  services.plex.enable = hostname == "beelink-ser5";
  services.node-red.enable = hostname == "beelink-ser5";

  xdg = optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    portal.enable = true;
    portal.extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-kde
    ];
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = hostname == "beelink-ser5";
  virtualisation.lxc.enable = hostname == "ms-7c94";
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.virtualbox.host.enable = (hostname == "asus-x421da" || hostname == "ms-7c94");
  virtualisation.virtualbox.host.enableKvm = true;
  virtualisation.virtualbox.host.addNetworkInterface = false;
  virtualisation.virtualbox.host.enableHardening = false;

  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
    qemu.package = pkgs.qemu_kvm;
    qemu.ovmf.packages = [
      (pkgs.OVMF.override {
        secureBoot = true;
        tpmSupport = true;
      }).fd
    ];
  } // optionalAttrs (hostname == "ms-7c94") {
    hooks.qemu.win10 = pkgs.writeShellScript "win10" ''
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
  } // optionalAttrs (hostname == "beelink-ser5") {
    hooks.qemu.LibreELEC = pkgs.writeShellScript "LibreELEC" ''
      if [ "$1" != "LibreELEC" ]; then
        exit
      fi

      case $2 in
        prepare)
          modprobe -r amdgpu
          ;;
        release)
          modprobe amdgpu
          systemctl restart systemd-vconsole-setup
          ;;
        esac
    '';
  };

  hardware.alsa.enablePersistence = hostname == "ms-7c94";
  security.rtkit.enable = hostname == "asus-x421da" || hostname == "ms-7c94";
  services.pipewire = optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  } // optionalAttrs (hostname == "ms-7c94") {
    wireplumber.configPackages = singleton (pkgs.writeTextDir "share/wireplumber/main.lua.d/51-alsa-custom.lua" ''
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
    '');
  };

  services.libinput = optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    enable = true;
  };

  services.xserver = optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    enable = true;
    xkb.layout = "us,ru";
    xkb.options = "grp:win_space_toggle";
    videoDrivers = [ "modesetting" ];
  };

  services.displayManager = optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    sddm.enable = true;
    sddm.wayland.enable = true;
    autoLogin.enable = true;
    autoLogin.user = "ilya";
    defaultSession = "plasma";
  };

  services.desktopManager.plasma6 = optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    enable = true;
  };

  fonts = optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    packages = with pkgs; [
      nur.repos.ilya-fedin.exo2
      nur.repos.ilya-fedin.cascadia-code-powerline
      unifont
      symbola
      joypixels
      nur.repos.ilya-fedin.nerd-fonts-symbols
    ];

    enableDefaultPackages = false;

    fontconfig.crOSMaps = true;
    fontconfig.defaultFonts.sansSerif = [ "Exo 2" "Symbols Nerd Font" ];
    fontconfig.defaultFonts.serif = [ "Tinos" "Symbols Nerd Font" ];
    fontconfig.defaultFonts.monospace = [ "Cascadia Code PL" "Symbols Nerd Font" ];
    fontconfig.defaultFonts.emoji = [ "JoyPixels" ];
  };

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
      "libvirtd"
      "vboxusers"
      "adbusers"
      "sambashare"
    ];
    uid = 1000;
    isNormalUser = true;
  };

  users.groups = optionalAttrs (hostname == "asus-x421da" || hostname == "ms-7c94") {
    sambashare = {};
  };

  system.stateVersion = "24.05";
}
