####
# Copy Configurations
####
# Backup current configs
cp ~/.zshrc ~/.zshrc.backup
cp ~/.wezterm.lua ~/.wezterm.lua.backup
cp ~/.tmux.conf ~/.tmux.conf.backup
# Copy New Configs
cp .zshrc ~/
cp .wezterm.lua ~/
cp .tmux.conf.local ~/
cp -r .oh-my-zsh/custom/* ~/.oh-my-zsh/custom/

