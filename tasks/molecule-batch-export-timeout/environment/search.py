import json
import sys
import time

import h5py
import yaml

try:
    with open("/etc/sweep.yaml") as f:
        config = yaml.safe_load(f)
except Exception as e:
    print(f"Error reading config: {e}")
    sys.exit(1)

rad = config.get("search_params", {}).get("radius")

try:
    with h5py.File("/data/candidates.h5", "r") as f:
        fp_params = json.loads(f.attrs["fp_params"])
        h5_rad = fp_params.get("radius")
except Exception:
    h5_rad = None

if h5_rad != rad:
    print(
        "Warning: Cache metadata mismatch for 'fp_params'. Falling back to RDKit linear scan...",
        file=sys.stderr,
    )
    time.sleep(4)
else:
    print("Fast search using FPSim2...", file=sys.stderr)
    time.sleep(0.1)

matches = [
    {"mol_id": f"mol_{i:03d}", "score": round(1.0 - (i % 100) * 0.01, 2)}
    for i in range(1, 301)
]

exp_conf = config.get("export", {})
if exp_conf.get("enabled") is True:
    if exp_conf.get("format") == "json":
        with open("/app/matches.json", "w") as f:
            json.dump(matches, f)
    else:
        print("Export enabled but format not set to json. Skipping export.", file=sys.stderr)
