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

func open(url: String) -> void:
	_socket = WebSocketPeer.new()
	_was_open = false
	var err := _socket.connect_to_url(url)
	_active = err == OK
	if err != OK:
		push_error("NetClient: connect_to_url failed (%d)" % err)
		socket_closed.emit()

func is_open() -> bool:
	return _active and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func send_message(type: String, payload: Variant = {}) -> void:
	if is_open():
		_socket.send_text(JSON.stringify({"type": type, "payload": payload}))

func _process(_delta: float) -> void:
	if not _active:
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
			_was_open = false
			socket_closed.emit()
