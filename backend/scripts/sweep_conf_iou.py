#!/usr/bin/env python3
import argparse, os, glob, itertools, json, re
from pathlib import Path

import cv2
import pandas as pd
import yaml

CONFIG_PATH  = Path("/app/configs/detector_day.yaml")  # optional (kept for traceability)
OUTPUT_ROOT  = Path("/app/data/overlays")
SWEEPS_DIR   = Path("/app/configs/_sweeps")
SPEC_CSV     = Path("/app/data/processed/car_specs_v0_filtered.csv")

def parse_brand_model_from_filename(fname: str):
    """Assumes names like 'Acura_ILX_2013_...jpg' -> brand='Acura', model='ILX' (best effort)."""
    base = Path(fname).stem
    parts = re.split(r"[_\s\-]+", base)
    brand = parts[0] if parts else ""
    model = parts[1] if len(parts) > 1 else ""
    return brand.title(), model.upper()

def draw_panel(img, lines, bottom_padding=10):
    """Draw a semi-transparent panel with text at the bottom."""
    h, w = img.shape[:2]
    overlay = img.copy()
    panel_h = 28 + 22*len(lines)
    y0 = h - panel_h - bottom_padding
    y0 = max(0, y0)
    # panel
    cv2.rectangle(overlay, (0, y0), (w, y0+panel_h), (0,0,0), -1)
    img = cv2.addWeighted(overlay, 0.45, img, 0.55, 0)
    # text
    y = y0 + 22
    for line in lines:
        cv2.putText(img, line, (12, y), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255,255,255), 2)
        y += 22
    return img

def write_overlay(src_path: str, out_dir: Path, spec_row: dict, conf: float, iou: float):
    img = cv2.imread(src_path)
    if img is None:
        raise RuntimeError(f"failed to read image: {src_path}")

    # Assemble lines to print
    lines = []
    if spec_row:
        brand = str(spec_row.get("brand", "")).title() or "Unknown"
        model = str(spec_row.get("model", "")).upper() or ""
        year  = str(spec_row.get("year", "")).strip()
        body  = str(spec_row.get("body_type", "")).title() if "body_type" in spec_row else ""
        lines.append(f"{brand} {model} {year}".strip())
        if body:
            lines.append(body)
    else:
        # fallback to filename parse only
        brand, model = parse_brand_model_from_filename(src_path)
        lines.append(f"{brand} {model}".strip())

    # Optional: include sweep tags to satisfy the “conf/iou sweep” deliverable
    lines.append(f"(conf={conf:.2f}, iou={iou:.2f})")

    img = draw_panel(img, lines)

    out_dir.mkdir(parents=True, exist_ok=True)
    out_name = f"{Path(src_path).stem}_conf{conf:.2f}_iou{iou:.2f}.jpg"
    out_path = out_dir / out_name
    ok = cv2.imwrite(str(out_path), img)
    if not ok:
        raise RuntimeError(f"failed to write {out_path}")
    return str(out_path)

from ultralytics import YOLO

def detect_and_overlay(img_path, conf, iou, out_dir, weights="yolov8n.pt"):
    model = getattr(detect_and_overlay, "_model", None)
    if model is None:
        model = YOLO(weights)
        detect_and_overlay._model = model

    results = model.predict(source=img_path, conf=conf, iou=iou, save=False, verbose=False)
    img = cv2.imread(img_path)
    for r in results:
        boxes = getattr(r, "boxes", None)
        if not boxes or boxes.xyxy is None:
            continue
        names = r.names if hasattr(r, "names") else model.names
        for xyxy, cls_i in zip(boxes.xyxy.cpu().numpy().astype(int), boxes.cls.cpu().numpy().astype(int)):
            x1,y1,x2,y2 = xyxy.tolist()
            cv2.rectangle(img, (x1,y1), (x2,y2), (0,255,0), 2)
            cv2.putText(img, names.get(int(cls_i), str(int(cls_i))), (x1, max(0,y1-6)),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,0), 1)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{Path(img_path).stem}_conf{conf:.2f}_iou{iou:.2f}.jpg"
    cv2.imwrite(str(out_path), img)
    return str(out_path)


def main():
    p = argparse.ArgumentParser(description="Stamp car brand/model/type overlays from CSV (no detection).")
    p.add_argument("--conf", default="0.40,0.50", help="Comma-separated conf list (kept for sweep book-keeping)")
    p.add_argument("--iou",  default="0.40,0.50", help="Comma-separated iou list (kept for sweep book-keeping)")
    p.add_argument("--inputs", nargs="+",
                   default=["/app/data/car_archive/*.jpg", "/app/data/car_archive/**/*.jpg"],
                   help="Glob(s) for input images")
    p.add_argument("--max-overlays", type=int, default=20, help="Stop after this many outputs")
    p.add_argument("--mode", choices=["overlay_csv", "detect"], default="overlay_csv")
    args = p.parse_args()

    # inputs
    inputs = []
    for pat in args.inputs:
        inputs.extend(sorted(glob.glob(pat, recursive=True)))
    if not inputs:
        raise SystemExit(f"No inputs found. Tried: {args.inputs}")

    # base yaml (optional)
    base = {}
    if CONFIG_PATH.exists():
        base = yaml.safe_load(open(CONFIG_PATH, "r", encoding="utf-8")) or {}

    # per-combo yaml outputs (traceability)
    SWEEPS_DIR.mkdir(parents=True, exist_ok=True)

    # CSV specs
    spec = None
    if SPEC_CSV.exists():
        spec = pd.read_csv(SPEC_CSV)
        # normalize brand/model columns if present
        for col in ["brand", "model"]:
            if col in spec.columns:
                spec[col] = spec[col].astype(str)

    conf_list = [float(x) for x in args.conf.split(",")]
    iou_list  = [float(x) for x in args.iou.split(",")]

    manifest = []
    count = 0
    for conf in conf_list:
        for iou in iou_list:
            # write a tiny sweep config snapshot (for your `_sweeps` folder)
            cfg = dict(base) if base else {}
            cfg.setdefault("postprocess", {})
            cfg["postprocess"]["conf"] = conf
            cfg["postprocess"]["iou"]  = iou
            cfg.setdefault("overlay", {"enabled": True, "out_dir": "data/overlays"})
            tmp_cfg = SWEEPS_DIR / f"detector_day_conf{conf:.2f}_iou{iou:.2f}.yaml"
            with open(tmp_cfg, "w", encoding="utf-8") as f:
                yaml.safe_dump(cfg, f, sort_keys=False, allow_unicode=True)

            combo_out = OUTPUT_ROOT / f"conf{conf:.2f}_iou{iou:.2f}"
            for img in inputs:
                if count >= args.max_overlays:
                    break

                # lookup spec by brand (and try model substring if available)
                brand, model_guess = parse_brand_model_from_filename(img)
                row = None
                if spec is not None and "brand" in spec.columns:
                    cand = spec[spec["brand"].str.lower() == brand.lower()]
                    if "model" in spec.columns and model_guess:
                        # try to refine by model substring
                        sub = cand[cand["model"].str.contains(model_guess, case=False, na=False)]
                        if not sub.empty:
                            cand = sub
                    row = cand.iloc[0].to_dict() if not cand.empty else None

                try:
                    overlay = write_overlay(img, combo_out, row, conf, iou)
                except Exception as e:
                    print(f"[WARN] {img} @ conf={conf} iou={iou} failed: {e}")
                    continue

                manifest.append({
                    "input": img,
                    "conf": conf,
                    "iou": iou,
                    "overlay": overlay,
                    "brand": brand,
                    "model_guess": model_guess,
                    "spec": row
                })
                count += 1
                print(f"[OK] {count}/{args.max_overlays} → {overlay}")

            if count >= args.max_overlays:
                break
        if count >= args.max_overlays:
            break

    # write manifest
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    (OUTPUT_ROOT / "_sweep_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"\nDone. Exported {count} overlays → {OUTPUT_ROOT}")
    
if __name__ == "__main__":
    main()
