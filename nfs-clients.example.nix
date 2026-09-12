# Example of the private NFS client list.
#
# The real file is NOT in this repo. It lives at
# ~/nixos-private/nfs-clients.nix and is read by absolute path, which is why
# rebuilds need --impure. Copy this file there and edit it:
#
#   mkdir -p ~/nixos-private
#   cp nfs-clients.example.nix ~/nixos-private/nfs-clients.nix
#
# Each list holds hosts, written as an IP address (192.168.1.50), a subnet
# (192.168.1.0/24), or a hostname the server can resolve back from the client's
# address. Plain addresses are the reliable choice on a home LAN.
#
#   rw  read and write. The client is mapped to julien (UID 1000) on the
#       server whatever user ID it sends, so macOS clients (UID 501) work.
#   ro  read only.
#
# A host may appear in one list per export. The most specific entry wins: a
# single host beats a subnet containing it, regardless of the order here.
#
# Apply changes with: sudo nixos-rebuild switch --flake .#server --impure
{
  # /data
  data = {
    rw = [
      "192.168.1.50" # some-client
    ];
    ro = [ ];
  };

  # /workspace
  workspace = {
    rw = [
      "192.168.1.50" # some-client
    ];
    ro = [
      "192.168.1.0/24" # rest of the LAN
    ];
  };
}
