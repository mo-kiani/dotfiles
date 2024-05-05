#!/bin/bash

set -e

# Ensure sudo permissions are granted by the invoking user before starting
sudo true

export REPO_PATH=$(realpath "$0")
export REPO_PATH=$(dirname "$REPO_PATH")
export REPO_PATH=$(dirname "$REPO_PATH")
export SETUP_DIR=~/.setup
export BACKUP_DIR="$SETUP_DIR"/backups/"$(date '+%Z_%Y-%m-%d_%H-%M-%S')"
export MOVE_OVER_FILES_PATH="$SETUP_DIR"/move_over_files

echo "Using home directory \"$HOME\""

# Always run this script with the repo's physical path as its working directory
echo "Running from absolute physical path \"$REPO_PATH\""
cd -P "$REPO_PATH"

echo "Storing related data in \"$SETUP_DIR\""
mkdir -p "$SETUP_DIR"

echo "Using \"$BACKUP_DIR\" as backup directory. If this script overwrites any files, try looking there."
if [ -e "$BACKUP_DIR" ]; then
    echo "\"$BACKUP_DIR\" already exists. It's unsafe to continue because existing backups might get deleted. Try again in a few seconds."
    exit 1
fi
mkdir -p "$BACKUP_DIR"

export MOVE_OVER_FILES_DIR=$(dirname "$MOVE_OVER_FILES_PATH")
mkdir -p "$MOVE_OVER_FILES_DIR"
touch "$MOVE_OVER_FILES_PATH"

export DISTRO_NAME='NOT YET SET'
if [ "$(lsb_release -is)" = 'Ubuntu' ]; then
    export DISTRO_NAME='ubuntu'
    echo 'Identified Linux distribution name as "Ubuntu"'
else
    echo "Could not identify Linux distribution. It is likely unsupported."
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
    echo "Could not identify package manager. It is likely unsupported."
    exit 3
fi

update_package_manager () {
    echo "Updating \"$PACKAGE_MANAGER\""
    case "$PACKAGE_MANAGER" in
        'apt')
            sudo apt -qq update
            sudo apt -qq upgrade
            ;;
        *)
            echo "Update of package manager \"$PACKAGE_MANAGER\" not supported."
            return 4
            ;;
    esac
    return 0
}
install_package () {
    local package_name="$1"
    echo "Installing \"$package_name\""
    case "$PACKAGE_MANAGER" in
        'apt')
            sudo apt -qq install -y "$package_name"
            ;;
        *)
            echo "Package installation with package manager \"$PACKAGE_MANAGER\" not supported."
            return 5
            ;;
    esac
    return 0
}

backup_file () {
    local source=$(realpath -m "$1")
    local destination=$(realpath -m "$2")
    local destination_dir=$(dirname "$destination")

    echo "Backing up file at \"$source\" to \"$destination\""

    if ! [ -e "$source" ]; then
        echo "File backup source \"$source\" does not exist."
        return 6
    fi

    if ! [[ "$destination" == "$BACKUP_DIR"/* ]]; then
        echo "File backup destination \"$destination\" must be under backup directory \"$BACKUP_DIR\""
        return 7
    fi
    if [ -e "$destination" ]; then
        echo "File backup destination \"$destination\" already exists. Operation considered unsafe."
        return 8
    fi

    mkdir -p "$destination_dir"
    cp -r "$source" "$destination"
    return 0
}
deploy_file () {
    local source=$(realpath -m "$1")
    local destination=$(realpath -m "$2")
    local destination_dir=$(dirname "$destination")

    echo "Deploying file from source \"$source\" to destination \"$destination\""

    if ! [ -e "$source" ]; then
        echo "File deployment source \"$source\" does not exist."
        return 9
    fi

    if ! [[ "$source" == "$REPO_PATH"/* ]]; then
        echo "File deployment source \"$source\" must be under repo \"$REPO_PATH\""
        return 10
    fi
    if [[ "$destination" == "$REPO_PATH"*(/*) ]]; then
        echo "File deployment destination \"$destination\" must NOT be at or under repo \"$REPO_PATH\""
        return 11
    fi

    mkdir -p "$destination_dir"
    if [ -e "$destination" ]; then
        local backup_rel_path=$(realpath --relative-to="$REPO_PATH" "$source")
        backup_file "$destination" "$BACKUP_DIR/$backup_rel_path"
        rm "$destination"
    fi
    ln "$source" "$destination"
    return 0
}

move_over_file () {
    local source=$(realpath -m "$1")
    local destination=$(realpath -m "$2")

    echo "Moving file over from \"$source\" to \"$destination\""

    if ! [ -e "$source" ]; then
        echo "File move-over source \"$source\" does not exist. Nothing to move over."
        return 0
    fi

    if [[ "$source" == "$REPO_PATH"*(/*) ]]; then
        echo "File move-over source \"$source\" must NOT be at or under repo \"$REPO_PATH\""
        return 12
    fi
    if [[ "$destination" == "$REPO_PATH"*(/*) ]]; then
        echo "File move-over destination \"$destination\" must NOT be at or under repo \"$REPO_PATH\""
        return 13
    fi

    if [ -e "$destination" ]; then
        local line
        while read line; do
            if [ "$line" = "$destination" ]; then
                echo "File move-over to destination \"$destination\" previously done."
                return 0
            fi
        done < "$MOVE_OVER_FILES_PATH"

        echo "File move-over destination \"$destination\" already exists."
        return 14
    fi

    echo "$destination" >> "$MOVE_OVER_FILES_PATH"
    mv "$source" "$destination"
    return 0
}


echo
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
deploy_file dotfiles/inputrc ~/.inputrc
echo
move_over_file ~/.bashrc ~/.bashrc_default
deploy_file dotfiles/bashrc ~/.bashrc
echo
deploy_file dotfiles/ssh/config ~/.ssh/config
echo
deploy_file dotfiles/tmux.conf ~/.tmux.conf
echo
deploy_file dotfiles/vimrc ~/.vimrc
echo
deploy_file dotfiles/gitconfig ~/.gitconfig
echo
deploy_file dotfiles/oh-my-posh/themes/mo.omp.json ~/.oh-my-posh/themes/custom/mo.omp.json
echo
