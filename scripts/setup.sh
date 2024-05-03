#!/bin/bash

set -e

# Require root/sudo permissions
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root/sudo permissions. Try: sudo !!"
    exit 1
fi

# Always run this script with the repo's physical path as its working directory
cd -P "$(dirname $(realpath "$0"))/.."
echo "Running from absolute physical path: $(pwd)"

export DISTRO_NAME='NOT YET SET'
if [ $(lsb_release -is) = 'Ubuntu' ]; then
    export DISTRO_NAME='ubuntu'
    echo 'Identified Linux distribution name as "Ubuntu"'
else
    echo "Could not identify Linux distribution."
    exit 2
fi

export PACKAGE_MANAGER='NOT YET SET'
if [ -f /etc/debian_version ]; then
    export PACKAGE_MANAGER='apt'
    echo 'Identified package manager as "apt"'
elif [ -f /etc/redhat-release ]; then
    export PACKAGE_MANAGER='yum'
    echo 'Identified package manager as "yum"'
elif [ -f /etc/arch-release ]; then
    export PACKAGE_MANAGER='pacman'
    echo 'Identified package manager as "pacman"'
elif [ -f /etc/alpine-release ]; then
    export PACKAGE_MANAGER='apk'
    echo 'Identified package manager as "apk"'
elif [ -f /etc/SuSE-release ]; then
    export PACKAGE_MANAGER='zypp'
    echo 'Identified package manager as "zypp"'
elif [ -f /etc/gentoo-release ]; then
    export PACKAGE_MANAGER='emerge'
    echo 'Identified package manager as "emerge"'
else
    echo "Could not identify package manager."
    exit 3
fi

update_package_manager () {
    echo "Updating/Upgrading \"$PACKAGE_MANAGER\""
    case $PACKAGE_MANAGER in
        'apt')
            sudo apt -qq update
            sudo apt -qq upgrade
            ;;
        *)
            echo "Update/Upgrade of package manager \"$PACKAGE_MANAGER\" not supported."
            return 4
            ;;
    esac
    return 0
}
install_package () {
    local package_name=$1
    echo
    case $PACKAGE_MANAGER in
        'apt')
            echo "Installing $package_name"
            sudo apt -qq install -y $package_name
            ;;
        *)
            echo "Package installation with package manager \"$PACKAGE_MANAGER\" not supported."
            return 5
            ;;
    esac
    return 0
}
install_packages () {
    local package_name
    for package_name in "$@"; do
        install_package $package_name
    done
    return 0
}

echo
update_package_manager
install_packages curl
install_packages gpg ssh tmux
install_packages vim git
install_packages tree neofetch figlet unicode || true
