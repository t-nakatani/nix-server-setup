{
  pkgs,
  commonModules,
  system,
}:
let
  image = pkgs.dockerTools.buildImage {
    name = "server-test";
    tag = "local";
    copyToRoot = pkgs.buildEnv {
      name = "test-http-root";
      paths = [
        pkgs.busybox
        (pkgs.writeTextDir "www/index.html" "nixos-server-ok")
      ];
      pathsToLink = [
        "/bin"
        "/www"
      ];
    };
    config.Cmd = [
      "/bin/httpd"
      "-f"
      "-p"
      "8080"
      "-h"
      "/www"
    ];
  };
in
pkgs.testers.runNixOSTest {
  name = "server-setup";
  node.specialArgs.settings = import ./settings.nix { inherit system; };
  nodes = {
    server = { ... }: {
      imports = commonModules;
      virtualisation.memorySize = 2048;
      virtualisation.diskSize = 4096;
      networking.interfaces.eth1.ipv6.addresses = [
        {
          address = "fd00:1::1";
          prefixLength = 64;
        }
      ];
    };
    client = { ... }: {
      environment.systemPackages = [
        pkgs.openssh
        pkgs.curl
        pkgs.netcat-openbsd
      ];
      networking.interfaces.eth1.ipv6.addresses = [
        {
          address = "fd00:1::2";
          prefixLength = 64;
        }
      ];
    };
  };
  testScript = ''
    import shlex
    import time

    start_all()
    server.wait_for_unit("multi-user.target")
    server.wait_for_unit("sshd.service")
    server.wait_for_unit("docker.service")
    server.wait_for_unit("fail2ban.service")
    server.wait_for_unit("home-manager-testadmin.service")
    client.wait_for_unit("multi-user.target")
    server.wait_for_open_port(53122)
    client.wait_until_succeeds("nc -z -w 2 test-server 53122", timeout=60)
    client.wait_until_succeeds("nc -z -w 2 fd00:1::1 53122", timeout=60)

    with subtest("keys-only SSH, targeted sudo and shell tools"):
        client.succeed("ssh-keygen -q -t ed25519 -N \"\" -f /root/testkey")
        pub = client.succeed("cat /root/testkey.pub").strip()
        server.succeed("install -d -m 700 -o testadmin -g users /home/testadmin/.ssh")
        server.succeed("printf '%s\\n' " + shlex.quote(pub) + " > /home/testadmin/.ssh/authorized_keys")
        server.succeed("chown testadmin:users /home/testadmin/.ssh/authorized_keys; chmod 600 /home/testadmin/.ssh/authorized_keys")
        ssh = "ssh -4 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=5 -i /root/testkey -p 53122 "
        client.succeed(ssh + "testadmin@test-server 'sudo -n true && docker info && docker compose version && uv --version'")
        client.fail(ssh + "root@test-server true")
        client.fail("nc -z -w 2 test-server 22")
        client.succeed(ssh.replace("ssh -4", "ssh -6") + "testadmin@fd00:1::1 true")
        server.succeed("sshd -T -f /etc/ssh/sshd_config | grep -Fx 'passwordauthentication no'")
        server.succeed("sshd -T -f /etc/ssh/sshd_config | grep -Fx 'kbdinteractiveauthentication no'")
        server.succeed("sshd -T -f /etc/ssh/sshd_config | grep -Fx 'permitrootlogin no'")
        server.succeed("su - testadmin -c \"zsh -ic 'whence -w peco-history-selection && bindkey ^R && whence -w _git'\"")
        server.succeed("test $(readlink /etc/localtime) = $(readlink -f /etc/zoneinfo/Asia/Tokyo) || date +%Z | grep JST")

    with subtest("Docker publication remains inaccessible from outside"):
        server.succeed("docker load < ${image}")
        server.succeed("docker run -d --name web -p 0.0.0.0:18080:8080 -p '[::]:18080:8080' server-test:local")
        server.wait_until_succeeds("curl --fail http://127.0.0.1:18080 | grep nixos-server-ok")
        client.fail("curl --noproxy '*' --connect-timeout 2 --max-time 3 --fail http://test-server:18080")
        client.fail("curl --noproxy '*' --connect-timeout 2 --max-time 3 --fail 'http://[fd00:1::1]:18080'")
        # A firewall reload must not remove the extra forwarding guard.
        server.succeed("systemctl restart firewall.service")
        client.fail("curl --noproxy '*' --connect-timeout 2 --max-time 3 --fail http://test-server:18080")

    with subtest("fail2ban reads actual SSH failures and enforces a ban"):
        server.wait_until_succeeds("fail2ban-client status sshd")
        assert server.succeed("fail2ban-client get sshd maxretry").strip() == "5"
        assert server.succeed("fail2ban-client get sshd bantime").strip() == "3600"
        assert server.succeed("fail2ban-client get sshd findtime").strip() == "600"
        for _ in range(6):
            # Let OpenSSH's short per-source penalty expire so fail2ban sees each failure.
            time.sleep(6)
            client.execute(ssh + "does-not-exist@test-server true")
        server.wait_until_succeeds("fail2ban-client status sshd | grep -E 'Currently banned:[[:space:]]+[1-9]'")
        client.fail(ssh + "testadmin@test-server true")
  '';
}
