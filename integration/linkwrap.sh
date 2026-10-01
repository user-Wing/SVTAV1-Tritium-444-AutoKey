#!/bin/sh
link_exe="$(dirname "$(command -v cl.exe)")/link.exe"
if [ "${1:-}" = "-nologo-" ]; then
    echo 'Microsoft (R) Incremental Linker (link.exe)'
    exit 0
fi
exec "$link_exe" "$@"
