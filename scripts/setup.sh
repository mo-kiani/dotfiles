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
