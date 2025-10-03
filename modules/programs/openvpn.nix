{ pkgs, lib, ... }:
{
  services.openvpn.servers = {
    officeVPN = {
      config = ''config /home/ali/openvpn/basic.conf '';
      updateResolvConf = true;
    };
  };
}
