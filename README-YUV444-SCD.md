# SVT-AV1 YUV444 10/12-bit + SCD branch

This branch carries only the local **YUV 4:4:4 high-bit-depth work** and the **scene-change keyframe logic** on top of the SVT-AV1 mainline-derived base used by the local project.

## Included

- YUV444 10-bit encoding.
- YUV444 12-bit encoding, including high-bit-depth transform, prediction, filtering, resize/superres, noise/grain, rate-control and buffer-path fixes needed by the validated local build.
- Scene-change keyframes:
  - `scd=0`: disabled.
  - `scd=1`: histogram/region detector.
  - `scd=2`: histogram prefilter plus source-domain prediction cost and short future-frame confirmation.
- `scd-min-keyint` to limit scene-triggered keyframe frequency.
- FFmpeg wrapper patch for `yuv444p10le` / `yuv444p12le`: `integration/ffmpeg-yuv444p10p12.patch`.
- Reproducible smoke test: `test/yuv444_scd_smoke.py`.

## Not included

This branch intentionally excludes unrelated encoder tuning families, alternate filtering controls, quality-bias options and release automation from other experimental branches.

## FFmpeg integration

The wrapper patch was generated against FFmpeg commit:
`8864fd0aecf21fe9e3cfcd83a8ef33cb7e885fd4`

Apply it in an FFmpeg checkout:

```powershell
git apply path\to\integration\ffmpeg-yuv444p10p12.patch
```

Build FFmpeg against the SVT library produced from this branch. The patch:
1. sizes input buffers correctly for 4:4:4,
2. advertises `AV_PIX_FMT_YUV444P10` and `AV_PIX_FMT_YUV444P12`,
3. selects AV1 High profile for 10-bit 4:4:4 and Professional profile for >10-bit,
4. enables scene detection by default while still allowing `-svtav1-params scd=0/1/2` to override it.

Example:

```powershell
ffmpeg -i input.mkv -c:v libsvtav1 -pix_fmt yuv444p12le -preset 8 -crf 30 `
  -svtav1-params "scd=2:scd-min-keyint=32:keyint=257" output.mkv
```

## Validation

Run:

```powershell
python .\test\yuv444_scd_smoke.py --ffmpeg C:\path\to\ffmpeg.exe --ffprobe C:\path\to\ffprobe.exe
```

The test encodes synthetic 4:4:4 10-bit and 12-bit scene-cut clips, decodes both outputs, checks output pixel formats and checks that the scene-change path inserts at least one keyframe after frame 0.

See `Docs/YUV444_10_12_SCD.md` for implementation notes and `Docs/YUV444_TEST_RESULTS.md` for the validation record generated for this branch.
