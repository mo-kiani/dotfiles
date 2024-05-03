#!/bin/bash

# Always run this script with its physical path as its working directory
cd -P "$(dirname $(realpath "$0"))"
echo "Running from absolute physical path: $(pwd)"
