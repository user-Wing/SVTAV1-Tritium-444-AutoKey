#!/bin/sh
if [ "${1:-}" = "-nologo-" ]; then
    echo 'Microsoft (R) C/C++ Optimizing Compiler (cl.exe)'
    exit 0
fi
exec cl.exe "$@"
