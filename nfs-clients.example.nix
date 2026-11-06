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
# A client mounting over Tailscale arrives from its 100.x tailnet address, not
# its LAN one, so list that too (`tailscale ip -4` on the client shows it).
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
      "100.101.102.103" # some-client, over Tailscale
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
