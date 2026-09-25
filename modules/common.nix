{
  config,
  lib,
  pkgs,
  settings,
  ...
}:
{
  assertions = [
    {
      assertion =
        settings.sshPublicKeys != [ ]
        && lib.all (
          key:
          builtins.match "ssh-ed25519 [A-Za-z0-9+/=]+( .*)?" key != null
          || builtins.match "ssh-rsa [A-Za-z0-9+/=]+( .*)?" key != null
          || builtins.match "ecdsa-sha2-nistp[0-9]+ [A-Za-z0-9+/=]+( .*)?" key != null
        ) settings.sshPublicKeys;
      message = "Set at least one SSH public key in settings.nix; never deploy an empty key list.";
    }
    {
      assertion =
        settings.username != "root" && builtins.match "[a-z_][a-z0-9_-]*" settings.username != null;
      message = "settings.username must be a non-root Linux username.";
    }
  ];

  networking.hostName = settings.hostName;
  time.timeZone = "Asia/Tokyo";
  system.stateVersion = settings.stateVersion;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    unzip
    uv
    docker-compose
  ];
  programs.zsh.enable = true;
  users.mutableUsers = false;
  users.users.${settings.username} = {
    isNormalUser = true;
    createHome = true;
    home = "/home/${settings.username}";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "docker"
    ];
    # No password login; SSH public-key auth and targeted NOPASSWD sudo are used.
    hashedPassword = "!";
    openssh.authorizedKeys.keys = settings.sshPublicKeys;
  };
  security.sudo.extraRules = [
    {
      users = [ settings.username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.openssh = {
    enable = true;
    ports = [ 53122 ];
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PermitEmptyPasswords = false;
      PubkeyAuthentication = true;
      LogLevel = "VERBOSE";
    };
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = config.services.openssh.ports;
    allowedUDPPorts = [ ];
  };
  networking.nftables = {
    enable = true;
    # Docker's published ports travel through FORWARD, not the host INPUT rules.
    # Permit container egress/replies but drop new traffic forwarded from outside.
    # This is an endpoint server, not a VPN/router; standard Docker bridges only.
    tables.docker-ingress = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority -10; policy accept;
          ct state established,related accept
          iifname "docker0" accept
          iifname "br-*" accept
          counter drop
        }
      '';
    };
  };
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      # Default binding for docker0 and newly-created user-defined bridges.
      ip = "127.0.0.1";
      default-network-opts.bridge."com.docker.network.bridge.host_binding_ipv4" = "127.0.0.1";
    };
  };
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "3600";
    jails.sshd = {
      enabled = true;
      settings = {
        port = lib.concatMapStringsSep "," toString config.services.openssh.ports;
        backend = "systemd";
        findtime = 600;
      };
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit settings; };
    users.${settings.username} = import ../home/user.nix;
  };

  # Deploy only the Git-tracked lock; no on-server nix flake update.
  system.autoUpgrade = lib.mkIf (settings.upgradeFlake != null) {
    enable = true;
    flake = settings.upgradeFlake;
    upgrade = false;
    flags = [
      "--refresh"
      "--no-update-lock-file"
    ];
    dates = "04:40";
    randomizedDelaySec = "30m";
    allowReboot = false;
  };
  # Keep rollback generations. Deliberately no automatic GC until retention is chosen.
}
