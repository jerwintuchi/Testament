class_name NetClient
extends Node
## Raw WebSocket + JSON envelope transport (TD-002). No game knowledge: it moves
## `{ "type": ..., "payload": ... }` envelopes; main.gd decides what they mean.

signal socket_opened
signal socket_closed
signal message_received(type: String, payload: Variant)

var _socket := WebSocketPeer.new()
var _active := false
var _was_open := false

# ── Retrying the first connect (TD-086) ──────────────────────────────────────
# The client used to get ONE attempt. Start it a moment before the server finishes binding — which
# `tools/playtest.bat` does routinely, since it waits a fixed 4s for a server that takes ~3s warm and
# longer cold — and it reported "server offline" and stayed that way until the player restarted it.
# The fix belongs here rather than in a longer sleep in the .bat, because it also covers a server
# started late, restarted mid-session, or simply slower on a cold cache.
#
# It backs off so a genuinely absent server does not spin: roughly 0.5s, 1s, 2s, 4s, then every 5s.
const RETRY_FIRST := 0.5
const RETRY_MAX := 5.0

var _url := ""
var _retry_in := 0.0
var _retry_delay := RETRY_FIRST
var _want_open := false          # true between `open()` and `close()`: keep trying while set

func open(url: String) -> void:
	_url = url
	_want_open = true
	_retry_delay = RETRY_FIRST
	_retry_in = 0.0
	_connect_now()

func close() -> void:
	_want_open = false
	_active = false

func _connect_now() -> void:
	_socket = WebSocketPeer.new()
	_was_open = false
	var err := _socket.connect_to_url(_url)
	_active = err == OK
	if err != OK:
		# Not a push_error: a refused connect while the server is still starting is expected, and
		# an error per attempt would bury the log. The retry below reports it once it gives up.
		_schedule_retry()
		socket_closed.emit()

func _schedule_retry() -> void:
	if not _want_open:
		return
	_retry_in = _retry_delay
	_retry_delay = minf(_retry_delay * 2.0, RETRY_MAX)

func is_open() -> bool:
	return _active and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func send_message(type: String, payload: Variant = {}) -> void:
	if is_open():
		_socket.send_text(JSON.stringify({"type": type, "payload": payload}))

func _process(delta: float) -> void:
	if not _active:
		# Waiting to try again. `_want_open` is what separates "the server is not up yet" from
		# "we deliberately disconnected", so a real close does not reconnect behind the player.
		if _want_open and _retry_in > 0.0:
			_retry_in -= delta
			if _retry_in <= 0.0:
				_connect_now()
		return
	_socket.poll()
	match _socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _was_open:
				_was_open = true
				socket_opened.emit()
			while _socket.get_available_packet_count() > 0:
				var text := _socket.get_packet().get_string_from_utf8()
				var data: Variant = JSON.parse_string(text)
				if typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] is String:
					message_received.emit(data["type"], data.get("payload"))
		WebSocketPeer.STATE_CLOSED:
			_active = false
			var had_been_open := _was_open
			_was_open = false
			if had_been_open:
				# A live connection dropped: start the backoff from the top, because this is a new
				# outage rather than a continuation of the one we were already backing off from.
				_retry_delay = RETRY_FIRST
			_schedule_retry()
			socket_closed.emit()
