#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function _sb_main {
    local out_dir="$AKB_CB_OUT_BOOFS_DIR/wifi_init"
    local out_file="$out_dir/property_shim.so"

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                if [[ ! -e "$out_file" ]]; then
                    log "property_shim cannot be cleaned: not built or bootfs not initialised" "warn"
                    return 0
                fi
                (
                    set -x
                    rm -rf "out"
                    rm "$out_file"
                )
                return 0
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_props {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$out_file" ]]; then
        log "property_shim is already built, pass build explicitly to continue" "warn"
        return 0
    fi

    tc::use
    mkdir -p "$out_dir"
    mkdir -p out

    for f in *.c; do
        obj="${f%.c}.o"
        (
            set -x
            # $AKB_TC_CC -DINCLUDE_DEBUG_HOOKS -c "$f" -o "out/$obj"
            $AKB_TC_CC -c "$f" -o "out/$obj"
        )
    done

    (
        set -x
        $AKB_TC_CC -shared -fvisibility=hidden -fPIC out/* -o "$out_file"
    )
}