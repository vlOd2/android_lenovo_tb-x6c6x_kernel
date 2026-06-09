#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function _sb_main {
    if [[ "${RB_REBOOTER:-0}" -ne "1" && -e "$AKB_CB_OUT_BOOFS_DIR/bin/rebooter" ]]; then
        log "Rebooter is already built, export RB_REBOOTER=1 to rebuild" "warn"
        return 0
    fi
    
    tc::use
    mkdir -p "$AKB_CB_OUT_BOOFS_DIR/bin"

    (
        set -x
        $AKB_TC_CC -static main.c -o "$AKB_CB_OUT_BOOFS_DIR/bin/rebooter"
    )
}