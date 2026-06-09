#!/bin/sh

exec 1>/dev/kmsg
exec 2>&1

log() {
    local level="$1"
    shift
    
    case "$level" in
        error)
            printf "<1>[ERROR] %s\n" "$*"
            ;;

        warn)
            printf "<1>[WARN] %s\n" "$*"
            ;;

        *)
            printf "<1>[INFO] %s\n" "$*"
            ;;
    esac
}

log warn "Serial tty: enter loop"

while true; do
    if [ -e /dev/ttyGS0 ]; then
        log warn "Serial tty: shell start"
        /bin/sh -i </dev/ttyGS0 >/dev/ttyGS0 2>&1
        log warn "Serial tty: shell end"
    else
        log warn "Serial tty: waiting for /dev/ttyGS0"
        sleep 2
    fi
done