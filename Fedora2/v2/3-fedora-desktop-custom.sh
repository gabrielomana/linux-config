#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo "■ Error en la línea $LINENO"; exit 1' ERR

source "$(dirname "${BASH_SOURCE[0]}")/sources/functions/functions.sh"


