extends "res://lookdev/ashford/ashford_look.gd"
## Fly-through for the look test: starts low beside Cinderpup on the green,
## tilts up to the sky and the Sigilfall, then cranes back over the rooftops.

const WARMUP := 12          # frames rendered before the clip starts (fog and AA settle)
var elapsed := 0.0
var keys := [
	# time (s), camera position, look-at point, field of view
	[0.0, Vector3(6.2, 1.0, 11.2), Vector3(2.2, 1.2, 3.8), 46.0],
	[3.0, Vector3(4.6, 1.05, 8.6), Vector3(1.4, 2.2, 0.5), 46.0],
	[6.0, Vector3(6.0, 3.6, 11.5), Vector3(0.5, 9.5, -8.0), 50.0],
	[9.0, Vector3(-12.0, 15.0, 33.0), Vector3(6.0, 12.0, -32.0), 52.0],
	[12.5, Vector3(-50.0, 30.0, 50.0), Vector3(12.0, 22.0, -42.0), 54.0],
]

func _process(delta: float) -> void:
	frame += 1
	elapsed += delta
	for fl in flicker_lights:
		var l: OmniLight3D = fl[0]
		l.light_energy = fl[1] * (0.82 + 0.18 * sin(elapsed * 13.0 + fl[1]) * sin(elapsed * 7.3 + fl[1] * 2.0))
	var t := maxf(0.0, (frame - WARMUP) / 24.0)
	var total: float = keys[keys.size() - 1][0]
	t = minf(t, total)
	var i := 0
	while i < keys.size() - 2 and t > keys[i + 1][0]:
		i += 1
	var k0: Array = keys[max(i - 1, 0)]
	var k1: Array = keys[i]
	var k2: Array = keys[i + 1]
	var k3: Array = keys[min(i + 2, keys.size() - 1)]
	var u: float = (t - float(k1[0])) / (float(k2[0]) - float(k1[0]))
	var pos := cr(k0[1], k1[1], k2[1], k3[1], u)
	var look := cr(k0[2], k1[2], k2[2], k3[2], u)
	var fov := lerpf(k1[3], k2[3], u * u * (3.0 - 2.0 * u))
	set_cam(pos, look, fov, 0.0)
	env.tonemap_exposure = lerpf(1.0, 1.35, smoothstep(6.0, 12.5, t))
	for s in streaks:
		var head: Vector3 = s.head + s.dir * s.speed * 0.35 * (t + 0.0)
		var ground := height(head.x, head.z)
		while head.y < ground:
			head -= s.dir * 200.0
		s.node.global_position = head - s.dir * s.len * 0.5
		s.glow.global_position = head
		if s.light:
			s.light.global_position = head
	white_light.position = Vector3(1.5, 15.0 - t * 0.3, -2.5)
	if frame >= WARMUP + int(total * 24.0) + 1:
		get_tree().quit()

func cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2 := u * u
	var u3 := u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)
