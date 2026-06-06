#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

__SRC_DIR="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__SRC_DIR" ]]; then __SRC_DIR="$PWD"; fi
source "$__SRC_DIR/<... environment script goes here ...>"
source "$__SRC_DIR/akb_lib/common.sh"

akb::init

case "${1:-}" in
    *)
        echo "Usage: $0 {<... valid sub commands go here ...>}"
        exit 1
        ;;
esac
