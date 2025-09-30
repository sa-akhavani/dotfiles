{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    # shell = "${pkgs.bash}/bin/bash";
    shortcut = "a";
    # aggressiveResize = true; -- Disabled to be iTerm-friendly
    baseIndex = 1;
    # newSession = true;
    # Stop tmux+escape craziness.
    escapeTime = 0;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    # secureSocket = false;
    mouse = true;
    clock24 = true;
    historyLimit = 500000;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.sensible
      tmuxPlugins.resurrect
      tmuxPlugins.continuum
      tmuxPlugins.pain-control
      # tmuxPlugins.vim-tmux-navigator
    ];

    extraConfig = ''
      # https://old.reddit.com/r/tmux/comments/mesrci/tmux_2_doesnt_seem_to_use_256_colors/
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # easy-to-remember split pane commands
      # bind | split-window -h -c "#{pane_current_path}"
      # bind - split-window -v -c "#{pane_current_path}"
      # bind c new-window -c "#{pane_current_path}"

      # Tmux continuum enable
      set -g @continuum-restore 'on'
      # Continuum status in tmux status line
      set -g status-right 'Continuum status: #{continuum_status}'

      # Change border color of active pane to yellow
      set -g pane-active-border-style "fg=yellow"
      # set-option -g pane-active-border-style fg=red


    '';
  };
}
