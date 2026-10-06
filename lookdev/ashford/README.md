# Ashford look test

The night of the Sigilfall, built procedurally to set the lighting and effects
recipe for the story mode: moonlight and the torn sky, volumetric fog and ground
mist, window and lantern light, fire and smoke, the falling Sigils, grass, and
the post-processing (glow, AgX tone mapping, vignette, grain).

Render a still (shots: wide, green, strike, white):

    godot --path . --resolution 1920x1080 res://lookdev/ashford/ashford_look.tscn -- shot=wide frames=24 out=/tmp/wide.png

Record the fly-through as PNG frames:

    godot --path . --resolution 1280x720 --write-movie /tmp/vid/frame.png --fixed-fps 24 res://lookdev/ashford/ashford_flythrough.tscn

The playable Ashford area (scripts/world/areas/ashford.gd) builds on this.
