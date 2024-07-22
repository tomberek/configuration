# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{

  services.postgresql.enable = true;
  services.postgresql.authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';

  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./tinc.nix
#(import (fetchTarball "https://github.com/flox/nixos-module/archive/tng.tar.gz"))

    ];

  # Specific needs for Framework
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  console.earlySetup = true;
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  hardware.enableRedistributableFirmware = true;
  services.fprintd.enable = false;

  # ZFS related
  boot.loader.grub.copyKernels.enable = true;
  boot.kernelParams = [ "nohibernate" 
    "i915.enable_fbc=1"
      "i915.enable_guc=2"
      "i915.modeset=1"
      # "video=eDP-1:1920x1200@60"
     "systemd.gpt_auto=0"
  ];

  networking.nameservers = [ "9.9.9.9"];
  networking = {
    # {{{
    #resolvconf.extraConfig = ''
    # PEERDNS=no
    #'';
    hostName = "tframe"; # Define your hostname.
    hostId = "f7a33074";
    networkmanager.enable = true;
    networkmanager.insertNameservers = ["9.9.9.9"];
    networkmanager.appendNameservers = ["9.9.9.9"];
    networkmanager.connectionConfig = {
         powersave = 2;
    };
    useDHCP = false;
    interfaces.wlp170s0.useDHCP = true;
    #interfaces.enp0s20f0u6u3u1.useDHCP = true;
    enableIPv6 = true;
    #interfaces.enp0s20f0u6u3u1.enableIPv6 = false;
    #interfaces.wlp170s0.enableIPv6 = false;
    firewall.allowedTCPPorts = [ 22 2086 5353 80 443 ];
    firewall.allowedUDPPorts = [ 5353 2086 6666 7777 ];
    # firewall.extraCommands = ''
        # iptables -w -t nat -A POSTROUTING -s 11.233.1.2/32 -o wlp170s0 -j MASQUERADE
    # '';
    hosts = {
      "10.233.1.2" = [
        "builds.sr.ht.local"
        "git.sr.ht.local"
        "meta.sr.ht.local"
        "lists.sr.ht.local"
        "man.sr.ht.local"
        "hub.sr.ht.local"
        "logs.sr.ht.local"
        "sr.ht.local"
      ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "wlp170s0";
    };
    networkmanager.unmanaged = [ "interface-name:ve-*" ];

  }; # }}}

  services.guix.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    virtualHosts = {
      "tomberek.info" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://localhost:8080/";
        };
        locations."/api" = {
          proxyPass = "http://localhost:8081";
        };
      };
    };
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "tomberek+letsencrypt@gmail.com";
  environment.stub-ld.enable = false;
  programs.hyprland.enable = true;

  nix = {
    # {{{
    # package = (builtins.getFlake "github:NixOS/nix/daa14b89103b1246e8d7297ffe8ac5b4f4c8c45c").packages.x86_64-linux.nix;
    package = pkgs.nixVersions.latest;
    settings = {
      trusted-users = [ "root" "tom" ];
       extra-trusted-substituters = ["https://cache.floxdev.com"];
       extra-trusted-public-keys = ["flox-store-public-0:8c/B+kjIaQ+BloCmNkRUKwaVPFWkriSAd0JJvuDu4F0="];
       extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
      system-features = [ "benchmark" "recursive-nix" "kvm" "nixos-test" "big-parallel" "ca-derivations" "gccarch-ivybridge"];
    };
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations impure-derivations 
      netrc-file = /etc/nix/netrc
      allowed-impure-host-deps = /nix/var/flox-cache /nix/var/cache /usr/bin/env
      connect-timeout = 10
      builders-use-substitutes = true
      log-lines = 30
      builders = @/etc/nix/machines
    '';
  }; # }}}

  nixpkgs.config.allowUnfree = true;

  programs.fuse.userAllowOther = true;
  programs.sway = {
    # {{{
    enable = true;
    wrapperFeatures = {
      gtk = true;
      base = true;
    };
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      mako
      alacritty
      dmenu
      konsole
      i3status-rust
      light
      brightnessctl
      xorg.xhost
      xorg.xauth
      xorg.xinit
      xwayland
      waybar
      slurp
      wf-recorder
      mate.caja
      grim
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    extraSessionCommands =
      ''
        export SDL_VIDEODRIVER=wayland
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export _JAVA_AWT_WM_NONREPARENTING=1
        export SUDO_ASKPASS="${pkgs.ksshaskpass}/bin/ksshaskpass"
        export SSH_ASKPASS="${pkgs.ksshaskpass}/bin/ksshaskpass"
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=sway
      '';
  }; # }}}

  # ssh {{{
  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh = {
    enable = true;
  }; # }}}

  services.displayManager.sddm.enable = true;
  services.xserver = {
    # {{{
    enable = true;
    # videoDrivers = lib.mkForce [ "intel" ];
    #desktopManager.plasma5.enable = true;
    autorun = false;
    # Enable touchpad support (enabled default in most desktopManager). }}}
  };
  services.libinput.enable = true;
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
    autoSnapshot.weekly = 2;
    autoSnapshot.daily = 2;
    autoSnapshot.hourly = 2;
    autoSnapshot.frequent = 2;
    autoSnapshot.flags = "-k -p --utc";
    #requestEncryptionCredentials = false;
  };
  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];
  services.avahi.enable = true;
  services.avahi.ipv6 = false;
  services.avahi.publish.addresses = true;
  services.avahi.publish.userServices = true;
  services.avahi.publish.enable = true;
  services.avahi.nssmdns4 = true;
  services.pcscd.enable = true;
  security.polkit.enable = true;
  # }}}

  services.udev.packages = [
    pkgs.libu2f-host
    pkgs.yubikey-personalization
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  #virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "overlay2";
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;

  # Enable sound.
  sound.enable = true;
  # services.acpid = {
  #   enable = true;
  #   handlers.mic = {
  #     event = "jack/headphone HEADPHONE plug";
  #     action = "${pkgs.alsa-utils}/bin/alsactl --file /etc/asound.state restore";
  #     
  #   };
  # };

  boot.supportedFilesystems = [ "ntfs"];
  #boot.extraModprobeConfig = ''
  #  options snd slots=snd-hda-intel
  #'';
  #hardware.pulseaudio.enable = true;
  #hardware.pulseaudio.support32Bit = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.General.InitiallyPowered = "true";

  users.users.tom = {
    isNormalUser = true;
    extraGroups = [ "input" "users" "tom" "wheel" "audio" "video" "libvirtd" "docker" "vboxusers" ]; # Enable ‘sudo’ for the user.
    group = "tom";
  };
  users.groups.tom = {};
  programs.ccache.enable = true;
  # programs.ccache.packageNames = [ "nix" "lowdown" ];

  security.polkit.debug = true;
  security.polkit.extraConfig = ''
      polkit.log("XYZ");
      polkit.addRule(function(action, subject) {
        polkit.log("XYZ-2");
        polkit.log("action=" + action);
        if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
          subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
  '';

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    jq
    waybar
    clipse
    kitty
    xwaylandvideobridge
    hyprpaper
    wofi

    pcscliteWithPolkit.out
    qt5.qtwayland
alsa-utils
(pkgs.writeScriptBin "xdg-fix.sh" ''
    #!${pkgs.bash}/bin/sh
    ${pkgs.systemd}/bin/systemctl --user stop xdg-desktop-portal
    ${pkgs.procps}/bin/pkill xdg-desktop-portal
    ${pkgs.procps}/bin/pkill xdg-desktop-portal-gtk
    ${pkgs.procps}/bin/pkill xdg-desktop-portal-wlr
    ${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal -v -r &
    ${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk --replace --verbose &
    ${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr -l DEBUG -o DP-2 &
  '')
    qpwgraph
haruna
mplayer

    wget
    vim
    curl
    tmux
    git
    google-chrome
    entr
    parallel
    file
    nix-index
    nix-top
    nix-diff
    nixpkgs-fmt
    nixpkgs-review
    nload
    nmap
    openssl
    powertop
    rlwrap
    timewarrior
    taskwarrior
    universal-ctags
    tree
  ];
  environment.profiles = [ "$HOME/.nix-profile-new" ];

  fonts = {
    # {{{
    fontconfig.enable = true;
    enableDefaultPackages = true;
    fontDir.enable = true;
    packages = with pkgs; [
      recursive
      noto-fonts
      font-awesome
      powerline-fonts
      comic-relief
      # iosevka
      # (iosevka-bin.override({variant="sgr-iosevka-fixed";}))
      # (iosevka-bin.override({variant="sgr-iosevka-term";}))
    ];
  }; # }}}

  system.stateVersion = "21.11"; # Did you read the comment?

hardware.graphics.enable = true;
# hardware.graphics.driSupport = true;
# hardware.graphics.driSupport32Bit = true;
hardware.graphics.extraPackages = with pkgs; [ intel-ocl intel-media-driver intel-vaapi-driver intel-compute-runtime];
hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [  intel-media-driver intel-vaapi-driver ];
services.fwupd.enable = true;

# rtkit is optional but recommended
security.rtkit.enable = true;
systemd.services.pipewire.path = [ pkgs.libcamera];
services.pipewire = {
  systemWide = false;
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
  alsa.support32Bit = true;
  socketActivation = true;
  jack.enable = true;
  # media-session.enable = false;
  wireplumber.enable = true;
  # config.pipewire = {
  #   "context.properties" = {
  #     "link.max-buffers" = 64;
  #     #"link.max-buffers" = 16; # version < 3 clients can't handle more than this
  #     "log.level" = 4; # https://docs.pipewire.org/#Logging
  #     #"default.clock.rate" = 48000;
  #     #"default.clock.quantum" = 1024;
  #     #"default.clock.min-quantum" = 32;
  #     #"default.clock.max-quantum" = 8192;
  #   };
  # };
};

xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
        # gtkUsePortal = true; # deprecated
      };

  programs.extra-container.enable = false;
  boot.extraSystemdUnitPaths = [ "/etc/systemd-mutable/system" ];
  services.gnunet.enable = false;
}
