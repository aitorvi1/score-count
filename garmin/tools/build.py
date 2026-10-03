#!/usr/bin/env python3
"""Build declared devices with the official SDK, without Python dependencies."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", type=Path, help="Connect IQ SDK root (or CONNECTIQ_SDK)")
    parser.add_argument("--key", type=Path, required=True, help="RSA developer key in DER format")
    parser.add_argument("--device", help="One declared device; defaults to all manifest products")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--tests", action="store_true", help="Include native Monkey C tests")
    mode.add_argument("--export", action="store_true", help="Export the Store .iq package")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    ns = {"iq": "http://www.garmin.com/xml/connectiq"}
    products = [node.attrib["id"] for node in
                ET.parse(root / "manifest.xml").findall(".//iq:product", ns)]
    if args.device and args.device not in products:
        parser.error(f"Device {args.device!r} is not declared in manifest.xml")
    if args.export and args.device:
        parser.error("Store export includes all manifest products; omit --device")
    key = args.key.expanduser().resolve()
    if not key.is_file():
        parser.error(f"Developer key not found: {key}")
    sdk = args.sdk or os.environ.get("CONNECTIQ_SDK")
    tool_name = "monkeyc.bat" if os.name == "nt" else "monkeyc"
    compiler = str(Path(sdk).expanduser().resolve() / "bin" / tool_name) if sdk else shutil.which(tool_name)
    if not compiler or not Path(compiler).is_file():
        parser.error("Install the SDK and set --sdk, CONNECTIQ_SDK, or PATH")
    (root / "bin").mkdir(exist_ok=True)

    jungle = "monkey.jungle;tests.jungle" if args.tests else "monkey.jungle"
    common = [compiler, "-f", jungle, "-y", str(key), "-w"]
    if args.export:
        subprocess.run(common + ["-e", "-r", "-o", "bin/ScoreCount.iq"], cwd=root, check=True)
        return
    for device in [args.device] if args.device else products:
        prefix = "ScoreCount-tests" if args.tests else "ScoreCount"
        command = common + ["-d", device, "-o", f"bin/{prefix}-{device}.prg"]
        command += ["-t"] if args.tests else ["-r"]
        print(f"Building {device}", flush=True)
        subprocess.run(command, cwd=root, check=True)


if __name__ == "__main__":
    main()
