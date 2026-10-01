#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root/integration/ffmpeg"
if git apply --reverse --check ../ffmpeg-yuv444p10.patch 2>/dev/null; then
    exit 0
fi
git apply --check ../ffmpeg-yuv444p10.patch
git apply ../ffmpeg-yuv444p10.patch
