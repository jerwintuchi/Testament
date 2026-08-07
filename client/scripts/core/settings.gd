extends RefCounted
## The player's settings, on disk (TD-084). Preloaded as `Settings`, never a global class_name so a
## headless parse/import resolves it (TD-029/30).
##
## Legitimate to persist under **TD-006**: identity, cosmetics and *customization* survive between
## sessions; nothing about an expedition does. A volume level and a motion preference are
## customization, and a display name is identity.
##
## The **name deliberately keeps its own file** (`display-name.txt`, TD-080). It is read on the path
## that creates a room, and folding it into a config file would mean that path now depends on config
## parsing succeeding — a worse failure mode for the one value the game cannot start without.

const PATH := "user://settings.cfg"
const SECTION := "player"

const DEF_REDUCED_MOTION := false
const DEF_VOLUME := 0.8

var reduced_motion: bool = DEF_REDUCED_MOTION
var volume: float = DEF_VOLUME


## Read from disk. A missing file is the FIRST LAUNCH, which is the common case rather than an edge
## one, so it returns defaults silently; a corrupt file does the same rather than erroring, because
## nothing here is worth refusing to start over.
## Returns untyped and the caller casts. A script with no `class_name` cannot name its own type in
## a signature (and canon forbids the `class_name`, TD-029/30), so `preload` + cast at the call site
## is the idiom the rest of the client already uses.
static func load_from_disk():
	var s = load("res://scripts/core/settings.gd").new()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return s
	s.reduced_motion = bool(cfg.get_value(SECTION, "reduced_motion", DEF_REDUCED_MOTION))
	s.volume = clampf(float(cfg.get_value(SECTION, "volume", DEF_VOLUME)), 0.0, 1.0)
	return s


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "reduced_motion", reduced_motion)
	cfg.set_value(SECTION, "volume", volume)
	cfg.save(PATH)


## Push the audio setting at the engine. Called on load and on change, so the stored value and what
## you can hear never disagree.
func apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	# Linear 0..1 to decibels, with 0 as true silence rather than -80dB of nearly-silence.
	AudioServer.set_bus_mute(bus, volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))
