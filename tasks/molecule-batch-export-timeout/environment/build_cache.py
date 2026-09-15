import argparse
import json
import os

import h5py
import yaml


def build(radius, out_file):
    os.makedirs(os.path.dirname(out_file), exist_ok=True)
    with h5py.File(out_file, "w") as f:
        f.attrs["fp_params"] = json.dumps({"radius": radius, "nBits": 2048})
        f.attrs["rdkit_ver"] = "2023.09.1"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--template", default="/etc/sweep.yaml")
    parser.add_argument("--radius", type=int)
    args = parser.parse_args()

    try:
        with open(args.template) as f:
            config = yaml.safe_load(f)
    except Exception:
        config = {}

    rad = (
        args.radius
        if args.radius is not None
        else config.get("search_params", {}).get("radius", 2)
    )
    build(rad, "/data/candidates.h5")
