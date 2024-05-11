#!/bin/bash

# Ensure sudo permissions are granted by the invoking user before starting
sudo true

export REPO_PATH=$(realpath "$BASH_SOURCE")
export REPO_PATH=$(dirname "$REPO_PATH")
export REPO_PATH=$(dirname "$REPO_PATH")
export CONFIG_SCRIPT_PATH_AS_GIVEN="$1"
export CONFIG_SCRIPT_PATH=$(realpath -m "$CONFIG_SCRIPT_PATH_AS_GIVEN" 2>/dev/null)
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
    return 2 2>/dev/null || exit 2
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
    return 3 2>/dev/null || exit 3
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
    return 4 2>/dev/null || exit 4
fi

# Set variable indicating whether bash is running in WSL
export IM_IN_WSL=false
if grep -qi -- '-WSL' /proc/sys/kernel/osrelease || test -f /proc/sys/fs/binfmt_misc/WSLInterop; then
    echo "Identified this as a WSL (Windows Subsystem for Linux) environment."
    export IM_IN_WSL=true
fi

update_package_manager () {
    echo "Updating \"$PACKAGE_MANAGER\""
    case "$PACKAGE_MANAGER" in
        'apt')
            sudo apt -qq update -y && sudo apt -qq upgrade -y
            ;;
        *)
            echo "Update of package manager \"$PACKAGE_MANAGER\" not supported."
            return 5
            ;;
    esac
    return
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
            return 6
            ;;
    esac
    return
}

ensure_containing_dir () {
    local given_path="$1"
    local canonical_path=$(realpath -sm "$given_path")
    local containing_dir=$(dirname "$canonical_path")

    mkdir -p "$containing_dir"

    return
}
ensure_inside () {
    local sub_path="$1"
    local sub_path_canonical=$(realpath -sm "$sub_path")
    local sub_dir=$(dirname "$sub_path_canonical")
    local sub_dir=$(realpath -m "$sub_dir")
    local sub_name=$(basename "$sub_path_canonical")
    local sub_path_canonical="$sub_dir/$sub_name"
    local container="$2"
    local container_canonical=$(realpath -sm "$container")
    local container_canonical=$(realpath -m "$container_canonical")

    if ! [[ "$sub_path_canonical" == "$container_canonical"/* ]]; then
        echo "\"$sub_path\" (\"$sub_path_canonical\") must be under \"$container\" (\"$container_canonical\")"
        return 7
    fi

    return 0
}
ensure_outside () {
    local sub_path="$1"
    local sub_path_canonical=$(realpath -sm "$sub_path")
    local sub_dir=$(dirname "$sub_path_canonical")
    local sub_dir=$(realpath -m "$sub_dir")
    local sub_name=$(basename "$sub_path_canonical")
    local sub_path_canonical="$sub_dir/$sub_name"
    local container="$2"
    local container_canonical=$(realpath -sm "$container")
    local container_canonical=$(realpath -m "$container_canonical")

    if [[ "$sub_path_canonical" == "$container_canonical"*(/*) ]]; then
        echo "\"$sub_path\" (\"$sub_path_canonical\") must NOT be at or under \"$container\" (\"$container_canonical\")"
        return 8
    fi

    return 0
}
backup_file () {
    local source="$1"
    local destination="$2"

    echo "Backing up \"$source\" to \"$destination\""

    ensure_inside "$destination" "$BACKUP_DIR" || return
    ensure_containing_dir "$destination"

    cp -a -T --backup='numbered' "$source" "$destination"
    return
}

deploy_file () {
    local source="$1"
    local destination="$2"

    echo "Deploying \"$source\" to \"$destination\""

    if ! [ -e "$source" ]; then
        echo "Deployment source \"$source\" does not exist."
        return 9
    fi

    ensure_inside "$source" "$REPO_PATH" || return
    ensure_outside "$destination" "$REPO_PATH" || return

    if [ -e "$destination" ] || [ -L "$destination" ]; then
        local backup_rel_path=$(realpath --relative-to="$REPO_PATH" "$source")
        backup_file "$destination" "$BACKUP_DIR/deployment/$backup_rel_path" || return
        rm "$destination"
    fi

    ensure_containing_dir "$destination"

    ln -sT "$source" "$destination"
    return
}
deploy_file_wsl () {
    local source="$1"
    local destination="$2"

    echo "Deploying \"$source\" to \"$destination\" in WSL -> Windows style"

    if ! [ -e "$source" ]; then
        echo "Deployment source \"$source\" does not exist."
        return 10
    fi

    ensure_inside "$source" "$REPO_PATH" || return
    ensure_outside "$destination" "$REPO_PATH" || return

    if [ -e "$destination" ] || [ -L "$destination" ]; then
        local backup_rel_path=$(realpath --relative-to="$REPO_PATH" "$source")
        backup_file "$destination" "$BACKUP_DIR/deployment/$backup_rel_path" || return
        rm "$destination"
    fi

    ensure_containing_dir "$destination"

    cp -a -T "$source" "$destination"
    return
}
move_over_file () {
    local source="$1"
    local destination="$2"
    local destination_canonical=$(realpath -m "$destination")

    echo "Moving \"$source\" over to \"$destination\""

    if ! [ -e "$source" ]; then
        echo "Move-over source \"$source\" does not exist. Nothing to move over."
        return 0
    fi

    ensure_outside "$source" "$REPO_PATH" || return
    ensure_outside "$destination" "$REPO_PATH" || return

    if [ -e "$destination" ] || [ -L "$destination" ]; then
        local line
        while read line; do
            if [ "$line" = "$destination_canonical" ]; then
                echo "Move-over to destination \"$destination\" (\"$destination_canonical\") previously done."
                return 0
            fi
        done < "$MOVE_OVER_FILES_PATH"

        local destination_name=$(basename "$destination")
        backup_file "$destination" "$BACKUP_DIR/move-overs/$destination_name" || return
        rm "$destination"
    fi

    echo "$destination_canonical" >> "$MOVE_OVER_FILES_PATH"
    ensure_containing_dir "$destination"
    mv -n -T "$source" "$destination"
    return
}
reset_move_overs () {
    > "$MOVE_OVER_FILES_PATH"
}
set_symlink () {
    local target="$1"
    local link="$2"

    echo "Setting symlink \"$link\" => \"$target\""

    ensure_outside "$link" "$REPO_PATH" || return

    if [ -e "$link" ] || [ -L "$destination" ]; then
        local link_name=$(basename "$link")
        backup_file "$link" "$BACKUP_DIR/symlinks/$link_name" || return
        rm "$link"
    fi

    ensure_containing_dir "$link"
    ln -s -T "$target" "$link"
    return
}

prompt_choice () {
    local var_name="$1"
    local prompt="$2"
    local default_value="$3"
    shift 2
    local menu=$(local IFS='|' && echo "$*")

    while : ; do
        local ret=0
        read -e -t 300 -p "$prompt[$menu]: " "$var_name" || local ret=$?
        if [ "$ret" -gt 128 ]; then
            echo
            export "$var_name"="$default_value"
            echo "Timeout: using first option \"${!var_name}\" as default"
            break
        fi

        local option
        local found='false'
        for option in "$@"; do
            if [ "$option" = "${!var_name}" ]; then
                found='true'
            fi
        done

        if [ "$found" = 'true' ]; then
            break
        else
            echo "Choice '${!var_name}' invalid. Please choose one of: $menu"
        fi
    done
}


return 0 2>/dev/null  # Only do the rest if not sourced

set -e
set -o pipefail

echo
echo "Using configuration source script \"$CONFIG_SCRIPT_PATH_AS_GIVEN\" (from first argument) resolved to \"$CONFIG_SCRIPT_PATH\""
if ! [ -e "$CONFIG_SCRIPT_PATH" ]; then
    echo "Configuration source script \"$CONFIG_SCRIPT_PATH\" does not exist."
    exit 1
fi

echo "Sourcing configuration script from \"$CONFIG_SCRIPT_PATH\""
echo
source "$CONFIG_SCRIPT_PATH"
echo
echo "Done sourcing configuration script from \"$CONFIG_SCRIPT_PATH\""
