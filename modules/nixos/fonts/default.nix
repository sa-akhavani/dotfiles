{ config, lib, pkgs, ... }:

{
	# https://nixos.wiki/wiki/Fonts is really good!
	fonts = {
		enableDefaultPackages = true;
		packages = with pkgs; [
			noto-fonts
			noto-fonts-cjk-sans
			noto-fonts-color-emoji

			fira-code
			fira-code-symbols
			nerd-fonts.fira-code
			# nerdfonts # installing "all" nerfonts

			liberation_ttf

			# Persian Font
			vazir-fonts
		];
		
		fontconfig = {
			defaultFonts = {
				serif = [ "Noto Serif" "Liberation Serif" "Vazirmatn" ];
				sansSerif = [ "Noto" "Vazirmatn" ];
				monospace = [ "Noto Mono" ];
			};
		};
	};
}
