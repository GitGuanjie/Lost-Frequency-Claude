"""Fetch the CC0 Poly Haven texture sets listed in assets/external/manifest.json.

    python3 -I tools/fetch_assets.py

Writes assets/external/<asset>/<asset>_{diff,nor_gl,arm}_1k.jpg and records
author, licence, source URL and sha256 in assets/external/lock.json (committed),
so builds are reproducible and attributable. Files themselves stay out of Git.
"""
import hashlib
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXT = ROOT / "assets" / "external"
UA = {"User-Agent": "LostFrequencyAssetFetch/1.0"}
MAPS = {"diff": "Diffuse", "nor_gl": "nor_gl", "arm": "arm"}


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120) as r:
        return r.read()


def main():
    man = json.loads((EXT / "manifest.json").read_text())
    res = man["resolution"]
    lock_p = EXT / "lock.json"
    lock = json.loads(lock_p.read_text()) if lock_p.exists() else {}
    for asset in sorted({m["asset"] for m in man["materials"].values()}):
        info = json.loads(get(f"https://api.polyhaven.com/info/{asset}"))
        files = json.loads(get(f"https://api.polyhaven.com/files/{asset}"))
        rec = {"source": f"https://polyhaven.com/a/{asset}", "license": "CC0 1.0",
               "authors": sorted((info.get("authors") or {}).keys()), "files": {}}
        out = EXT / asset
        out.mkdir(parents=True, exist_ok=True)
        for short, key in MAPS.items():
            url = files[key][res]["jpg"]["url"]
            dst = out / f"{asset}_{short}_{res}.jpg"
            want = lock.get(asset, {}).get("files", {}).get(short, {}).get("sha256")
            if not dst.exists():
                dst.write_bytes(get(url))
            h = hashlib.sha256(dst.read_bytes()).hexdigest()
            if want and want != h:
                raise SystemExit(f"hash mismatch for {dst.name}: upstream changed; review before updating lock.json")
            rec["files"][short] = {"url": url, "sha256": h, "bytes": dst.stat().st_size}
        lock[asset] = rec
        print("ok", asset, rec["authors"])
    lock_p.write_text(json.dumps(lock, indent=1, sort_keys=True) + "\n")


if __name__ == "__main__":
    main()
