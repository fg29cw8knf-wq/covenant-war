#!/usr/bin/env python3
"""What the body sweep found (tools/body_sweep.sh), in one place.

    python3 tools/body_report.py <sweep_dir>

Reads every <run>.log's BODY: and BODY-END: lines, puts the same finding
seen in several looks together (the player's own are kept apart by look),
and writes:
  <sweep_dir>/report.md       every finding: what, who, when (the line on
                              screen), in which runs, how bad at worst, its stills
  <sweep_dir>/sheet_NN.png    contact sheets: the game's picture and the close
                              look side by side, labelled, for looking at
"""
import os
import re
import sys
from collections import OrderedDict

LINE = re.compile(r"^BODY: (\S+)\s+f(\d+)\s+(.*?)\s+\[(.*)\]\s*$")
END = re.compile(r"^BODY-END: (\S+)\s+f(\d+)-(\d+) (\S+) (.*?): worst (.*)$")


def main(d):
    runs = sorted(f[:-4] for f in os.listdir(d) if f.endswith(".log"))
    found = OrderedDict()
    for run in runs:
        starts = []
        for raw in open(os.path.join(d, run + ".log"), errors="replace"):
            raw = raw.rstrip("\n")
            m = LINE.match(raw)
            if m:
                kind, f0, text, ctx = m.group(1), int(m.group(2)), m.group(3), m.group(4)
                who = text.split("'s ")[0] if "'s " in text else text.split(",")[0]
                # what it is, without the numbers (so the same thing matches
                # across looks and runs)
                what = re.sub(r"[-\d.]+ ?(cm|deg)?", "#", text)
                what = re.sub(r", clip \S+$", "", what)
                key = (kind, what, ctx)
                still = None
                e = found.setdefault(key, {"kind": kind, "who": who, "text": text, "ctx": ctx, "runs": [], "frames": [],
                                           "worst": text, "still": None, "close": None})
                e["runs"].append(run)
                e["frames"].append(f0)
                starts.append(key)
                continue
            if raw.startswith("BODY-STILL: ") and starts:
                e = found[starts[-1]]
                still = os.path.join(run, "body", raw[12:].strip())
                if not e["still"]:
                    e["still"] = still
                    c = still[:-4] + "_close.png"
                    if os.path.exists(os.path.join(d, c)):
                        e["close"] = c
                continue
            m = END.match(raw)
            if m:
                # the worst of it, onto the latest finding of that kind and who
                for key in reversed(starts):
                    e = found[key]
                    if e["kind"] == m.group(1) and e["who"] == m.group(4):
                        e["worst"] = m.group(6)
                        e.setdefault("span", []).append("%s f%s-%s" % (run, m.group(2), m.group(3)))
                        break
    with open(os.path.join(d, "report.md"), "w") as out:
        out.write("# Body sweep: %d findings over %d runs (%s)\n\n" % (len(found), len(runs), ", ".join(runs)))
        by_kind = OrderedDict()
        for e in found.values():
            by_kind.setdefault(e["kind"], []).append(e)
        for kind, es in by_kind.items():
            out.write("## %s (%d)\n\n" % (kind, len(es)))
            for e in es:
                out.write("- **%s** — on screen: \"%s\"\n  - runs: %s; worst: %s%s\n" % (
                    e["text"], e["ctx"], ", ".join("%s f%d" % (r, f) for r, f in zip(e["runs"], e["frames"])),
                    e["worst"], ("\n  - still: " + e["still"]) if e["still"] else ""))
            out.write("\n")
    sheets(d, [e for e in found.values() if e["still"]])
    print("%d findings; %s" % (len(found), os.path.join(d, "report.md")))


def sheets(d, es):
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        return
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
    except Exception:
        font = ImageFont.load_default()
    per = 4
    W, H, CW = 640, 360, 480
    for n in range(0, len(es), per):
        sheet = Image.new("RGB", (W + CW, per * (H + 44)), (24, 24, 24))
        dr = ImageDraw.Draw(sheet)
        for i, e in enumerate(es[n:n + per]):
            y = i * (H + 44)
            try:
                im = Image.open(os.path.join(d, e["still"])).convert("RGB").resize((W, H))
                sheet.paste(im, (0, y + 44))
            except Exception:
                pass
            if e["close"]:
                try:
                    im = Image.open(os.path.join(d, e["close"])).convert("RGB")
                    im = im.resize((CW, int(CW * im.height / im.width)))
                    sheet.paste(im.crop((0, 0, CW, H)), (W, y + 44))
                except Exception:
                    pass
            dr.text((6, y + 4), "%d. %s" % (n + i + 1, e["text"][:150]), fill=(255, 220, 120), font=font)
            dr.text((6, y + 23), "%s | %s" % (", ".join(sorted(set(e["runs"])))[:60], e["ctx"][:90]), fill=(200, 200, 200), font=font)
        sheet.save(os.path.join(d, "sheet_%02d.png" % (n // per + 1)))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/tmp/body_sweep")
