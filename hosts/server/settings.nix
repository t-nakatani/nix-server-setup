{
  # Enable only after setting your real public key and generating hardware configuration.
  enable = false;
  hostName = "server";
  system = "x86_64-linux"; # or aarch64-linux; this is the SERVER's CPU, not your laptop's.
  username = "admin";
  sshPublicKeys = [ ]; # e.g. "ssh-ed25519 AAAA... laptop"; never put a private key here.

  # Compatibility baselines, NOT package version selectors. Keep on normal updates.
  stateVersion = "26.05";
  homeStateVersion = "26.05";

  gitName = "";
  gitEmail = "";

  # Set after the host is deployed, Git is pushed, and root can fetch this repository.
  # Public: "github:t-nakatani/nix-server-setup/main#server"
  # Private: "git+ssh://git@github.com/t-nakatani/nix-server-setup?ref=main#server"
  # null disables automatic deployment; update the lock manually until enabled.
  upgradeFlake = null;
}
