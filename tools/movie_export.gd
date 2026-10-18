extends Node
## Plays the opening movie on its own and quits when it ends, so Godot's movie
## writer can record it to a video file with its sound:
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
##       --fixed-fps 30 --write-movie /tmp/opening.avi res://tools/movie_export.tscn
##   ffmpeg -i /tmp/opening.avi -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -c:a aac -b:a 192k opening_movie.mp4


func _ready() -> void:
	var m := OpeningMovie.new()
	add_child(m)
	m.finished.connect(func() -> void: get_tree().quit())
