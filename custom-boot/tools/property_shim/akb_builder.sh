#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function _sb_main {
    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                if [[ ! -e "$AKB_CB_OUT_BOOFS_DIR/lib/property_shim.so" ]]; then
                    log "property_shim cannot be cleaned: not built or bootfs not initialised" "warn"
                    return 0
                fi
                (
                    set -x
                    rm "$AKB_CB_OUT_BOOFS_DIR/lib/property_shim.so"
                )
                return 0
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_property_shim {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$AKB_CB_OUT_BOOFS_DIR/lib/property_shim.so" ]]; then
        log "property_shim is already built, pass build explicitly to continue" "warn"
        return 0
    fi

    tc::use
    mkdir -p "$AKB_CB_OUT_BOOFS_DIR/lib"

    (
        set -x
        $AKB_TC_CC -shared -fPIC main.c -o "$AKB_CB_OUT_BOOFS_DIR/lib/property_shim.so"
    )
}