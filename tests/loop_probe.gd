extends SceneTree
## Plays a looping music file through Godot's own decoder and reports where
## the loop actually lands and whether the join has a jump in it, so a
## loop made with tools/music_loop.py can be checked exactly as the game plays it.
##   godot --headless --script res://tests/loop_probe.gd -- <track name> [loop start seconds]
## (the track name is the file in assets/audio/music/; the loop start defaults
## to Music.LOOP_START's entry for it)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var track: String = args[0]
	var path := "res://assets/audio/music/%s.ogg" % track
	var music_script = load("res://scripts/ui/music.gd")
	var loop_off: float = float(args[1]) if args.size() > 1 else float(music_script.LOOP_START.get(track, 0.0))
	var s: AudioStreamOggVorbis = load(path)
	s.loop = true
	s.loop_offset = loop_off
	var length := s.get_length()
	var rate := int(s.get_sampling_rate() if s.has_method("get_sampling_rate") else AudioServer.get_mix_rate())
	# decode the whole file once, straight, to compare against
	var plain: PackedVector2Array = _mix(s, false, 0.0, length + 0.5)
	var looped: PackedVector2Array = _mix(s, true, loop_off, length + 6.0)
	# the seam: where the looped stream stops matching the plain one
	var seam := -1
	var n := mini(plain.size(), looped.size())
	for i in n:
		if absf(plain[i].x - looped[i].x) > 1e-4:
			seam = i
			break
	if seam < 0:
		seam = plain.size()   # the straight play simply ends where the file does
	# where it continues from: find the plain sample run matching the looped stream after the seam
	var probe_at := seam + 2048
	var probe := 4096
	var want_from := int((loop_off - 0.5) * rate)
	var want_to := int((loop_off + 0.5) * rate)
	var best := -1
	var best_err := 1e9
	for j in range(maxi(0, want_from), mini(plain.size() - probe, want_to)):
		var err := 0.0
		for k in range(0, probe, 16):
			err += absf(plain[j + k].x - looped[probe_at + k].x)
		if err < best_err:
			best_err = err
			best = j
	var landed := float(best - 2048) / rate
	var jump := absf(looped[seam].x - looped[seam - 1].x)
	var typical := 0.0
	for i in range(seam - 4800, seam - 1):
		typical = maxf(typical, absf(looped[i + 1].x - looped[i].x))
	print("%s: file %.3f s, loop lands at %.4f s (asked %.4f, %+.1f ms); jump at the join %.3f (biggest jump in the 0.1 s before it %.3f)" % [
		track, length, landed, loop_off, (landed - loop_off) * 1000.0, jump, typical])
	quit()


static func _mix(s: AudioStreamOggVorbis, loop: bool, off: float, seconds: float) -> PackedVector2Array:
	s.loop = loop
	s.loop_offset = off
	var pb := s.instantiate_playback()
	pb.start(0.0)
	var total := int(seconds * AudioServer.get_mix_rate())
	var out := PackedVector2Array()
	while out.size() < total:
		var buf: PackedVector2Array = pb.mix_audio(1.0, mini(4096, total - out.size()))
		if buf.is_empty():
			break
		out.append_array(buf)
	return out
