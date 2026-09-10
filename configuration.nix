{ config, pkgs, lib, inputs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Storage (btrfs)
  boot.supportedFilesystems.btrfs = true;

  fileSystems."/data" = {
    device = "/dev/disk/by-label/tank";
    fsType = "btrfs";
    options = [ "subvol=data" "compress=zstd" "noatime" ];
  };

  fileSystems."/workspace" = {
    device = "/dev/disk/by-label/tank";
    fsType = "btrfs";
    options = [ "subvol=workspace" "compress=zstd" "noatime" ];
  };

  # Scrub monthly. Only /data is listed: both mounts are the same filesystem,
  # and scrub works per filesystem, not per subvolume.
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/data" ];
  };
  
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
