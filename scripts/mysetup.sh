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
install_package tree || true
echo
install_package neofetch || true
echo
install_package figlet || true
echo
install_package unicode || true

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
echo
deploy_file "$REPO_PATH/dotfiles/oh-my-posh/themes" ~/.oh-my-posh/themes/custom

echo
echo "Creating folder ~/.path, which bashrc will append to \$PATH"
mkdir -p ~/.path
