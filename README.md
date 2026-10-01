# SVTAV1-Tritium-444-AutoKey

基于 SVT-AV1-Tritium，合并本地 **yuv444p10le** 编码修复和 **scd=2 自动关键帧**机制。仓库提供 SVT 核心源码、固定版本 FFmpeg 子模块、444 接口补丁和构建入口，直接生成仅含 SVT 视频编码器的最小 FFmpeg。

此实现仍为实验性支持；12-bit 编码尚未实现。Tritium 的其他选项和原有 `scd=0/1` 保留。若需使用本轮代价/前瞻判断，请显式设置 `scd=2`。

## Windows x64 构建

安装并加入 PATH：

- [Git for Windows](https://gitforwindows.org/)。
- [Visual Studio 2022 Build Tools](https://visualstudio.microsoft.com/downloads/)，选择“使用 C++ 的桌面开发”，包含 MSVC 和 Windows SDK。
- [CMake](https://cmake.org/download/) 和 [NASM](https://www.nasm.us/)。
- GNU Make：可安装 [MSYS2](https://www.msys2.org/)，在其终端执行 `pacman -S make`。脚本可自动使用默认位置 `C:\msys64\usr\bin`；其他位置需手动加入 PATH。

在没有空格的目录中克隆、构建：

```powershell
git clone --recurse-submodules --branch tritium-444-autokey https://github.com/user-Wing/SVTAV1-Tritium-444-AutoKey.git
cd SVTAV1-Tritium-444-AutoKey
.\build-ffmpeg.bat
```

输出：`build-output/bin/ffmpeg.exe`、`ffprobe.exe`、`SvtAv1Enc.dll`。运行时将 DLL 与 EXE 放在同一目录。脚本自动初始化子模块、应用 FFmpeg 补丁、构建 SVT SIMD 库和 FFmpeg，默认并行数为 6。需要联网获取 FFmpeg 子模块；不下载测试视频。

## Linux 构建

安装 C/C++ 编译器、CMake、Git、NASM、GNU Make 和 pkg-config，然后执行：

```sh
git clone --recurse-submodules --branch tritium-444-autokey https://github.com/user-Wing/SVTAV1-Tritium-444-AutoKey.git
cd SVTAV1-Tritium-444-AutoKey
sh build-ffmpeg.sh
```

输出位于 `build-output/bin`，SVT 静态链接到 FFmpeg。Linux 入口尚未在本轮本机验证，Windows x64 已进行完整构建与编码验证。

## 编码示例

```powershell
.\build-output\bin\ffmpeg.exe -i input.mkv -an -c:v libsvtav1 -pix_fmt yuv444p10le -preset 8 -crf 36 -svtav1-params "scd=2:scd-min-keyint=32:keyint=257:enable-tf=3:tf-strength=1:kf-tf-strength=1:lp=4" output.mkv
```

`scd=2` 先用直方图筛选，再比较低分辨率亮度的帧内和运动预测代价，使用最多 3 个可用后续帧复核，减少闪光、遮挡返回、平移造成的误插帧。最小/最大关键帧间隔仍然生效；代价分析有额外计算，同 preset 不等于零速度开销。

最小构建只启用 `libsvtav1` 视频编码器，保留常用测试输入解码器和容器，不包含音频编码器、AV1 解码器或 VMAF。评分与双解码验证使用独立完整 FFmpeg。查看构建选项：`integration/ffmpeg-options.txt`。

## 验证结果与范围

同一约 61 秒 H.264 原片，1466 帧；preset 8、CRF 36、444p10le、lp=4、TF=3/强度1、最小间隔32/最大257，评分模型严格为 **vmaf_v0.6.1neg**：

| 策略 | IVF 字节数 | VMAF NEG | 关键帧数 |
|---|---:|---:|---:|
| Tritium + scd=1 | 10,001,870 | 94.936008 | 20 |
| Tritium + scd=2 | 9,994,244 | 94.942663 | 21 |

体积减少 0.076%，分数增加 0.006655，属于微小改善，不能据此推断所有素材都更好。原 Tritium 19 组回归码流逐字节不变；SCD2 的场景/间隔、24 次确定性、闪光/平移/64×64 SIMD 边界、随机访问与参数限制验证通过。两策略全片 dav1d/libaom 解码哈希一致。本次合并未另做 Tritium ASan；仅色度切换、长遮挡及更多素材仍需验证。

## 来源、版本与许可证

- Tritium 上游：[Uranite/svt-av1-tritium](https://github.com/Uranite/svt-av1-tritium)，提交 `4bbed4ad69ed6a3d2e636457099fab07583e9819`；本地 444/自动关键帧合并基础 `a8d4f19e1ad3a5718e38cd6e4d5ee05dd3617669`，本分支进一步加入 SCD2。
- FFmpeg 子模块：[FFmpeg/FFmpeg](https://github.com/FFmpeg/FFmpeg)，固定提交 `8864fd0aecf21fe9e3cfcd83a8ef33cb7e885fd4`；444 接口补丁为 `integration/ffmpeg-yuv444p10.patch`。
- SVT 的原始许可见 `LICENSE.md`、`LICENSE-BSD2.md` 和 `PATENTS.md`；FFmpeg 许可见其子模块的 `LICENSE.md` 及 `COPYING.*`。新增构建脚本沿用 SVT 根目录许可证，FFmpeg 补丁沿用被修改源文件许可证。
- 原 Tritium 文档保存在 `README-tritium-upstream.md`。本分支更新请正常合并，勿照原上游文档的 `reset --hard origin/main` 操作。

未上传原视频、测试输出、DLL/EXE、本机路径或构建缓存。完整 SVT 上游 Git 历史和许可证保留。
