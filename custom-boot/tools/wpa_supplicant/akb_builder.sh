#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

WPASUPPLICANT_ARCHIVE="https://w1.fi/releases/wpa_supplicant-2.12.tar.gz"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

WPASUPPLICANT_LOGS="$(realpath .)/build.log"

function download_src {
    if [[ -d "src" ]]; then
        return 0
    fi
    log "Downloading $WPASUPPLICANT_ARCHIVE"
    wget "$WPASUPPLICANT_ARCHIVE" -O"wpa_supplicant.tar.gz" &>>$WPASUPPLICANT_LOGS
    mkdir -p src
    tar -C "src" --strip-components=1 -xvf "wpa_supplicant.tar.gz" &>>$WPASUPPLICANT_LOGS
    rm "wpa_supplicant.tar.gz"
}

function _sb_main {
    AKB_MKB_SOURCE_DIR="$(realpath src)/wpa_supplicant"
    AKB_MKB_BUILD_DIR="$AKB_MKB_SOURCE_DIR"
    AKB_MKB_BUILD_ARGS=(
        "__AKB_DUMMY=1" # todo: currently AKB_MKB_BUILD_ARGS cannot be empty
    )

    _akb_import "/../akb_lib/makebuild.sh"
    echo -n > $WPASUPPLICANT_LOGS

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                if [[ ! -d "$AKB_MKB_SOURCE_DIR" ]]; then
                    log "Source directory not found, cannot run clean" "error"
                    return 1
                fi
                
                read -p "Run clean? [y/N] " clean_prompt

                case "$clean_prompt" in
                    [yY])
                        mkb::run "clean"
                        return 0
                        ;;

                    *)
                        log "Clean cancelled" "warn"
                        ;;
                esac
                
                return 1
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_wpasup {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$AKB_CB_OUT_BOOFS_DIR/sbin/wpa_supplicant" ]]; then
        log "wpa_supplicant already exists in the bootfs, pass build explicitly to continue" "warn"
        return 0
    fi

    if [[ ! -d "$AKB_CB_TOOLS_DIR/openssl/build" ]]; then
        log "You must first build OpenSSL before wpa_supplicant" "error"
        return 1
    fi

    if [[ ! -d "$AKB_CB_TOOLS_DIR/libnl/src/build" ]]; then
        log "You must first build libnl before wpa_supplicant" "error"
        return 1
    fi

    download_src
    tc::use

    log "Configuring wpa_supplicant"
    cat > "$AKB_MKB_SOURCE_DIR/.config" <<EOF
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CC=$AKB_TC_CC
LDFLAGS += -static -pthread
CFLAGS += -I$AKB_CB_TOOLS_DIR/libnl/src/build/include
CFLAGS += -I$AKB_CB_TOOLS_DIR/openssl/build/include
LDFLAGS += -L$AKB_CB_TOOLS_DIR/libnl/src/build/lib
LDFLAGS += -L$AKB_CB_TOOLS_DIR/openssl/build/lib
EOF
    
    mkb::run "-j$(nproc)" "wpa_supplicant" "wpa_passphrase" "wpa_cli" 

    log "Copying built wpa_supplicant"
    cp "$AKB_MKB_BUILD_DIR/wpa_supplicant" "$AKB_CB_OUT_BOOFS_DIR/sbin/wpa_supplicant"
    log "Copying built wpa_passphrase"
    cp "$AKB_MKB_BUILD_DIR/wpa_passphrase" "$AKB_CB_OUT_BOOFS_DIR/sbin/wpa_passphrase"
    log "Copying built wpa_cli"
    cp "$AKB_MKB_BUILD_DIR/wpa_cli" "$AKB_CB_OUT_BOOFS_DIR/sbin/wpa_cli"
}
