{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false; # Todo change this to false
      AllowUsers = [ "ali" ];
      PermitRootLogin = "no";
    };
  };
  services.fail2ban.enable = true; # Base security for ssh
  programs.ssh = {
    startAgent = true; # Enable ssh-agent
    extraConfig = "
      Host nuc-alpha
        Hostname 192.168.1.162
        Port 22
        User ali
    ";
  };
}
