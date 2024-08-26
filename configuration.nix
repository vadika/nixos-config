# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  myOverlay = import /home/vadikas/N/overlay.nix;

in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
#      ./i915-iov.nix
    ];

#    boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest.override {
#    structuredExtraConfig = with pkgs.lib.kernel; {
#      # Your kernel config options go here
#      DRM_I915_PXP = yes;
#      INTEL_MEI_PXP = freeform "m";
#      # Add more options as needed
#    };
#   });

  boot.kernelParams = [ "mitigations=off" "intel_iommu=on" "intel_iommu=on" "i915.enable_guc=3" "i915.max_vfs=7" ];


  boot.initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];


  # Enable networking
  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    # If using dhcpcd:
    dhcpcd.extraConfig = "nohook resolv.conf";
    # If using NetworkManager:
    networkmanager.enable = true;
    networkmanager.dns = "none";
    hostName = "woooster"; # Define your hostname.
  };

  virtualisation.libvirtd.enable = true;
  boot.kernelModules = [ "kvm-intel" ];

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

  # Enable the GNOME Desktop Environment.
  # Ensure gnome-settings-daemon udev rules are enabled.
  services.udev.packages = with pkgs; [
    gnome.gnome-settings-daemon
    yubikey-personalization
  ];
  services.pcscd.enable = true;
  
  services.gnome.gnome-keyring.enable = lib.mkForce false;

   environment.shellInit = ''
     gpg-connect-agent /bye
     export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
   '';


  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt          # for newer GPUs on NixOS >24.05 or unstable
    ];
  };


  services.xserver = {
    # Required for DE to launch.
    enable = true;
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
    };
    # Enable Desktop Environment.
    desktopManager.gnome.enable = true;
    excludePackages = with pkgs; [ xterm ];
  };


  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
    wireplumber.enable = true;
    wireplumber.extraConfig = {
       "main" = {
          "monitor" = {
             "libcamera" = "disabled";
          };
       };
     }; 
  };

  services.stubby = {
    enable = true;
    settings = pkgs.stubby.passthru.settingsExample // {
      upstream_recursive_servers = [{
        address_data = "1.1.1.1";
        tls_auth_name = "cloudflare-dns.com";
        tls_pubkey_pinset = [{
          digest = "sha256";
          value = "4pqQ+yl3lAtRvKdoCCUR8iDmA53I+cJ7orgBLiF08kQ=";
        }];
      }
        {
          address_data = "1.0.0.1";
          tls_auth_name = "cloudflare-dns.com";
          tls_pubkey_pinset = [{
            digest = "sha256";
            value = "4pqQ+yl3lAtRvKdoCCUR8iDmA53I+cJ7orgBLiF08kQ=";
          }];
        }];
    };
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.vadikas = {
    isNormalUser = true;
    description = "vadikas";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      gnome.gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.caffeine
      gnomeExtensions.dash-to-dock
      gnomeExtensions.just-perfection
      gnomeExtensions.window-title-is-back
      gnome.networkmanager-openvpn
      firefox
      telegram-desktop
      zapzap
      slack
      git
      sublime4
      sublime-merge
      nixpkgs-fmt
      mc
      virtualenv
      vagrant
      yubioath-flutter
      terminator
      devenv
      pinta
      onlyoffice-bin_latest
      vistafonts
    ];
  };


 environment.variables = {
  EDITOR = "vi";
  VISUAL = "vi";
 };

 environment.gnome.excludePackages = with pkgs.gnome; [
    baobab      # disk usage analyzer
    cheese      # photo booth
    eog         # image viewer
    epiphany    # web browser
    simple-scan # document scanner
    totem       # video player
    yelp        # help viewer
    file-roller # archive manager
    geary       # email client
    seahorse    # password manager

    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-screenshot
    gnome-weather
    gnome-disk-utility
    pkgs.gnome-connections
    
  ];



  # Install firefox.
  programs.firefox.enable = true;
 

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow broken/unsecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];


  nixpkgs.config.allowBroken = true;


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    htop
    ripgrep
    usbutils
    pciutils
    python3
    gnupg
    yubikey-personalization
    screen
    microcom
    bashdb
    psmisc
    pipx
    qemu_full 
  ];


   nixpkgs.overlays = [ myOverlay ];
 
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  
  # Enable ZeroTier
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ "17d709436ccd20b1" ];
  
  # Enable fwupdate
  services.fwupd.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.extra-platforms = config.boot.binfmt.emulatedSystems;

  nix.settings.trusted-users = [ "root" "vadikas" ];
  nix.settings.substituters = [
  "https://devenv.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
  "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];


}
