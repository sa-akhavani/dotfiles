{ config, pkgs, ... }:

{
  # sound.enable = true;
  # hardware.pulseaudio.enable = false;

  security.rtkit.enable = true;		# (optional, recommended) allows Pipewire to use the realtime scheduler for increased performance.
  services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
		jack.enable = true;
#		wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pamixer				# Pulseaudio command line mixer
    pavucontrol				# PulseAudio Volume Control
  ];
}
