import shutil
import sys
from pathlib import Path

import cv2

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
cap = cv2.VideoCapture(str(src))
if not cap.isOpened():
    raise SystemExit("cannot open %s" % src)
w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
print("in %sx%s @ %s" % (w, h, fps))
writer = cv2.VideoWriter(str(dst), cv2.VideoWriter_fourcc(*"mp4v"), fps, (w, h))
n = 0
while True:
    ok, frame = cap.read()
    if not ok:
        break
    writer.write(frame)
    n += 1
cap.release()
writer.release()
print("wrote %s frames %.1f MB" % (n, dst.stat().st_size / 1e6))
if len(sys.argv) > 3:
    copy = Path(sys.argv[3])
    shutil.copy2(dst, copy)
    print("copied", copy)
