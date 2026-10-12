#!/usr/bin/env python3
"""Splits a web export's index.pck into parts under GitHub's 100 MB file limit
and patches index.html to download the parts and stitch them back together
before the engine starts. Run by tools/build_web.sh; harmless when the pack
is already small enough.

    python3 tools/split_pack.py build/web [part size in bytes]
"""
import json
import os
import re
import sys

web = sys.argv[1] if len(sys.argv) > 1 else "build/web"
part_size = int(sys.argv[2]) if len(sys.argv) > 2 else 90_000_000
pck = os.path.join(web, "index.pck")
html = os.path.join(web, "index.html")
size = os.path.getsize(pck)
if size <= part_size:
    print("index.pck is %.1f MB, no split needed" % (size / 1048576))
    sys.exit(0)

parts = []
with open(pck, "rb") as f:
    i = 0
    while True:
        chunk = f.read(part_size)
        if not chunk:
            break
        name = "index.pck.part%d" % i
        with open(os.path.join(web, name), "wb") as out:
            out.write(chunk)
        parts.append([name, len(chunk)])
        i += 1
os.remove(pck)

page = open(html).read()
m = re.search(r"const GODOT_CONFIG = (\{.*?\});", page)
cfg = json.loads(m.group(1))
cfg["packParts"] = parts
cfg["fileSizes"].pop("index.pck", None)
page = page.replace(m.group(0), "const GODOT_CONFIG = %s;" % json.dumps(cfg))

start_old = re.search(r"\t\tengine\.startGame\(\{.*?\}\)\.then\(\(\) => \{\n\t\t\tsetStatusMode\('hidden'\);\n\t\t\}, displayFailureNotice\);", page, re.S)
assert start_old, "index.html's startGame block has changed; update tools/split_pack.py"
start_new = """\t\tconst onProgress = function (current, total) {
\t\t\tif (current > 0 && total > 0) {
\t\t\t\tstatusProgress.value = current;
\t\t\t\tstatusProgress.max = total;
\t\t\t} else {
\t\t\t\tstatusProgress.removeAttribute('value');
\t\t\t\tstatusProgress.removeAttribute('max');
\t\t\t}
\t\t};
\t\t// The pack is split into parts (GitHub Pages won't serve a file over 100 MB):
\t\t// download them in turn, stitch them together, and hand the engine one pack.
\t\tconst PARTS = GODOT_CONFIG['packParts'];
\t\tconst total = PARTS.reduce((a, p) => a + p[1], 0);
\t\tlet loaded = 0;
\t\tconst chunks = [];
\t\tconst fetchPart = function (i) {
\t\t\tif (i >= PARTS.length) {
\t\t\t\treturn Promise.resolve();
\t\t\t}
\t\t\treturn fetch(PARTS[i][0]).then(function (r) {
\t\t\t\tif (!r.ok) {
\t\t\t\t\tthrow new Error('Failed loading file ' + PARTS[i][0]);
\t\t\t\t}
\t\t\t\tconst reader = r.body.getReader();
\t\t\t\tconst pump = function () {
\t\t\t\t\treturn reader.read().then(function (res) {
\t\t\t\t\t\tif (res.done) {
\t\t\t\t\t\t\treturn Promise.resolve();
\t\t\t\t\t\t}
\t\t\t\t\t\tchunks.push(res.value);
\t\t\t\t\t\tloaded += res.value.length;
\t\t\t\t\t\tonProgress(loaded, total);
\t\t\t\t\t\treturn pump();
\t\t\t\t\t});
\t\t\t\t};
\t\t\t\treturn pump();
\t\t\t}).then(function () {
\t\t\t\treturn fetchPart(i + 1);
\t\t\t});
\t\t};
\t\tPromise.all([engine.init(GODOT_CONFIG['executable']), fetchPart(0)]).then(function () {
\t\t\tconst pack = new Uint8Array(chunks.reduce((a, c) => a + c.length, 0));
\t\t\tlet at = 0;
\t\t\tchunks.forEach(function (c) {
\t\t\t\tpack.set(c, at);
\t\t\t\tat += c.length;
\t\t\t});
\t\t\tchunks.length = 0;
\t\t\treturn engine.preloadFile(pack, 'index.pck');
\t\t}).then(function () {
\t\t\treturn engine.start({ 'args': ['--main-pack', 'index.pck'].concat(GODOT_CONFIG['args']) });
\t\t}).then(() => {
\t\t\tsetStatusMode('hidden');
\t\t}, displayFailureNotice);"""
page = page.replace(start_old.group(0), start_new)
open(html, "w").write(page)

sw = os.path.join(web, "index.service.worker.js")
if os.path.exists(sw):
    s = open(sw).read()
    s = s.replace('"index.pck"', ",".join('"%s"' % p[0] for p in parts))
    open(sw, "w").write(s)
print("split index.pck (%.1f MB) into %d parts; index.html patched" % (size / 1048576, len(parts)))
