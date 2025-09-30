{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    # shell = "${pkgs.bash}/bin/bash";
    shortcut = "a";
    # aggressiveResize = true; -- Disabled to be iTerm-friendly
    baseIndex = 1;
    newSession = false;
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
      tmuxPlugins.pain-control
      # tmuxPlugins.vim-tmux-navigator
      # tmuxPlugins.continuum
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

      # Change border color of active pane to yellow
      set -g pane-active-border-style "fg=yellow"

      # Status bar customizations
      set -g status-style "bg=#005f00"
      set-option -g status-position top

      run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux

      # Tmux continuum enable
      run-shell ${pkgs.tmuxPlugins.continuum}
      set -g @continuum-restore 'on'

      set -g status-right 'Continuum: #{continuum_status} -- #{cpu_percentage}  %H:%M'
    '';
  };
}
