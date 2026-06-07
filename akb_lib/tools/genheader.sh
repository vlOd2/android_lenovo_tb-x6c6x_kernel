#!/bin/bash

uuid=$(uuidgen)
uuid=${uuid//-/}

import_dir_var="__AKB_IMPORT_DIR_${uuid::12}"

header=$(
cat <<END
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Imports
# ---------------------------------------------------------
shopt -s expand_aliases;
$import_dir_var="\$(dirname \${BASH_SOURCE[0]})"
if [[ ! -d "\$$import_dir_var" ]]; then $import_dir_var="\$PWD"; fi
$import_dir_var="\$(realpath \$$import_dir_var)"
_akb_import() { alias _akb_import=$uuid; source "\$$import_dir_var\$1"; unalias _akb_import >/dev/null 2>&1 || true; unset -f $uuid; }
# ---------------------------------------------------------
END
)

echo "$header"