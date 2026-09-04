#!/usr/bin/env python3
"""Generate docs/assets/repo-qr.png for the talk slide.

The project has no git remote yet, so the URL is an argument:

    python3 -m venv .venv && .venv/bin/pip install qrcode[pil]
    .venv/bin/python docs/assets/make_qr.py https://github.com/you/fcl_2026_demo
"""

import sys
from pathlib import Path

import qrcode
from qrcode.constants import ERROR_CORRECT_M

if len(sys.argv) != 2 or not sys.argv[1].startswith("https://"):
    sys.exit("usage: make_qr.py <https repo url>")

url = sys.argv[1]
qr = qrcode.QRCode(error_correction=ERROR_CORRECT_M, box_size=40, border=4)
qr.add_data(url)
qr.make(fit=True)
image = qr.make_image(fill_color="black", back_color="white")

out = Path(__file__).parent / "repo-qr.png"
image.save(out)
print(f"encoded url: {url}")
print(f"saved {out} at {image.size[0]}x{image.size[1]}")
