{ settings, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Suitable for a UEFI installation with its EFI partition mounted at /boot.
  # For BIOS/cloud images, replace with the provider's required boot loader settings.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # For static addressing, configure the actual interface, gateway and DNS here.
  networking.useDHCP = true;

  assertions = [
    {
      assertion = settings.enable;
      message = "Configure hosts/server/settings.nix before enabling this host.";
    }
  ];
}
