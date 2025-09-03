{ config, lib, pkgs, pkgs-unstable, ... }:

{

	networking.networkmanager.enable = true;

	# Disable NetworkManager's internal DNS resolution
	# networking.networkmanager.dns = "none";

	# These options are unnecessary when managing DNS ourselves
	# networking.useDHCP = false;
	# networking.dhcpcd.enable = false;

	# Configure DNS servers manually (this example uses Cloudflare and Google DNS)
	# IPv6 DNS servers can be used here as well.
	networking.nameservers = [
	  "1.1.1.1"
	  "1.0.0.1"
	  "8.8.8.8"
	  "8.8.4.4"
	];

}
