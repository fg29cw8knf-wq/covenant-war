// NativeVideoPlayer on Apple platforms: AVPlayer in a view laid over the
// game's own view (the one DisplayServer hands out as WINDOW_VIEW), so the
// film is decoded by the device's hardware and drawn by the system, at its
// full size and frame rate. See native_video_player.h for the API.
//
// Built as Objective-C++ with ARC. The Objective-C state (player, views,
// flags) lives in NVPlayerState, held by the C++ object through an opaque
// pointer; AVPlayer's notifications set flags on it from the main queue, and
// the game reads them with poll() each frame, so nothing of Godot's is
// touched from inside a system callback.

#include "native_video_player.h"

#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
typedef UIView NVView;
typedef UILabel NVLabel;
typedef UIColor NVColor;
typedef UIFont NVFont;
#else
#import <AppKit/AppKit.h>
typedef NSView NVView;
typedef NSTextField NVLabel;
typedef NSColor NVColor;
typedef NSFont NVFont;
#endif

using namespace godot;

// ------------------------------------------------------------------ views ---

// The view whose layer is the AVPlayerLayer: it fills the overlay and the
// layer follows it, so the picture is laid out by the system on every
// resize and rotation.
@interface NVPlayerHostView : NVView
@property(nonatomic, readonly) AVPlayerLayer *playerLayer;
@end

@implementation NVPlayerHostView

#if TARGET_OS_IPHONE
+ (Class)layerClass {
	return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
	return (AVPlayerLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.userInteractionEnabled = NO;
		self.backgroundColor = [UIColor blackColor];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
		self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
	}
	return self;
}
#else
{
	AVPlayerLayer *_layer;
}

- (AVPlayerLayer *)playerLayer {
	return _layer;
}

- (instancetype)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		_layer = [AVPlayerLayer layer];
		_layer.videoGravity = AVLayerVideoGravityResizeAspect;
		_layer.backgroundColor = [NSColor blackColor].CGColor;
		// the layer set before wantsLayer makes this a layer-hosting view: the
		// player layer is the view's own layer and is sized with it
		self.layer = _layer;
		self.wantsLayer = YES;
		self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	}
	return self;
}

- (NSView *)hitTest:(NSPoint)point {
	return nil; // clicks go to the overlay behind the labels
}
#endif

@end

// The black overlay over the game: the player, the subtitle, the Skip label,
// and the taps. It covers the whole game view and takes every touch, so
// nothing underneath is pressed while the film plays.
@interface NVOverlayView : NVView
@property(nonatomic, strong) NVPlayerHostView *host;
@property(nonatomic, strong) NVLabel *subtitle;
@property(nonatomic, strong) NVLabel *skip;
@property(nonatomic, copy) void (^onTap)(BOOL onSkip);
- (void)setSubtitleText:(NSString *)text;
- (void)setSkipText:(NSString *)text shown:(BOOL)shown;
- (void)placeLabels;
@end

@implementation NVOverlayView

static const CGFloat NV_MARGIN = 28.0;

#if TARGET_OS_IPHONE

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor blackColor];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.userInteractionEnabled = YES;
		self.multipleTouchEnabled = NO;

		_host = [[NVPlayerHostView alloc] initWithFrame:self.bounds];
		[self addSubview:_host];

		_subtitle = [[UILabel alloc] initWithFrame:CGRectZero];
		_subtitle.numberOfLines = 0;
		_subtitle.textAlignment = NSTextAlignmentCenter;
		_subtitle.textColor = [UIColor colorWithWhite:1.0 alpha:0.95];
		_subtitle.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightMedium];
		_subtitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.9];
		_subtitle.shadowOffset = CGSizeMake(0.0, 1.5);
		_subtitle.backgroundColor = [UIColor clearColor];
		_subtitle.hidden = YES;
		[self addSubview:_subtitle];

		_skip = [[UILabel alloc] initWithFrame:CGRectZero];
		_skip.textAlignment = NSTextAlignmentCenter;
		_skip.textColor = [UIColor colorWithRed:0.93 green:0.80 blue:0.47 alpha:1.0]; // the game's gold
		_skip.font = [UIFont systemFontOfSize:19.0 weight:UIFontWeightSemibold];
		_skip.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
		_skip.layer.cornerRadius = 10.0;
		_skip.layer.masksToBounds = YES;
		_skip.layer.borderColor = [UIColor colorWithRed:0.93 green:0.80 blue:0.47 alpha:0.7].CGColor;
		_skip.layer.borderWidth = 1.0;
		_skip.text = @"Skip";
		_skip.hidden = YES;
		[self addSubview:_skip];

		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nvTapped:)];
		tap.cancelsTouchesInView = YES;
		[self addGestureRecognizer:tap];
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self placeLabels];
}

- (void)nvTapped:(UITapGestureRecognizer *)g {
	if (g.state != UIGestureRecognizerStateEnded) {
		return;
	}
	CGPoint p = [g locationInView:self];
	BOOL onSkip = !self.skip.hidden && CGRectContainsPoint(CGRectInset(self.skip.frame, -24.0, -24.0), p);
	if (self.onTap) {
		self.onTap(onSkip);
	}
}

- (void)placeLabels {
	CGRect b = self.bounds;
	UIEdgeInsets in = UIEdgeInsetsZero;
	if (@available(iOS 11.0, *)) {
		in = self.safeAreaInsets;
	}
	// Skip: top right, clear of the Dynamic Island and the corner
	[self.skip sizeToFit];
	CGSize ss = CGSizeMake(MAX(self.skip.bounds.size.width + 44.0, 110.0), self.skip.bounds.size.height + 18.0);
	self.skip.frame = CGRectMake(b.size.width - in.right - NV_MARGIN - ss.width, in.top + NV_MARGIN * 0.75, ss.width, ss.height);
	// the subtitle: along the foot, inside the home bar's space
	CGFloat w = b.size.width * 0.84;
	CGSize fit = [self.subtitle sizeThatFits:CGSizeMake(w, 400.0)];
	self.subtitle.frame = CGRectMake((b.size.width - w) * 0.5, b.size.height - in.bottom - NV_MARGIN - fit.height, w, fit.height);
}

- (void)setSubtitleText:(NSString *)text {
	self.subtitle.text = text;
	self.subtitle.hidden = (text.length == 0);
	[self placeLabels];
}

- (void)setSkipText:(NSString *)text shown:(BOOL)shown {
	if (text.length > 0) {
		self.skip.text = text;
	}
	self.skip.hidden = !shown;
	[self placeLabels];
}

#else // macOS

- (instancetype)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.wantsLayer = YES;
		self.layer.backgroundColor = [NSColor blackColor].CGColor;
		self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

		_host = [[NVPlayerHostView alloc] initWithFrame:self.bounds];
		[self addSubview:_host];

		_subtitle = [NSTextField wrappingLabelWithString:@""];
		_subtitle.alignment = NSTextAlignmentCenter;
		_subtitle.textColor = [NSColor colorWithWhite:1.0 alpha:0.95];
		_subtitle.font = [NSFont systemFontOfSize:26.0 weight:NSFontWeightMedium];
		_subtitle.drawsBackground = NO;
		_subtitle.bezeled = NO;
		_subtitle.editable = NO;
		_subtitle.selectable = NO;
		NSShadow *sh = [[NSShadow alloc] init];
		sh.shadowColor = [NSColor colorWithWhite:0.0 alpha:0.9];
		sh.shadowOffset = NSMakeSize(0.0, -1.5);
		sh.shadowBlurRadius = 3.0;
		_subtitle.shadow = sh;
		_subtitle.hidden = YES;
		[self addSubview:_subtitle];

		_skip = [NSTextField labelWithString:@"Skip"];
		_skip.alignment = NSTextAlignmentCenter;
		_skip.textColor = [NSColor colorWithRed:0.93 green:0.80 blue:0.47 alpha:1.0];
		_skip.font = [NSFont systemFontOfSize:20.0 weight:NSFontWeightSemibold];
		_skip.drawsBackground = NO;
		_skip.bezeled = NO;
		_skip.editable = NO;
		_skip.selectable = NO;
		_skip.wantsLayer = YES;
		_skip.layer.backgroundColor = [NSColor colorWithWhite:0.0 alpha:0.55].CGColor;
		_skip.layer.cornerRadius = 10.0;
		_skip.layer.borderColor = [NSColor colorWithRed:0.93 green:0.80 blue:0.47 alpha:0.7].CGColor;
		_skip.layer.borderWidth = 1.0;
		_skip.hidden = YES;
		[self addSubview:_skip];
	}
	return self;
}

- (BOOL)isFlipped {
	return YES; // top-left origin, as on the phone
}

- (BOOL)acceptsFirstResponder {
	return NO; // the keys stay with the game's view
}

- (void)layout {
	[super layout];
	[self placeLabels];
}

- (void)mouseDown:(NSEvent *)event {
	NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
	BOOL onSkip = !self.skip.hidden && NSPointInRect(p, NSInsetRect(self.skip.frame, -24.0, -24.0));
	if (self.onTap) {
		self.onTap(onSkip);
	}
}

- (void)placeLabels {
	NSRect b = self.bounds;
	[self.skip sizeToFit];
	NSSize ss = NSMakeSize(MAX(self.skip.frame.size.width + 44.0, 110.0), self.skip.frame.size.height + 18.0);
	self.skip.frame = NSMakeRect(b.size.width - NV_MARGIN - ss.width, NV_MARGIN * 0.75, ss.width, ss.height);
	CGFloat w = b.size.width * 0.84;
	self.subtitle.preferredMaxLayoutWidth = w;
	NSSize fit = [self.subtitle.cell cellSizeForBounds:NSMakeRect(0, 0, w, 400.0)];
	self.subtitle.frame = NSMakeRect((b.size.width - w) * 0.5, b.size.height - NV_MARGIN - fit.height, w, fit.height);
}

- (void)setSubtitleText:(NSString *)text {
	self.subtitle.stringValue = text;
	self.subtitle.hidden = (text.length == 0);
	[self placeLabels];
}

- (void)setSkipText:(NSString *)text shown:(BOOL)shown {
	if (text.length > 0) {
		self.skip.stringValue = text;
	}
	self.skip.hidden = !shown;
	[self placeLabels];
}

#endif

@end

// ------------------------------------------------------------------ state ---

// Everything the player owns, and the flags the system sets for poll().
@interface NVPlayerState : NSObject
@property(nonatomic, strong) AVPlayer *player;
@property(nonatomic, strong) AVPlayerItem *item;
@property(nonatomic, strong) NVOverlayView *overlay;
@property(nonatomic, strong) id endObserver;
@property(nonatomic, strong) id failObserver;
@property(atomic, assign) BOOL ended;
@property(atomic, assign) BOOL failed;
@property(atomic, assign) int taps;
@property(atomic, assign) int skips;
@property(atomic, assign) BOOL playing;
@property(atomic, assign) float volume;
@property(nonatomic, copy) NSString *error;
- (void)tearDown;
@end

@implementation NVPlayerState

- (void)tearDown {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (self.endObserver) {
		[nc removeObserver:self.endObserver];
		self.endObserver = nil;
	}
	if (self.failObserver) {
		[nc removeObserver:self.failObserver];
		self.failObserver = nil;
	}
	if (self.player) {
		[self.player pause];
		self.player = nil;
	}
	if (self.overlay) {
		self.overlay.host.playerLayer.player = nil;
		self.overlay.onTap = nil;
		[self.overlay removeFromSuperview];
		self.overlay = nil;
	}
	self.item = nil;
	self.playing = NO;
}

@end

// -------------------------------------------------------------- the class ---

static inline NVPlayerState *nv_state(void *p_impl) {
	return (__bridge NVPlayerState *)p_impl;
}

static inline NSString *nv_ns(const String &p_s) {
	CharString u = p_s.utf8();
	return [NSString stringWithUTF8String:u.get_data() ? u.get_data() : ""];
}

static inline String nv_gd(NSString *p_s) {
	return String::utf8(p_s ? [p_s UTF8String] : "");
}

void NativeVideoPlayer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_supported"), &NativeVideoPlayer::is_supported);
	ClassDB::bind_method(D_METHOD("find_file", "name"), &NativeVideoPlayer::find_file);

	ClassDB::bind_method(D_METHOD("open", "path"), &NativeVideoPlayer::open);
	ClassDB::bind_method(D_METHOD("play"), &NativeVideoPlayer::play);
	ClassDB::bind_method(D_METHOD("pause"), &NativeVideoPlayer::pause);
	ClassDB::bind_method(D_METHOD("stop"), &NativeVideoPlayer::stop);

	ClassDB::bind_method(D_METHOD("is_open"), &NativeVideoPlayer::is_open);
	ClassDB::bind_method(D_METHOD("is_ready"), &NativeVideoPlayer::is_ready);
	ClassDB::bind_method(D_METHOD("is_playing"), &NativeVideoPlayer::is_playing);
	ClassDB::bind_method(D_METHOD("has_finished"), &NativeVideoPlayer::has_finished);
	ClassDB::bind_method(D_METHOD("has_failed"), &NativeVideoPlayer::has_failed);
	ClassDB::bind_method(D_METHOD("get_error"), &NativeVideoPlayer::get_error);

	ClassDB::bind_method(D_METHOD("get_position"), &NativeVideoPlayer::get_position);
	ClassDB::bind_method(D_METHOD("get_length"), &NativeVideoPlayer::get_length);
	ClassDB::bind_method(D_METHOD("seek", "seconds"), &NativeVideoPlayer::seek);
	ClassDB::bind_method(D_METHOD("get_video_size"), &NativeVideoPlayer::get_video_size);

	ClassDB::bind_method(D_METHOD("set_volume", "volume"), &NativeVideoPlayer::set_volume);
	ClassDB::bind_method(D_METHOD("get_volume"), &NativeVideoPlayer::get_volume);
	ClassDB::bind_method(D_METHOD("set_opacity", "opacity"), &NativeVideoPlayer::set_opacity);
	ClassDB::bind_method(D_METHOD("set_visible", "visible"), &NativeVideoPlayer::set_visible);
	ClassDB::bind_method(D_METHOD("is_visible"), &NativeVideoPlayer::is_visible);

	ClassDB::bind_method(D_METHOD("set_subtitle", "text"), &NativeVideoPlayer::set_subtitle);
	ClassDB::bind_method(D_METHOD("show_skip", "show", "text"), &NativeVideoPlayer::show_skip, DEFVAL(String("Skip")));

	ClassDB::bind_method(D_METHOD("poll"), &NativeVideoPlayer::poll);

	ADD_SIGNAL(MethodInfo("tapped"));
	ADD_SIGNAL(MethodInfo("skip_pressed"));
	ADD_SIGNAL(MethodInfo("finished"));
	ADD_SIGNAL(MethodInfo("failed", PropertyInfo(Variant::STRING, "error")));

	BIND_ENUM_CONSTANT(EVENT_TAPPED);
	BIND_ENUM_CONSTANT(EVENT_SKIP_PRESSED);
	BIND_ENUM_CONSTANT(EVENT_FINISHED);
	BIND_ENUM_CONSTANT(EVENT_FAILED);
}

NativeVideoPlayer::NativeVideoPlayer() {
	NVPlayerState *state = [[NVPlayerState alloc] init];
	state.volume = 1.0f;
	impl = (void *)CFBridgingRetain(state);
}

NativeVideoPlayer::~NativeVideoPlayer() {
	if (impl) {
		NVPlayerState *state = (NVPlayerState *)CFBridgingRelease(impl);
		[state tearDown];
		impl = nullptr;
	}
}

bool NativeVideoPlayer::is_supported() const {
	return true;
}

String NativeVideoPlayer::find_file(const String &p_name) const {
	@autoreleasepool {
		NSString *name = nv_ns(p_name);
		if (name.length == 0) {
			return String();
		}
		NSFileManager *fm = [NSFileManager defaultManager];
		NSMutableArray<NSString *> *candidates = [NSMutableArray array];
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *inBundle = [bundle pathForResource:[name stringByDeletingPathExtension] ofType:[name pathExtension]];
		if (inBundle) {
			[candidates addObject:inBundle];
		}
		if (bundle.resourcePath) {
			[candidates addObject:[bundle.resourcePath stringByAppendingPathComponent:name]];
		}
		if (bundle.bundlePath) {
			[candidates addObject:[bundle.bundlePath stringByAppendingPathComponent:name]];
		}
		NSString *exe = bundle.executablePath;
		if (exe) {
			NSString *dir = [exe stringByDeletingLastPathComponent];
			[candidates addObject:[dir stringByAppendingPathComponent:name]];
			[candidates addObject:[[dir stringByAppendingPathComponent:@"../Resources"] stringByAppendingPathComponent:name]];
		}
		for (NSString *c in candidates) {
			if ([fm fileExistsAtPath:c]) {
				return nv_gd([c stringByStandardizingPath]);
			}
		}
		return String();
	}
}

bool NativeVideoPlayer::open(const String &p_path) {
	@autoreleasepool {
		NVPlayerState *state = nv_state(impl);
		[state tearDown];
		state.ended = NO;
		state.failed = NO;
		state.taps = 0;
		state.skips = 0;
		state.error = nil;
		reported = 0;

		NSString *path = nv_ns(p_path);
		if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
			state.error = [NSString stringWithFormat:@"no such file: %@", path];
			return false;
		}
		NVView *gameView = (__bridge NVView *)(void *)(intptr_t)DisplayServer::get_singleton()->window_get_native_handle(DisplayServer::WINDOW_VIEW);
		if (gameView == nil) {
			state.error = @"no game view to draw over";
			return false;
		}

		NSURL *url = [NSURL fileURLWithPath:path];
		AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
		AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
		AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
		player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
		if (@available(iOS 10.0, macOS 10.12, *)) {
			player.automaticallyWaitsToMinimizeStalling = NO; // a local file
		}
		player.volume = state.volume;
		state.item = item;
		state.player = player;

		NVOverlayView *overlay = [[NVOverlayView alloc] initWithFrame:gameView.bounds];
		overlay.host.playerLayer.player = player;
		__weak NVPlayerState *weakState = state;
		overlay.onTap = ^(BOOL onSkip) {
			NVPlayerState *s = weakState;
			if (!s) {
				return;
			}
			if (onSkip) {
				s.skips = s.skips + 1;
			} else {
				s.taps = s.taps + 1;
			}
		};
		[gameView addSubview:overlay];
#if TARGET_OS_IPHONE
		[overlay setNeedsLayout];
#else
		overlay.needsLayout = YES;
#endif
		state.overlay = overlay;

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		state.endObserver = [nc addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
											object:item
											 queue:[NSOperationQueue mainQueue]
										usingBlock:^(NSNotification *note) {
											NVPlayerState *s = weakState;
											if (s) {
												s.ended = YES;
												s.playing = NO;
											}
										}];
		state.failObserver = [nc addObserverForName:AVPlayerItemFailedToPlayToEndTimeNotification
											 object:item
											  queue:[NSOperationQueue mainQueue]
										 usingBlock:^(NSNotification *note) {
											 NVPlayerState *s = weakState;
											 if (s) {
												 NSError *err = note.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
												 s.error = err ? err.localizedDescription : @"playback failed";
												 s.failed = YES;
												 s.playing = NO;
											 }
										 }];
		return true;
	}
}

void NativeVideoPlayer::play() {
	NVPlayerState *state = nv_state(impl);
	if (state.player) {
		[state.player play];
		state.playing = YES;
	}
}

void NativeVideoPlayer::pause() {
	NVPlayerState *state = nv_state(impl);
	if (state.player) {
		[state.player pause];
		state.playing = NO;
	}
}

void NativeVideoPlayer::stop() {
	NVPlayerState *state = nv_state(impl);
	[state tearDown];
}

bool NativeVideoPlayer::is_open() const {
	return nv_state(impl).player != nil;
}

bool NativeVideoPlayer::is_ready() const {
	NVPlayerState *state = nv_state(impl);
	return state.item != nil && state.item.status == AVPlayerItemStatusReadyToPlay;
}

bool NativeVideoPlayer::is_playing() const {
	NVPlayerState *state = nv_state(impl);
	if (state.player == nil || state.ended || state.failed) {
		return false;
	}
	return state.playing && state.player.rate != 0.0f;
}

bool NativeVideoPlayer::has_finished() const {
	return nv_state(impl).ended;
}

bool NativeVideoPlayer::has_failed() const {
	NVPlayerState *state = nv_state(impl);
	if (state.failed) {
		return true;
	}
	if (state.item != nil && state.item.status == AVPlayerItemStatusFailed) {
		NSError *err = state.item.error;
		state.error = err ? err.localizedDescription : @"the file can't be played";
		state.failed = YES;
		return true;
	}
	return false;
}

String NativeVideoPlayer::get_error() const {
	return nv_gd(nv_state(impl).error);
}

double NativeVideoPlayer::get_position() const {
	NVPlayerState *state = nv_state(impl);
	if (state.player == nil) {
		return 0.0;
	}
	CMTime t = state.player.currentTime;
	return CMTIME_IS_NUMERIC(t) ? CMTimeGetSeconds(t) : 0.0;
}

double NativeVideoPlayer::get_length() const {
	NVPlayerState *state = nv_state(impl);
	if (state.item == nil) {
		return 0.0;
	}
	CMTime d = state.item.duration;
	return CMTIME_IS_NUMERIC(d) ? CMTimeGetSeconds(d) : 0.0;
}

void NativeVideoPlayer::seek(double p_seconds) {
	NVPlayerState *state = nv_state(impl);
	if (state.player) {
		[state.player seekToTime:CMTimeMakeWithSeconds(p_seconds, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
		state.ended = NO;
	}
}

Vector2 NativeVideoPlayer::get_video_size() const {
	NVPlayerState *state = nv_state(impl);
	if (state.item == nil) {
		return Vector2();
	}
	CGSize s = state.item.presentationSize;
	return Vector2((real_t)s.width, (real_t)s.height);
}

void NativeVideoPlayer::set_volume(double p_volume) {
	NVPlayerState *state = nv_state(impl);
	state.volume = (float)std::max(0.0, std::min(1.0, p_volume));
	if (state.player) {
		state.player.volume = state.volume;
	}
}

double NativeVideoPlayer::get_volume() const {
	return nv_state(impl).volume;
}

void NativeVideoPlayer::set_opacity(double p_opacity) {
	NVPlayerState *state = nv_state(impl);
	if (state.overlay) {
		CGFloat a = (CGFloat)std::max(0.0, std::min(1.0, p_opacity));
#if TARGET_OS_IPHONE
		state.overlay.alpha = a;
#else
		state.overlay.alphaValue = a;
#endif
	}
}

void NativeVideoPlayer::set_visible(bool p_visible) {
	NVPlayerState *state = nv_state(impl);
	if (state.overlay) {
		state.overlay.hidden = !p_visible;
	}
}

bool NativeVideoPlayer::is_visible() const {
	NVPlayerState *state = nv_state(impl);
	return state.overlay != nil && !state.overlay.hidden;
}

void NativeVideoPlayer::set_subtitle(const String &p_text) {
	NVPlayerState *state = nv_state(impl);
	if (state.overlay) {
		[state.overlay setSubtitleText:nv_ns(p_text)];
	}
}

void NativeVideoPlayer::show_skip(bool p_show, const String &p_text) {
	NVPlayerState *state = nv_state(impl);
	if (state.overlay) {
		[state.overlay setSkipText:nv_ns(p_text) shown:p_show];
	}
}

int NativeVideoPlayer::poll() {
	NVPlayerState *state = nv_state(impl);
	int events = 0;
	if (state.taps > 0) {
		state.taps = 0;
		events |= EVENT_TAPPED;
	}
	if (state.skips > 0) {
		state.skips = 0;
		events |= EVENT_SKIP_PRESSED;
	}
	// reported once each
	static const int REPORTED_FINISHED = 1 << 16;
	static const int REPORTED_FAILED = 1 << 17;
	if (state.ended && !(reported & REPORTED_FINISHED)) {
		reported |= REPORTED_FINISHED;
		events |= EVENT_FINISHED;
	}
	if (has_failed() && !(reported & REPORTED_FAILED)) {
		reported |= REPORTED_FAILED;
		events |= EVENT_FAILED;
	}
	if (events & EVENT_TAPPED) {
		emit_signal("tapped");
	}
	if (events & EVENT_SKIP_PRESSED) {
		emit_signal("skip_pressed");
	}
	if (events & EVENT_FINISHED) {
		emit_signal("finished");
	}
	if (events & EVENT_FAILED) {
		emit_signal("failed", get_error());
	}
	return events;
}
