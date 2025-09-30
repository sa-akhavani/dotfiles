{ pkgs, ... }:
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
      update = "sudo nixos-rebuild switch --flake /home/ali/dotfiles";
    };

    history = {
      size = 50000;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
      ];
      theme = "wedisagree";
      # theme = "robbyrussell";
    };
  };
}
