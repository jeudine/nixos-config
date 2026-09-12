{ config, pkgs, lib, inputs, ... }:
let
  # Who may mount what. The real list is kept out of this public repo: it lives
  # at ~/nixos-private/nfs-clients.nix and is read by absolute path, so every
  # rebuild needs --impure. See ./nfs-clients.example.nix for the format.
  nfsClients = import /home/julien/nixos-private/nfs-clients.nix;

  # Build one export's client list. fsid is required because /data and
  # /workspace are subvolumes of the same btrfs filesystem, so they share a
  # UUID and cannot otherwise be told apart; it identifies the export, and so
  # is the same for every client of that export. Read-write clients are
  # squashed to julien (UID 1000, group users) because a client's own user IDs
  # need not match the server's — macOS numbers its first user 501.
  nfsExport = fsid: clients:
    let
      base = [ "sync" "no_subtree_check" "fsid=${toString fsid}" ];
      entry = options: host: lib.nameValuePair host (options ++ base);
    in
    lib.listToAttrs (
      map (entry [ "rw" "all_squash" "anonuid=1000" "anongid=100" ]) (clients.rw or [ ])
      ++ map (entry [ "ro" ]) (clients.ro or [ ])
    );
in
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

  # NFS. The client lists live in ~/nixos-private/nfs-clients.nix (see above).
  #
  # v3 is served alongside v4 because the macOS client does not reliably
  # complete an NFSv4 handshake: it connects to 2049 and then hangs, and since
  # NFS mounts are hard by default that wedges the whole machine. v3 needs
  # rpcbind plus mountd, statd and lockd, whose ports are normally random, so
  # they are pinned here to keep the firewall rules exact.
  services.nfs.server = {
    enable = true;
    exports = {
      "/data" = nfsExport 1 nfsClients.data;
      "/workspace" = nfsExport 2 nfsClients.workspace;
    };
    mountdPort = 4002;
    statdPort = 4000;
    lockdPort = 4001;
  };

  networking.firewall = {
    # 111 rpcbind, 2049 nfsd, 4000 statd, 4001 lockd, 4002 mountd
    allowedTCPPorts = [ 111 2049 4000 4001 4002 ];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 ];
  };

  # Both mount points are root-owned after mkfs, which would leave the rw
  # exports unwritable: NFS maps a client's root to nobody by default.
  systemd.tmpfiles.rules = [
    "d /data 0755 julien users -"
    "d /workspace 0755 julien users -"
  ];

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
