#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

AKB_ROOT_DIR="$(dirname $BASH_SOURCE)"
if [[ ! -d "$AKB_ROOT_DIR" ]]; then AKB_ROOT_DIR="$PWD"; fi
AKB_ROOT_DIR="$(realpath $AKB_ROOT_DIR)"

__SRC_DIR="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__SRC_DIR" ]]; then __SRC_DIR="$PWD"; fi
source "$__SRC_DIR/akb_lib/common.sh"

akb::init

case "${1:-}" in
    *)
        echo "Usage: $0 {<... valid sub commands go here ...>}"
        exit 1
        ;;
esac
