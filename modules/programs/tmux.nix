{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    shortcut = "a";
    baseIndex = 1;
    # newSession = false;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    secureSocket = false;
    mouse = true;
    clock24 = true;
    historyLimit = 1000000;

    plugins = [
      pkgs.tmuxPlugins.better-mouse-mode
      pkgs.tmuxPlugins.sensible
      pkgs.tmuxPlugins.pain-control
      pkgs.tmuxPlugins.resurrect
    ];

    extraConfig = ''
      set -g default-terminal "xterm-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"

      # easy-to-remember split pane commands
      # bind | split-window -h -c "#{pane_current_path}"
      # bind - split-window -v -c "#{pane_current_path}"
      # bind c new-window -c "#{pane_current_path}"

      # Use vim keybindings in copy mode
      set-window-option -g mode-keys vi

      # v in copy mode starts making selection
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Change border color of active pane to yellow
      set -g pane-active-border-style "fg=yellow"

      # Status bar customizations
      set -g status-style "bg=#005f00"
      set-option -g status-position top
    '';
  };
}
