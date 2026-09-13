# Creates symbolic links to the dotfiles repo from ~
mkdir -p ~/.config/
if [ ! -L ~/.config/nvim ]; then
    ln -s ~/dotfiles/nvim ~/.config/nvim
    echo "Created symbolic link from ~/.config/nvim to ~/dotfiles/nvim"
fi

# Install fnm for node
curl -fsSL https://fnm.vercel.app/install | bash

# if [ ! -d ~/.config/powerline ]; then
#     ln -s ~/dotfiles/powerline ~/.config/powerline
#     echo "Created symbolic link from ~/.config/powerline to ~/dotfiles/powerline"
# fi

# Set up oh-my-tmux
if [ ! -d ~/.tmux ]; then
    git clone https://github.com/gpakosz/.tmux ~/.tmux
    echo "Cloned oh-my-tmux to ~/.tmux"
fi
if [ ! -L ~/.tmux.conf ]; then
    ln -s ~/.tmux/.tmux.conf ~/.tmux.conf
    echo "Created symbolic link from ~/.tmux.conf to ~/.tmux/.tmux.conf"
fi
if [ ! -L ~/.tmux.conf.local ]; then
    ln -s ~/dotfiles/tmux.conf.local ~/.tmux.conf.local
    echo "Created symbolic link from ~/.tmux.conf.local to ~/dotfiles/tmux.conf.local"
fi

# Set up tmuxinator
mkdir -p ~/.config
if [ ! -d ~/.config/tmuxinator ]; then
    ln -s ~/dotfiles/tmuxinator ~/.config/tmuxinator
    echo "Created symbolic link from ~/.config/tmuxinator to ~/dotfiles/tmuxinator"
fi

# Set up herdr
mkdir -p ~/.config/herdr
if [ ! -e ~/.config/herdr/config.toml ]; then
    ln -s ~/dotfiles/herdr/config.toml ~/.config/herdr/config.toml
    echo "Created symbolic link from ~/.config/herdr/config.toml to ~/dotfiles/herdr/config.toml"
elif [ ! -L ~/.config/herdr/config.toml ]; then
    echo "Leaving existing ~/.config/herdr/config.toml unchanged"
fi

# The selector plugin is linked from this repo, but its ignored Rust build
# output can disappear after a fresh clone or cleanup. Rebuild and relink it so
# valid-looking prefix+j/k/l bindings never point at a missing executable.
herdr_select_dir="$HOME/dotfiles/herdr/plugins/select"
herdr_select_bin="$herdr_select_dir/target/release/herdr-select"
case "$(uname -s)" in
    Darwin|Linux)
        if ! command -v herdr >/dev/null 2>&1; then
            echo "Warning: herdr is not installed; skipping herdr-select setup"
        elif ! command -v cargo >/dev/null 2>&1; then
            echo "Warning: cargo is not installed; herdr selector bindings will not work"
        elif ! cargo build --release --locked --manifest-path "$herdr_select_dir/Cargo.toml"; then
            echo "Warning: failed to build herdr-select; selector bindings will not work"
        elif [ ! -x "$herdr_select_bin" ]; then
            echo "Warning: herdr-select build completed without creating $herdr_select_bin"
        elif ! herdr plugin link "$herdr_select_dir" --enabled >/dev/null; then
            echo "Warning: failed to link the dotfiles.select Herdr plugin"
        elif ! herdr config check; then
            echo "Warning: Herdr configuration validation failed"
        else
            if herdr status server >/dev/null 2>&1; then
                herdr server reload-config >/dev/null \
                    || echo "Warning: failed to reload the running Herdr server"
            fi
            echo "Built and linked herdr-select"
        fi
        ;;
    *)
        echo "Skipping herdr-select setup on unsupported platform $(uname -s)"
        ;;
esac

# Set up Ghostty
mkdir -p ~/.config/ghostty
touch ~/.config/ghostty/config
if test $(grep -c "config-file = ~/dotfiles/ghostty/config" ~/.config/ghostty/config) = 0; then
    echo "Adding dotfiles config to ~/.config/ghostty/config"
    echo "config-file = ~/dotfiles/ghostty/config" >> ~/.config/ghostty/config
fi

# Set up zsh
touch ~/.zshrc
if test $(grep -c "~/dotfiles/zsh/.zshrc" ~/.zshrc) = 0; then
    echo "Adding zshrc to ~/.zshrc"
    echo "source ~/dotfiles/zsh/.zshrc" >> ~/.zshrc
fi
if [ ! -L ~/.p10k.zsh ]; then
    ln -s ~/dotfiles/zsh/.p10k.zsh ~/.p10k.zsh
    echo "Created symbolic link from ~/.p10k.zsh to ~/dotfiles/zsh/.p10k.zsh"
fi

# Set up some includes
#touch ~/.vimrc
#if test $(grep -c "~/dotfiles/vimrc" ~/.vimrc) = 0; then
#    echo "Adding vimrc to ~/.vimrc"
#    echo "source ~/dotfiles/vimrc" >> ~/.vimrc
#fi

#touch ~/.bashrc
if test $(grep -c "~/dotfiles/bashrc" ~/.bashrc) = 0; then
    echo "Adding bashrc to ~/.bashrc"
    echo -e "if [ -f ~/dotfiles/bashrc ]; then\n    . ~/dotfiles/bashrc\nfi" >> ~/.bashrc
fi

touch ~/.gitconfig
if test $(grep -c "~/dotfiles/gitconfig" ~/.gitconfig) = 0; then
    echo "Adding gitconfig to ~/.gitconfig"
    git config --global include.path ~/dotfiles/gitconfig
fi
