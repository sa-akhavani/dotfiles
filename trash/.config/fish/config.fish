# Load Custom Alias File
source ~/.config/fish/alias.fish

function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    fastfetch -c ~/.config/fastfetch/config.jsonc
end

# Install Starship
starship init fish | source

