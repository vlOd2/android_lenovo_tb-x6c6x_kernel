#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

AKB_ROOT_DIR="$(dirname $BASH_SOURCE)"
if [[ ! -d "$AKB_ROOT_DIR" ]]; then AKB_ROOT_DIR="$PWD"; fi
AKB_ROOT_DIR="$(realpath $AKB_ROOT_DIR)"
