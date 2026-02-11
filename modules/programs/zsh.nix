{ pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "lsd";
      ll = "ls -l";
      t = "tmux";
      ta = "tmux attach";
      td = "tmux detach";
      update = "sudo nixos-rebuild switch --flake .";
    };

    history = {
      size = 100000;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
      ];
      theme = "wedisagree";
      # theme = "robbyrussell";
      # extraConfig = ''
      #   eval `keychain --eval id_ed25519`
      # '';
    };
  };

  programs.keychain = {
    enable = true;
    enableZshIntegration = true;
    keys = [ "/home/ali/.ssh/id_ed25519" ];
  };

}
