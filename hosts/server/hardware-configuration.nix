# REPLACE this entire file with nixos-generate-config output from the target server.
# Never copy disk UUIDs from another machine or from a test fixture.
{ ... }:
{
  assertions = [
    {
      assertion = false;
      message = "Replace hosts/server/hardware-configuration.nix with the target server's generated file.";
    }
  ];
}
