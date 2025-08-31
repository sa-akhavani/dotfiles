{ config, pkgs, pkgs-unstable, lib, inputs, ... }:

{
	imports =
	[
		./networkmanager.nix
	];

	networking.firewall = {
		enable = false;
	};

	networking.proxy = {
		# default = "http://user:password@proxy:port/";
		# noProxy = "127.0.0.1,localhost,internal.domain";
	};

}

