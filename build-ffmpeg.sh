#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
git submodule update --init integration/ffmpeg
sh integration/prepare-ffmpeg.sh
prefix="$root/build-output/install"
cmake -S . -B build-output/svt -DCMAKE_BUILD_TYPE=Release \
    -DCOMPILE_C_ONLY=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_APPS=ON \
    -DCMAKE_INSTALL_PREFIX="$prefix"
cmake --build build-output/svt --parallel 6
cmake --install build-output/svt
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
mkdir -p build-output/ffmpeg build-output/bin
cd build-output/ffmpeg
if [ ! -f ffbuild/config.mak ]; then
    sh "$root/integration/ffmpeg/configure" --prefix="$root/build-output/bin" \
        --pkg-config-flags=--static $(cat "$root/integration/ffmpeg-options.txt")
fi
make -j6
cp ffmpeg ffprobe ../bin/
printf '\nBuilt: %s/build-output/bin/ffmpeg\n' "$root"
