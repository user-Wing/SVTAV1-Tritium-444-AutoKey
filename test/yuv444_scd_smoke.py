import argparse
import json
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path


def run(args, capture=False):
    cp = subprocess.run(args, text=True, capture_output=capture)
    if cp.returncode:
        raise RuntimeError(f"command failed ({cp.returncode}): {' '.join(map(str, args))}\n{cp.stderr or ''}")
    return cp.stdout if capture else ''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ffmpeg', required=True)
    ap.add_argument('--ffprobe')
    ap.add_argument('--workdir')
    ns = ap.parse_args()

    ffmpeg = Path(ns.ffmpeg).resolve()
    ffprobe = Path(ns.ffprobe).resolve() if ns.ffprobe else ffmpeg.with_name('ffprobe.exe')
    if not ffmpeg.is_file() or not ffprobe.is_file():
        raise FileNotFoundError('ffmpeg/ffprobe not found')

    workdir = Path(ns.workdir).resolve() if ns.workdir else Path(tempfile.gettempdir()) / 'svt-yuv444-scd-smoke'
    workdir.mkdir(parents=True, exist_ok=True)

    help_text = run([str(ffmpeg), '-hide_banner', '-h', 'encoder=libsvtav1'], capture=True)
    for pix_fmt in ('yuv444p10le', 'yuv444p12le'):
        if pix_fmt not in help_text:
            raise RuntimeError(f'libsvtav1 does not advertise {pix_fmt}')

    results = []
    for pix_fmt in ('yuv444p10le', 'yuv444p12le'):
        name = f'{pix_fmt}-scd2'
        output = workdir / f'{name}.mkv'
        args = [
            str(ffmpeg), '-hide_banner', '-y',
            '-f', 'lavfi', '-i', 'color=c=black:s=128x72:r=24:d=1',
            '-f', 'lavfi', '-i', 'color=c=white:s=128x72:r=24:d=1',
            '-filter_complex', f'[0:v][1:v]concat=n=2:v=1:a=0,format={pix_fmt}[v]',
            '-map', '[v]', '-frames:v', '48',
            '-c:v', 'libsvtav1', '-preset', '10', '-crf', '35',
            '-pix_fmt', pix_fmt,
            '-svtav1-params', 'scd=2:scd-min-keyint=4:keyint=120',
            '-an', str(output),
        ]
        run(args)

        actual_fmt = run([
            str(ffprobe), '-v', 'error', '-select_streams', 'v:0',
            '-show_entries', 'stream=pix_fmt', '-of', 'default=nw=1:nk=1', str(output)
        ], capture=True).strip().splitlines()[0]
        if actual_fmt != pix_fmt:
            raise RuntimeError(f'{name}: expected {pix_fmt}, got {actual_fmt}')

        frame_text = run([
            str(ffprobe), '-v', 'error', '-select_streams', 'v:0',
            '-show_entries', 'frame=key_frame,pict_type', '-of', 'csv=p=0', str(output)
        ], capture=True)
        keyframes = sum(1 for line in frame_text.splitlines() if line.startswith('1,'))
        if keyframes < 2:
            raise RuntimeError(f'{name}: expected scene-triggered keyframe; keyframe count={keyframes}')

        run([str(ffmpeg), '-hide_banner', '-v', 'error', '-i', str(output), '-f', 'null', 'NUL'])
        results.append({
            'name': name,
            'pix_fmt': actual_fmt,
            'keyframes': keyframes,
            'decoded': True,
            'bytes': output.stat().st_size,
        })

    report = {
        'ffmpeg': str(ffmpeg),
        'ffprobe': str(ffprobe),
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'cases': results,
    }
    result_path = workdir / 'smoke-results.json'
    result_path.write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report, indent=2))
    print(f'RESULT_JSON={result_path}')


if __name__ == '__main__':
    main()
