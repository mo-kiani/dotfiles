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
install_package unzip || true
echo
install_package unicode || true
if [ "$IM_IN_WSL" = 'true' ]; then
    echo
    install_package wslu
fi

echo
echo "Creating folder ~/.path, which bashrc will append to \$PATH"
mkdir -p ~/.path

echo
deploy_item dotfiles/inputrc ~/.inputrc
echo
if [ "$IM_IN_WSL" = 'true' ]; then
    deploy_item dotfiles/gnupg/pinentry-wsl.sh ~/.path/pinentry-wsl.sh
    deploy_item dotfiles/gnupg/gpg-agent-wsl.conf ~/.gnupg/gpg-agent.conf
else
    deploy_item dotfiles/gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
fi
echo
move_over_item ~/.bashrc ~/.bashrc_default
deploy_item dotfiles/bashrc ~/.bashrc
echo
move_over_item ~/.bash_profile ~/.bash_profile_default
deploy_item dotfiles/bash_profile ~/.bash_profile
echo "Ensuring ~/.bashrc_extras exists. You can use it for additional system-specific configurations that will be sourced at the end of ~/.bashrc"
touch ~/.bashrc_extras
echo
deploy_item dotfiles/ssh/config ~/.ssh/config
echo
deploy_item dotfiles/tmux.conf ~/.tmux.conf
echo
deploy_item dotfiles/vimrc ~/.vimrc
echo
deploy_item dotfiles/gitconfig ~/.gitconfig
echo "Ensuring git config files included in \"~/.gitconfig\" exist (\"~/.gitconfig-private/root\")"
mkdir -p ~/.gitconfig-private
touch ~/.gitconfig-private/root

if [ "$IM_IN_WSL" = 'true' ]; then
    export MY_WINDOWS_HOME_FOLDER=$(wslpath "$(wslvar 'UserProfile')")
    export MY_WINDOWS_TERMINAL_FOLDER=$(wslpath "$(wslvar 'LocalAppData')")/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState
    export MY_WINDOWS_STARTUP_FOLDER=$(wslpath "$(wslvar 'AppData')")/Microsoft/Windows/Start\ Menu/Programs/Startup/
    echo
    set_symlink "$MY_WINDOWS_HOME_FOLDER" ~/win
    echo
    deploy_item_wsl dotfiles/wt/settings.json "$MY_WINDOWS_TERMINAL_FOLDER/settings.json"
    echo
    deploy_item_wsl "dotfiles/wt/Windows Terminal Quake Mode Minimized.lnk" "$MY_WINDOWS_STARTUP_FOLDER/Windows Terminal Quake Mode Minimized.lnk"
    echo
    deploy_item_wsl assets/Tux.png "$MY_WINDOWS_HOME_FOLDER/Setup/Tux.png"
    echo
    deploy_item_wsl dotfiles/gitconfig-windows "$MY_WINDOWS_HOME_FOLDER/.gitconfig"
fi

echo
echo "Installing 'Oh My Posh!'"
mkdir -p ~/.oh-my-posh
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.oh-my-posh -t ~/.oh-my-posh/themes/built-in
deploy_item dotfiles/oh-my-posh/themes ~/.oh-my-posh/themes/custom
set_symlink custom/mo.omp.json ~/.oh-my-posh/themes/default.omp.json
set_symlink ~/.oh-my-posh/oh-my-posh ~/.path/oh-my-posh

echo
echo "Importing and signing GPG key for GitHub web-flow"
cat keys/web-flow.gpg | gpg --import
gpg --sign-key BB952194 || echo "Failed to sign GitHub web-flow's GPG key"

echo
echo "Importing and signing personal GPG key"
cat keys/mo-kiani.gpg | gpg --import
gpg --sign-key 78A6E78A || echo "Failed to sign personal GPG key"

echo
echo "Preparing vim"
echo "Creating folder structure under ~/.vim/"
mkdir -p ~/.vim/{swap,backup}
mkdir -p ~/.vim/pack/{colorschemes,plugins}/{start,opt}
if ! [ -d ~/.vim/pack/colorschemes/start/gruvbox ]; then
    echo "Installing vim colorscheme 'gruvbox'"
    git clone https://github.com/morhetz/gruvbox.git ~/.vim/pack/colorschemes/start/gruvbox
else
    echo "Vim colorscheme 'gruvbox' already installed"
fi
if ! [ -d ~/.vim/pack/plugins/start/vim-airline ]; then
    echo "Installing vim plugin 'vim-airline'"
    git clone https://github.com/vim-airline/vim-airline.git ~/.vim/pack/plugins/start/vim-airline
else
    echo "Vim plugin 'vim-airline' already installed"
fi

echo
echo "Installing Node Version Manager (NVM)"
export NVM_DIR="$HOME/.nvm"
if ! [ -d "$NVM_DIR" ]; then
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
else
    echo "Directory at \"$NVM_DIR\" already exists. Assuming NVM was previously cloned"
fi
(
    echo "Checking out latest version of NVM"
    cd "$NVM_DIR"
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
)

echo
prompt_choice CHOICE_NERD_FONT 'Are you using a Nerd Font?' no yes
if [ "$CHOICE_NERD_FONT" = 'yes' ]; then
    touch ~/.nerdfont_on
elif [ -e ~/.nerdfont_on ]; then
    rm ~/.nerdfont_on
fi

echo
prompt_choice CHOICE_TMUX "Does your tmux config support tmux version [$(tmux -V)]?" no yes
if [ "$CHOICE_TMUX" = 'no' ]; then
    touch ~/.tmux.conf-unsupported
elif [ -e ~/.tmux.conf-unsupported ]; then
    rm ~/.tmux.conf-unsupported
fi
