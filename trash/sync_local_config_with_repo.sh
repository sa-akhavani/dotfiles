# This script with sync the local config with the repo
# Tmux
cp ~/.tmux.conf.local ./
# ZSH
cp ~/.zshrc ./
cp -r ~/.oh-my-zsh/custom/themes ./.oh-my-zsh/
cp -r ~/.oh-my-zsh/custom/*.zsh ./.oh-my-zsh/
# WezTerm Config
cp ~/.wezterm.lua ./

