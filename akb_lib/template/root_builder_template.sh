#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Imports
# ---------------------------------------------------------
__SRC_DIR="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__SRC_DIR" ]]; then __SRC_DIR="$PWD"; fi
__SRC_DIR="$(realpath $__SRC_DIR)"
# ---------------------------------------------------------
source "$__SRC_DIR/akb_lib/common.sh"

# Environment
AKB_ROOT_DIR="$(akb::find_root_dir "${BASH_SOURCE[0]}")"

akb::init

case "${1:-}" in
    *)
        echo "Usage: $0 {<... valid sub commands go here ...>}"
        exit 1
        ;;
esac
