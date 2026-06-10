#!/bin/bash
IFS=$'\n\t'

if [[ -z "${AKB_LOAD_ENV:-}" ]]; then
    echo "error: AKB_LOAD_ENV is not defined"
else
    AKB_LOAD_ENV="$(realpath $AKB_LOAD_ENV)"

    if [[ ! -f "$AKB_LOAD_ENV" ]]; then
        echo "error: $AKB_LOAD_ENV does not exist"
    else
        __AKB_IMPORT_DIR="$(dirname ${BASH_SOURCE[0]})"
        if [[ ! -d "$__AKB_IMPORT_DIR" ]]; then __AKB_IMPORT_DIR="$PWD"; fi
        __AKB_IMPORT_DIR="$(realpath $__AKB_IMPORT_DIR)"
        source "$__AKB_IMPORT_DIR/../common.sh"
        source "$AKB_LOAD_ENV"
        set +euo pipefail
        IFS=$' \t\n'
        echo "Loaded $AKB_LOAD_ENV"
    fi
    
    unset -v AKB_LOAD_ENV
fi