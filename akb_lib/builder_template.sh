#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function _sb_main {
    log "This is an example AKB builder!"
}