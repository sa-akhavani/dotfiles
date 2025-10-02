{ config, pkgs, lib, ... }:

{
	services.openssh = {
		enable = true;
		ports = [ 22 ];
		settings = {
			PasswordAuthentication = true; # Todo change this to false
			AllowUsers = [ "ali" ];
			PermitRootLogin = "no";
		};
	};
	services.fail2ban.enable = true;		# Base security for ssh
}
