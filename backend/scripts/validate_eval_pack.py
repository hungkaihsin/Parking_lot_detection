#!/usr/bin/env python3
"""Validate and assemble a day evaluation pack.

This script looks for run folders under `backend/runs/w2_day_eval/` and builds
`backend/data/eval/day_pack/` containing a subset of frames and a consolidated
`events.csv` (GT stall events). It performs basic checks: frame counts,
matching events file, and prints a short summary.

Usage: python3 backend/scripts/validate_eval_pack.py
"""
import argparse
import csv
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNS_DIR = ROOT / "runs" / "w2_day_eval"
PACK_DIR = ROOT / "data" / "eval" / "day_pack"


def find_runs():
    if not RUNS_DIR.exists():
        return []
    return [p for p in RUNS_DIR.iterdir() if p.is_dir()]


def summarize_run(run_path: Path):
    frames = sorted(run_path.glob('frame_*.jpg'))
    events = run_path / 'events.csv'
    return {'run': run_path.name, 'frames': len(frames), 'has_events': events.exists(), 'events_path': str(events) if events.exists() else None}


def assemble_pack(runs, pack_dir: Path, per_run_limit: int | None):
    """Assemble an evaluation pack.

    per_run_limit: if None copy all frames from each run, otherwise copy up to that many frames per run.
    """
    pack_dir.mkdir(parents=True, exist_ok=True)
    # copy frames (limit per run) and concatenate events.csv into one
    out_events = pack_dir / 'events.csv'
    with out_events.open('w', newline='') as outf:
        writer = None
        for run in runs:
            frames = sorted(run.glob('frame_*.jpg'))
            to_copy = frames if per_run_limit is None else frames[:per_run_limit]
            for f in to_copy:
                dest = pack_dir / f.name
                if not dest.exists():
                    dest.write_bytes(f.read_bytes())
            ev = run / 'events.csv'
            if ev.exists():
                with ev.open('r', newline='') as inf:
                    reader = csv.DictReader(inf)
                    if writer is None:
                        writer = csv.DictWriter(outf, fieldnames=reader.fieldnames)
                        writer.writeheader()
                    for row in reader:
                        writer.writerow(row)
    
    # Create data.yaml for YOLO evaluation
    data_yaml_content = f"""path: {pack_dir.resolve()}
train:
val:
test: .

names:
  0: occupied
  1: empty
"""
    (pack_dir / 'data.yaml').write_text(data_yaml_content)


def main():
    parser = argparse.ArgumentParser(description='Assemble/validate day eval pack from runs')
    parser.add_argument('--dest', '-d', default=str(PACK_DIR), help='Destination directory for pack')
    parser.add_argument('--per-run', '-n', type=int, default=10, help='Number of frames to copy per run; set 0 to copy none, -1 to copy all')
    args = parser.parse_args()

    runs = find_runs()
    if not runs:
        print('No runs found under', RUNS_DIR)
        return 2
    print('Found runs:', ', '.join(p.name for p in runs))
    summary = [summarize_run(r) for r in runs]
    for s in summary:
        print(f"- {s['run']}: frames={s['frames']} events={s['has_events']}")

    dest = Path(args.dest)
    per_run_limit = None if args.per_run < 0 else args.per_run
    assemble_pack(runs, dest, per_run_limit)
    print('\nAssembled pack into:', dest)
    # quick report
    imgs = list(dest.glob('*.jpg'))
    ev = dest / 'events.csv'
    print(f'Pack contains {len(imgs)} frames, events.csv exists={ev.exists()}, and data.yaml exists={(dest / "data.yaml").exists()}')


if __name__ == '__main__':
    raise SystemExit(main())
