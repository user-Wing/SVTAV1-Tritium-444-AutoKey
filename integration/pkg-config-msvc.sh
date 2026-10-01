#!/bin/sh
set -eu
prefix=$(cygpath -m "$SVT_PREFIX")
for arg in "$@"; do
    case "$arg" in
        --exists|--atleast-version=*) exit 0 ;;
        --modversion) sed -n 's/^Version: //p' "$SVT_PREFIX/lib/pkgconfig/SvtAv1Enc.pc"; exit 0 ;;
        --cflags|--cflags-only-I) echo "-I$prefix/include/svt-av1"; exit 0 ;;
        --libs) echo "-L$prefix/lib -lSvtAv1Enc"; exit 0 ;;
        --variable=includedir) echo "$prefix/include/svt-av1"; exit 0 ;;
    esac
done
