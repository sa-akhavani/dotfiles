{ config, lib, pkgs, pkgs-unstable, ... }:

{
	networking = {
		hostName = "rostam";	
	};

	  networking.networkmanager.enable = true;
}
