{
  description = "Small, reproducible NixOS servers with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs systems;
      # Add one entry per host. Unconfigured templates are deliberately excluded.
      hosts = {
        server = ./hosts/server;
      };
      activeHosts = lib.filterAttrs (_: path: (import (path + "/settings.nix")).enable) hosts;
      commonModules = [
        ./modules/common.nix
        home-manager.nixosModules.home-manager
      ];
      mkFixture =
        system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs.settings = import ./tests/settings.nix { inherit system; };
          modules = commonModules ++ [
            ({ modulesPath, ... }: {
              imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
              fileSystems."/" = {
                device = "/dev/vda";
                fsType = "ext4";
              };
              boot.loader.grub.enable = false;
            })
          ];
        };
    in
    {
      nixosConfigurations = lib.mapAttrs (
        _: path:
        let
          settings = import (path + "/settings.nix");
        in
        lib.nixosSystem {
          system = settings.system;
          specialArgs = { inherit settings; };
          modules = commonModules ++ [ (path + "/configuration.nix") ];
        }
      ) activeHosts;

      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellScriptBin "format" ''
          exec ${pkgs.nixfmt-tree}/bin/treefmt --tree-root . "$@"
        ''
      );
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fixture = mkFixture system;
        in
        {
          # Build the complete shared OS + Home Manager, even before a host is configured.
          system = fixture.config.system.build.toplevel;
          integration = import ./tests/server.nix { inherit pkgs commonModules system; };
        }
        // lib.mapAttrs' (name: host: lib.nameValuePair "host-${name}" host.config.system.build.toplevel) (
          lib.filterAttrs (_: host: host.pkgs.stdenv.hostPlatform.system == system) self.nixosConfigurations
        )
      );
    };
}
