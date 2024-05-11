update_package_manager
echo
install_package curl
echo
install_package gpg
echo
install_package ssh
echo
install_package tmux
echo
install_package vim
echo
install_package git
echo
install_package python3
echo
install_package python3-pip
echo
install_package python3-venv
echo
install_package tree || true
echo
install_package neofetch || true
echo
install_package figlet || true
echo
install_package unicode || true
if [ "$IM_IN_WSL" = 'true' ]; then
    echo
    install_package wslu
fi

echo
deploy_file "$REPO_PATH/dotfiles/inputrc" ~/.inputrc
echo
move_over_file ~/.bashrc ~/.bashrc_default
deploy_file "$REPO_PATH/dotfiles/bashrc" ~/.bashrc
echo
deploy_file "$REPO_PATH/dotfiles/ssh/config" ~/.ssh/config
echo
deploy_file "$REPO_PATH/dotfiles/tmux.conf" ~/.tmux.conf
echo
deploy_file "$REPO_PATH/dotfiles/vimrc" ~/.vimrc
echo
deploy_file "$REPO_PATH/dotfiles/gitconfig" ~/.gitconfig
echo "Ensuring git config files included in \"~/.gitconfig\" exist (\"~/.gitconfig-private/root\")"
mkdir -p ~/.gitconfig-private
touch ~/.gitconfig-private/root

echo
echo "Creating folder ~/.path, which bashrc will append to \$PATH"
mkdir -p ~/.path

if [ "$IM_IN_WSL" = 'true' ]; then
    echo
    export MY_WINDOWS_HOME_FOLDER=$(wslpath "$(wslvar 'UserProfile')")
    set_symlink "$MY_WINDOWS_HOME_FOLDER" ~/win
fi

echo
echo "Installing 'Oh My Posh!'"
mkdir -p ~/.oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.oh-my-posh -t ~/.oh-my-posh/themes/built-in
deploy_file "$REPO_PATH/dotfiles/oh-my-posh/themes" ~/.oh-my-posh/themes/custom
set_symlink custom/mo.omp.json ~/.oh-my-posh/themes/default.omp.json
set_symlink ~/.oh-my-posh/oh-my-posh ~/.path/oh-my-posh

echo
echo "Importing and signing GPG key for GitHub web-flow"
cat "$REPO_PATH/keys/web-flow.gpg" | gpg --import
gpg --sign-key BB952194 || echo "Failed to sign GitHub web-flow's GPG key"

echo
echo "Importing and signing personal GPG key"
cat "$REPO_PATH/keys/mo-kiani.gpg" | gpg --import
gpg --sign-key 78A6E78A || echo "Failed to sign personal GPG key"

echo
echo "Preparing vim"
echo "Creating folder structure under ~/.vim/"
mkdir -p ~/.vim/{swap,backup}
mkdir -p ~/.vim/pack/{colorschemes,plugins}/{start,opt}
if ! [ -d ~/.vim/pack/colorschemes/start/gruvbox ]; then
    echo "Installing vim colorscheme 'gruvbox'"
    git clone git@github.com:morhetz/gruvbox.git ~/.vim/pack/colorschemes/start/gruvbox
else
    echo "Vim colorscheme 'gruvbox' already installed"
fi
if ! [ -d ~/.vim/pack/plugins/start/vim-airline ]; then
    echo "Installing vim plugin 'vim-airline'"
    git clone git@github.com:vim-airline/vim-airline.git ~/.vim/pack/plugins/start/vim-airline
else
    echo "Vim plugin 'vim-airline' already installed"
fi

echo
prompt_choice CHOICE_NERD_FONT 'Are you using a Nerd Font?' yes no
if [ "$CHOICE_NERD_FONT" = 'yes' ]; then
    touch ~/.nerdfont_on
elif [ -e ~/.nerdfont_on ]; then
    rm ~/.nerdfont_on
fi
