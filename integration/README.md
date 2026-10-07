# FFmpeg integration

`ffmpeg-yuv444p10p12.patch` targets FFmpeg commit `8864fd0aecf21fe9e3cfcd83a8ef33cb7e885fd4`.

Apply it to FFmpeg, then build FFmpeg against the SVT library from this branch.

The patch changes only `libavcodec/libsvtav1.c` and exposes:
- `yuv444p10le`
- `yuv444p12le`
- correct 4:4:4 input buffer sizing
- High/Professional AV1 profile selection
- SCD default enablement with normal `-svtav1-params` override behavior
