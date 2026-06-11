#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function _sb_main {
    local out_dir="$AKB_CB_OUT_BOOFS_DIR/wifi_init"
    local out_file="$out_dir/libnl.so"

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                if [[ ! -e "$out_file" ]]; then
                    log "libnl_stub cannot be cleaned: not built or bootfs not initialised" "warn"
                    return 0
                fi
                (
                    set -x
                    rm "$out_file"
                )
                return 0
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_lnl {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$out_file" ]]; then
        log "libnl_stub is already built, pass build explicitly to continue" "warn"
        return 0
    fi

    tc::use
    mkdir -p "$out_dir"

    (
        set -x
        # $AKB_TC_CC -shared -fPIC -DINCLUDE_LOGS main.c -o "$out_file"
        $AKB_TC_CC -shared -fPIC main.c -o "$out_file"
    )
}