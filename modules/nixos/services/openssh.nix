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
}
