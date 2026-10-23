// NativeVideoPlayer: plays a video file through the device's own player
// (Apple's AVPlayer on iPhone, iPad and Mac), over the game's view, with the
// device's hardware decoder. Made for Gary's 4K 60 fps films, which the
// engine's own Theora player can't carry: the film is played as he made it.
//
// Used from GDScript (scripts/story/opening_movie.gd):
//
//   if ClassDB.class_exists("NativeVideoPlayer"):
//       var p = ClassDB.instantiate("NativeVideoPlayer")
//       var path: String = p.find_file("opening_4k.mp4")   # in the app bundle
//       if path != "" and p.open(path):
//           p.play()
//           while not p.has_finished() and not p.has_failed():
//               var ev := p.poll()        # TAPPED / SKIP_PRESSED / FINISHED / FAILED since last poll
//               await get_tree().process_frame
//           p.stop()
//
// The picture is shown whole (letterboxed, black either side), covering the
// whole view, with its own sound. A tap on it is reported by poll() (and the
// `tapped` signal), so the game can show Skip (show_skip) and skip on the
// next tap of it (SKIP_PRESSED). set_subtitle draws a line of words at the
// foot for films that need the game's subtitles over them. set_opacity and
// set_volume fade it out. stop() takes it all down again.
//
// On every other platform the class isn't registered (no library for it), so
// the game checks ClassDB.class_exists("NativeVideoPlayer") first.
#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class NativeVideoPlayer : public RefCounted {
	GDCLASS(NativeVideoPlayer, RefCounted)

	// The platform side (an Objective-C object on Apple platforms), opaque here
	// so this header stays plain C++.
	void *impl = nullptr;
	// Which once-only events poll() has already reported (its own bits).
	int reported = 0;

protected:
	static void _bind_methods();

public:
	enum Event {
		EVENT_TAPPED = 1,
		EVENT_SKIP_PRESSED = 2,
		EVENT_FINISHED = 4,
		EVENT_FAILED = 8,
	};

	NativeVideoPlayer();
	~NativeVideoPlayer();

	// True where a native player exists (iOS, iPadOS, macOS).
	bool is_supported() const;
	// The full path of a file shipped loose in the app bundle (next to the
	// game's data: Contents/Resources on a Mac, the bundle root on an iPhone),
	// or "" if it isn't there. Looks next to the executable too.
	String find_file(const String &p_name) const;

	// Opens the file and puts the player over the game's view, paused and
	// black. False (with get_error set) if the file can't be read.
	bool open(const String &p_path);
	void play();
	void pause();
	// Stops and removes the player from the view.
	void stop();

	bool is_open() const;
	// The file has been read far enough to play (status ready).
	bool is_ready() const;
	bool is_playing() const;
	bool has_finished() const;
	bool has_failed() const;
	String get_error() const;

	double get_position() const;
	double get_length() const;
	void seek(double p_seconds);
	// The size of the picture in pixels (0,0 until it's known).
	Vector2 get_video_size() const;

	void set_volume(double p_volume);
	double get_volume() const;
	void set_opacity(double p_opacity);
	void set_visible(bool p_visible);
	bool is_visible() const;

	// A line of words at the foot of the picture ("" takes it down).
	void set_subtitle(const String &p_text);
	// A Skip label at the top right, tapped to skip.
	void show_skip(bool p_show, const String &p_text);

	// Events since the last call, as Event bits; also emits the matching
	// signals. Call once a frame.
	int poll();
};

} // namespace godot

VARIANT_ENUM_CAST(godot::NativeVideoPlayer::Event);
