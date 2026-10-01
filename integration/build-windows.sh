#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
msvc=$(cygpath -u "$VCToolsInstallDir")
export PATH="${msvc}bin/Hostx64/x64:$PATH"
export SVT_PREFIX="$root/build-output/install"
cd "$root"
git submodule update --init integration/ffmpeg
sh integration/prepare-ffmpeg.sh
cmake -S . -B build-output/svt -G "Visual Studio 17 2022" -A x64 \
    -DCOMPILE_C_ONLY=OFF -DBUILD_SHARED_LIBS=ON -DBUILD_APPS=ON \
    "-DCMAKE_INSTALL_PREFIX=$(cygpath -m "$SVT_PREFIX")" \
    "-DCMAKE_ASM_NASM_COMPILER=$(cygpath -m "$(command -v nasm)")"
cmake --build build-output/svt --config Release --parallel 6
cmake --install build-output/svt --config Release
mkdir -p build-output/ffmpeg build-output/bin
cd build-output/ffmpeg
if [ ! -f ffbuild/config.mak ]; then
    sh "$root/integration/ffmpeg/configure" --toolchain=msvc \
        --cc="$root/integration/clwrap.sh" --host-cc="$root/integration/clwrap.sh" \
        --ld="$root/integration/linkwrap.sh" --host-ld="$root/integration/linkwrap.sh" \
        --pkg-config="$root/integration/pkg-config-msvc.sh" \
        $(cat "$root/integration/ffmpeg-options.txt")
fi
src_rel="../../integration/ffmpeg"
printf 'include %s/Makefile\n' "$src_rel" > Makefile
sed -i -e "s|^SRC_PATH=.*|SRC_PATH=$src_rel|" -e "s|^SRC_LINK=.*|SRC_LINK=$src_rel|" ffbuild/config.mak
sed -E -i 's#^(CC|CXX|AS|DEPCC|DEPCXX|DEPAS|HOSTCC|DEPHOSTCC)=.*#\1=cl.exe#' ffbuild/config.mak
make -j6
cp ffmpeg.exe ffprobe.exe ../bin/
cp "$SVT_PREFIX/bin/SvtAv1Enc.dll" ../bin/
printf '\nBuilt: %s/build-output/bin/ffmpeg.exe\n' "$root"
