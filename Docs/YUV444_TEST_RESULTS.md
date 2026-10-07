# YUV444 10/12-bit + SCD validation record

Validation date: 2026-10-07 (Windows x64).

## 1. Clean branch build

Source branch: `yuv444-10-12-scd`. The published branch is one standalone feature commit directly on clean mainline-derived base `73ec3ee744f99ba600cf78652c391410ccc74c14`; that feature commit contains the validated local 10-bit 4:4:4 + SCD work together with the current 12-bit extension.

Build command used the Visual Studio 2022 generator, bundled Visual Studio CMake and NASM 2.16.03:

```text
cmake -S . -B build-yuv444-scd -G "Visual Studio 17 2022" -A x64 -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF
cmake --build build-yuv444-scd --config Release --parallel 8
```

Result: **PASS**. `Bin/Release/SvtAv1Enc.dll` and `SvtAv1EncApp.exe` were produced. The only repeated diagnostics were MSVC C4819 code-page warnings in existing source/header files; there were no compile or link errors.

Built `SvtAv1Enc.dll` SHA-256:

`94889C9F123434E2C07F6396C10F47F86408DE8D08509599F1163F2963EDA02D`

## 2. Standalone smoke test

The freshly built DLL was copied into an isolated FFmpeg runtime whose `libsvtav1` wrapper advertises both 4:4:4 formats. The committed `test/yuv444_scd_smoke.py` generated a 48-frame black-to-white scene cut and ran `scd=2:scd-min-keyint=4:keyint=120`.

| Case | Reported output | Keyframes | Full decode | Result |
|---|---|---:|---|---|
| yuv444p10le + scd=2 | yuv444p10le | 2 | PASS | PASS |
| yuv444p12le + scd=2 | yuv444p12le | 2 | PASS | PASS |

The second keyframe confirms that a keyframe was inserted after frame 0 on the abrupt synthetic scene change. Both streams decoded to null without error.

## 3. Broader 2160p local validation retained outside Git

A separate local validation suite used a 3840×2160 source, 4415 frames, preset 6, CRF 36 and `scd=1`. Each feature was tested independently in both yuv444p10le and yuv444p12le and all 4415 frames were checked.

| Feature | yuv444p10le PSNR | yuv444p12le PSNR | 12-bit minus 10-bit | Result |
|---|---:|---:|---:|---|
| film grain | 53.236986 | 53.498795 | +0.261809 | PASS |
| resize | 52.107871 | 52.877074 | +0.769203 | PASS |
| super-resolution | 52.559369 | 53.395224 | +0.835855 | PASS |
| hbd-mds=1 | 53.873404 | 54.047118 | +0.173714 | PASS |
| IntraBC | 53.737702 | 53.878177 | +0.140475 | PASS |

No tested case had a low-score frame under the local rejection thresholds, and no consecutive relative anomaly segment was detected. The local suite also forced 12-bit IntraBC on a repeated-pattern sample and verified encoder reconstruction against decoded pixels for that targeted sample.

Large source media, encoded outputs, PSNR frame dumps and build logs are intentionally not committed. They remain in the local validation workspace under `C:\Private\ffmpeg-native\tests\y412\features`.

## 4. Scope limits

This record demonstrates buildability and the tested 4:4:4 10/12-bit/SCD paths. It does not claim exhaustive coverage of every encoder option, preset, platform, SIMD combination or source type.
