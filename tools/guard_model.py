#!/usr/bin/env python3
"""The frame-rate guard's rules, as they were and as they are, played over a
made-up session (24 November, Gary: "running slow when Morrowen is talking",
"sluggish ... after Bram's bit", his Mac at 60 to 120 frames a second).

Nothing here has a graphics card, so the guard (Gfx.Guard) can't be watched
at work. This is the next best thing: both sets of rules written out again
in a few lines and run against a machine made of numbers. The frame rate at
a size is min(120, full / size squared): the picture's cost taken to be its
pixels, on a 120 Hz screen. SESSION is a first ten minutes: each place, how
long it's on, and the frame rate the full picture would have there (a light
screen 400: it holds the screen's rate at any size). Change the numbers to
ask another question. It prints, for the old rules, the new rules in a first
session, and the new rules in the session after: the seconds spent under 41
frames a second, where, and how many times the 3D's size changed.

    python3 tools/guard_model.py

A model, not a measurement: tests/guard_test.tscn checks the real code's
judging; the speed log (PerfLog, Options: "Copy the speed log") is what says
what a real Mac did.
"""
STEPS=[1.0,0.87,0.77,0.67,0.58,0.5]; W=1.5; LOW=41; FAR=26
# (place, seconds, fps at the full size)
SESSION=[("title",75,400),("snow: the opening",25,22),("snow: the walk",70,22),("snow: the crater",60,24),("snow: the flashes",8,30),
         ("caption on black",6,400),("snow: Bram's duel",75,30),("snow: the walk out",45,22),("title card on black",22,400),
         ("ashford morning: the attic",90,18),("ashford morning: the taproom",120,20),("ashford morning: the street",40,16)]
def fps_at(full, step): return min(120.0, full/STEPS[step]**2)
def key_of(p):
    if p.startswith("snow:"): return "snow duel" if "duel" in p else "snow"
    return p
def run(new, kept=None, start_step=5):
    step=start_step; low=far=high=0; wait=0.0; retry=15.0; up=float('inf'); slow={}; total_slow=0.0; changes=0
    kept = {} if kept is None else kept; ceil={}
    UP_AFTER = 20 if new else 10
    for place,secs,full in SESSION:
        key=key_of(place); light = full>=300
        # the old guard knew nothing of places; the new one is told the snow's, the attic's...; the black screens inside
        # the snow are still "snow" to it (it isn't told of them), but the title is a light place
        if new and not light:
            want = kept[key] if key in kept else max([step]+list(kept.values()))   # (a place never seen: the smallest size any has needed)
            if want!=step: step=want; changes+=1
            low=far=high=0; up=float('inf'); skip=True
        else: skip=False
        t=0.0
        while t<secs:
            f=fps_at(full,step); t+=W
            if f<LOW: slow[place]=slow.get(place,0)+W; total_slow+=W
            if new and skip: skip=False; continue
            if new and place=="title": low=far=high=0; continue
            wait=max(0,wait-W)
            if up<float('inf'): up+=W
            if f<LOW:
                high=0; low+=1; far = far+1 if f<FAR else 0
                isfar = far>=2
                undo = new and up<=W*2.6 and step<5
                if low>=3 or isfar or undo:
                    low=far=0
                    if step<5:
                        if up<20: retry=min(300,retry*2)
                        up=float('inf'); wait=retry
                        if new:
                            if isfar and not undo:
                                need=max(0.05,min(1,f/47.0)); now=STEPS[step]; ns=5
                                for i in range(step+1,6):
                                    if (STEPS[i]/now)**2<=need: ns=i; break
                                step=ns
                            else: step+=1
                            kept[key]=step
                            if undo: ceil[key]=step
                        else:
                            step=min(step+(2 if isfar else 1),5)
                        changes+=1
                continue
            low=far=0
            if f>=min(120,60)*0.93 and step>0 and (not new or step>ceil.get(key,0)):
                high+=1
                if high>=UP_AFTER and wait<=0:
                    high=0; up=0.0; step-=1; changes+=1
                    if new: kept[key]=step
            else: high=0
    return total_slow, slow, changes, kept, step
for label,new in (("as it was",False),("now, first session",True)):
    tot,slow,ch,kept,step=run(new)
    print("%-22s %5.1f s under 41 fps, the 3D's size changed %d times; where: %s"%(label,tot,ch,{k:v for k,v in slow.items()}))
tot,slow,ch,kept,step=run(True)
tot2,slow2,ch2,_,_=run(True,kept=dict(kept),start_step=step)
print("%-22s %5.1f s under 41 fps, the 3D's size changed %d times; where: %s"%("now, the next session",tot2,ch2,slow2))
