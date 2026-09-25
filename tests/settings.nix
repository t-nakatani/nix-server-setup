{ system }:
{
  enable = true;
  inherit system;
  hostName = "test-server";
  username = "testadmin";
  # Public fixture only. Runtime integration generates a fresh client key.
  sshPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ5kHFnwGtDlQsIEzGeNzBJhxRpSXckFNErgDFpCoHKv fixture-only"
  ];
  stateVersion = "26.05";
  homeStateVersion = "26.05";
  gitName = "";
  gitEmail = "";
  upgradeFlake = null;
}
