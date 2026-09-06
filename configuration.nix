{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
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

  environment.systemPackages = with pkgs; [ git vim htop ];

  system.stateVersion = "26.05";
}
