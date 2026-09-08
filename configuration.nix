{ config, pkgs, lib, inputs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "a637bea8";
  boot.zfs.extraPools = [ "tank" ];
  services.zfs.autoScrub.enable = true;
  
  # Hostname and time
  networking.hostName = "server";
  time.timeZone = "Europe/Zurich";

  users.users.julien = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Flake
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Claude
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "claude" ];

  environment.systemPackages = with pkgs; [ git vim htop ]
    ++ [ inputs.claude-code.packages.${pkgs.system}.default ];


  system.stateVersion = "26.05";
}
