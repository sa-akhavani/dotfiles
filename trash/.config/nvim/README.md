### Prerequisites
- Install nodejs (to support typescript language server)
- Install FiraCode Nerd Font and enable it in terminal! I went with the Retina option
```bash
sudo apt install nodejs

sudo apt install unzip
cd /tmp
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
unzip FiraCode.zip -d FiraCode
mkdir ~/.local/share/fonts/
mv /tmp/FiraCode/FiraCodeNerdFont-Retina.ttf ~/.local/share/fonts/
fc-cache -f -v # clear and regenerate font cache
fc-list | grep "FiraCode" # confirming installation
rm -r /tmp/FiraCode*
```

### Install
```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz

# Put this in .zshrc or .bashrc
export PATH="$PATH:/opt/nvim-linux64/bin"
```

### Configuration
Clone this repository in `~/.config`. Finally you should have all the config files in the `~/.config/nvim/` directory


### Learning Material
#### Comprehensive
- Learn-Vim
    - https://github.com/iggredible/Learn-Vim/
- Another learn-vim
    - https://github.com/dofy/learn-vim/tree/master/en
#### Videos!
- Derek Wyatt Videos
    - http://derekwyatt.org/vim/tutorials/
#### Blogs
- Learn Progressively
    - https://yannesposito.com/Scratch/en/blog/Learn-Vim-Progressively/
#### Interactive Guides
- https://www.openvim.com/
- https://vimgenius.com/

#### Lua
- Use lua to configure neovim
    - https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/

### Comment
The comment plugin makes it easy to comment lines
use `gcc` to comment one line
use gc+<number>j to comment or uncomment the next j lines



### LSP 


### Code Completion
#### nvim-cmp
used for code completion

##### lspkind-nvim
used for vscode like icons in completion menu

