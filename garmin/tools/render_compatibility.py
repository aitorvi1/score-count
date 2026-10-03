#!/usr/bin/env python3
"""Capture one production release per shape/resolution/policy in an X11 simulator.

Requires Pillow, libX11, libXtst and an already running Connect IQ simulator.
Waits for isolated builds produced by validate_compatibility.py.
"""
import argparse
import ctypes as C
import ctypes.util
import json
import hashlib
from pathlib import Path
import subprocess
import time

from PIL import ImageGrab
from verify_targets import ROOT


class Desktop:
    def __init__(self):
        self.x = C.CDLL(ctypes.util.find_library('X11'))
        self.t = C.CDLL(ctypes.util.find_library('Xtst'))
        self.x.XOpenDisplay.argtypes = [C.c_char_p]
        self.x.XOpenDisplay.restype = C.c_void_p
        self.d = self.x.XOpenDisplay(None)
        if not self.d:
            raise RuntimeError('X11 display is unavailable')
        self.x.XDefaultRootWindow.argtypes = [C.c_void_p]
        self.x.XDefaultRootWindow.restype = C.c_ulong
        self.root = self.x.XDefaultRootWindow(self.d)
        self.x.XQueryTree.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(C.c_ulong), C.POINTER(C.c_ulong), C.POINTER(C.POINTER(C.c_ulong)), C.POINTER(C.c_uint)]
        self.x.XFetchName.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(C.c_char_p)]
        self.x.XTranslateCoordinates.argtypes = [C.c_void_p, C.c_ulong, C.c_ulong, C.c_int, C.c_int, C.POINTER(C.c_int), C.POINTER(C.c_int), C.POINTER(C.c_ulong)]
        self.x.XGetGeometry.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(C.c_ulong), C.POINTER(C.c_int), C.POINTER(C.c_int), C.POINTER(C.c_uint), C.POINTER(C.c_uint), C.POINTER(C.c_uint), C.POINTER(C.c_uint)]
        self.x.XFree.argtypes = [C.c_void_p]
        self.x.XFlush.argtypes = [C.c_void_p]
        self.t.XTestFakeMotionEvent.argtypes = [C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_ulong]
        self.t.XTestFakeButtonEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]

    def windows(self, parent):
        root, owner = C.c_ulong(), C.c_ulong()
        children, count = C.POINTER(C.c_ulong)(), C.c_uint()
        self.x.XQueryTree(self.d, parent, C.byref(root), C.byref(owner), C.byref(children), C.byref(count))
        ids = [children[i] for i in range(count.value)]
        if children:
            self.x.XFree(children)
        for child in ids:
            name = C.c_char_p()
            self.x.XFetchName(self.d, child, C.byref(name))
            title = name.value.decode(errors='replace') if name.value else ''
            if name:
                self.x.XFree(name)
            if 'CIQ Simulator' in title:
                yield child, title
            yield from self.windows(child)

    def client(self):
        windows = list(self.windows(self.root))
        if not windows:
            raise RuntimeError('CIQ Simulator window is unavailable')
        return next((window for window, title in windows if title == 'CIQ Simulator'), windows[-1][0])

    def bounds(self):
        window = self.client()
        a, b, child = C.c_int(), C.c_int(), C.c_ulong()
        self.x.XTranslateCoordinates(self.d, window, self.root, 0, 0, C.byref(a), C.byref(b), C.byref(child))
        root, xx, yy = C.c_ulong(), C.c_int(), C.c_int()
        width, height, border, depth = C.c_uint(), C.c_uint(), C.c_uint(), C.c_uint()
        self.x.XGetGeometry(self.d, window, C.byref(root), C.byref(xx), C.byref(yy), C.byref(width), C.byref(height), C.byref(border), C.byref(depth))
        return a.value, b.value, width.value, height.value

    def click(self, x, y, seconds=.18):
        a, b, _, _ = self.bounds()
        self.t.XTestFakeMotionEvent(self.d, -1, a + int(x), b + 27 + int(y), 0)
        self.t.XTestFakeButtonEvent(self.d, 1, 1, 0)
        self.x.XFlush(self.d)
        time.sleep(seconds)
        self.t.XTestFakeButtonEvent(self.d, 1, 0, 0)
        self.x.XFlush(self.d)
        time.sleep(.4)

    def capture(self, file):
        a, b, width, height = self.bounds()
        ImageGrab.grab(bbox=(a, b, a + width, b + height)).save(file)


def group(row):
    return f"{row['shape']}|{row['width']}x{row['height']}|{row['policy']}"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--profiles', type=Path, default=Path.home() / '.Garmin/ConnectIQ/Devices')
    parser.add_argument('--output', type=Path, default=ROOT / 'bin/compatibility118')
    args = parser.parse_args()
    args.sdk, args.output = args.sdk.resolve(), args.output.resolve()
    if not args.output.is_relative_to(ROOT / 'bin'):
        parser.error('Artifacts must remain under garmin/bin/.')
    targets = json.loads((ROOT / 'compatibility/targets.json').read_text())
    pending = {group(row) for row in targets}
    capturefile = args.output / 'renders.json'
    captures = json.loads(capturefile.read_text()) if capturefile.exists() else {}
    for key, row in list(captures.items()):
        binary = args.output / f"projects/{row['product_id']}/bin/ScoreCount-release-{row['product_id']}.prg"
        if not binary.exists() or hashlib.sha256(binary.read_bytes()).hexdigest() != row.get('release_sha256'):
            del captures[key]
    pending -= set(captures)
    desktop = Desktop()
    (args.output / 'renders').mkdir(exist_ok=True)
    deadline = time.monotonic() + 1800
    processes = []
    while pending:
        if time.monotonic() > deadline:
            raise RuntimeError(f'Missing render groups: {sorted(pending)}')
        resultfile = args.output / 'results.json'
        results = json.loads(resultfile.read_text()) if resultfile.exists() else {}
        candidates = [row for row in targets if group(row) in pending and
                      results.get(row['product_id'], {}).get('compile_release', {}).get('ok')]
        if not candidates:
            time.sleep(1)
            continue
        row = candidates[0]
        id = row['product_id']
        project = args.output / 'projects' / id
        profile = json.loads((args.profiles / id / 'simulator.json').read_text())
        log = (args.output / f'renders/{id}.log').open('w')
        process = subprocess.Popen([str(args.sdk / 'bin/monkeydo'), str(project / f'bin/ScoreCount-release-{id}.prg'), id], stdout=log, stderr=subprocess.STDOUT)
        processes.append((process, log))
        time.sleep(12)
        loc = profile['display']['location']
        def key(key_id, duration=.18):
            rect = next(key['location'] for key in profile['keys'] if key['id'] == key_id)
            desktop.click(rect['x'] + rect['width'] / 2, rect['y'] + rect['height'] / 2, duration)
        def tap(x, y):
            desktop.click(loc['x'] + loc['width'] * x, loc['y'] + loc['height'] * y)
        if row['policy'] == 'FULL_PHYSICAL':
            key('enter', 1.8)
            key('up')
            key('down')
        else:
            tap(.5, .8)
            tap(.27, .45)
            tap(.72, .45)
        file = args.output / f'renders/{id}.png'
        desktop.capture(file)
        captures[group(row)] = dict(product_id=id, shape=row['shape'], width=row['width'], height=row['height'],
                                    policy=row['policy'], image=str(file.relative_to(args.output)),
                                    screen_origin=[loc['x'], loc['y'] + 27], visual_review='pending',
                                    release_sha256=hashlib.sha256((project / f'bin/ScoreCount-release-{id}.prg').read_bytes()).hexdigest())
        (args.output / 'renders.json').write_text(json.dumps(captures, indent=2) + '\n')
        pending.remove(group(row))
        print(f'{len(captures)}/20 {group(row)}: {id}', flush=True)
    for process, log in processes[:-1]:
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.terminate()
        log.close()
    print('All geometry/policy groups captured; visual review still required.', flush=True)


if __name__ == '__main__':
    main()
