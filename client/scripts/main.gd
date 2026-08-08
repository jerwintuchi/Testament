extends Node2D
## Testament client — the Phase 4 protocol walk: lobby → requisition → field → probe.
##
## Render + input only (trust boundary): every screen transition is caused by a
## server event; user input only ever *sends* an intention. All session state
## below is a render copy of what the server said, never locally derived.

enum Screen { TITLE, MENU, LOBBY, DEPLOYING, FIELD, TESTAMENT, RECONNECTING }

# The wire-protocol contract, codegen'd from src/shared (pnpm gen:protocol). The
# server references the same names, so message types, error codes, phases, and the
# gear catalog never drift (TD-029/TD-030: preload, not a global class_name).
const Protocol = preload("res://protocol/protocol.gd")
const WaxSeal = preload("res://scripts/board/wax_seal.gd")
const OrnamentScrollbar = preload("res://scripts/board/ornament_scrollbar.gd")
const VerbBadge = preload("res://scripts/board/verb_badge.gd")
const Notice = preload("res://scripts/board/notice.gd")
const NoticeReader = preload("res://scripts/board/notice_reader.gd")  # the taken-down writ + its seal
const ContractBoard = preload("res://scripts/board/contract_board.gd")  # the wall the writs hang on
const NoticeCard = preload("res://scripts/board/notice_card.gd")        # one writ + its furniture
const BoardGeo = preload("res://scripts/board/board_geometry.gd")  # pure board layout/keep-out/seed math
const BoardDecor = preload("res://scripts/board/board_decor.gd")   # torches + crest render factories
const BoardBar = preload("res://scripts/board/board_bar.gd")       # bottom legend/assignment/status bar
const Fonts = preload("res://scripts/ui/fonts.gd")              # shared font builders (Cinzel)
const PopupTheme = preload("res://scripts/ui/popup_theme.gd")   # the station popup's gothic Theme
const RiteBanner = preload("res://scripts/ui/rite_banner.gd")   # the CONTRACT SEALED ceremony overlay
const Widgets = preload("res://scripts/ui/widgets.gd")          # shared label/rule/engraved builders
const TitleScene = preload("res://scripts/ui/title_scene.gd")   # the title's layered environment
const WritForm = preload("res://scripts/ui/writ_form.gd")       # the join / name writ (TD-080)
const Settings = preload("res://scripts/core/settings.gd")      # persisted options (TD-084)
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")     # the Escape menu (TD-085)
const RoomScroll = preload("res://scripts/ui/room_scroll.gd")   # the lobby's toggleable roster
const StationNames = preload("res://scripts/core/station_names.gd")  # station kind -> player-facing name

const SERVER_URL := "ws://localhost:3001"

# Where the client dials. `localhost` is right when client and server share a host, but a
# Windows-side Godot talking to a server in WSL2 (NAT mode, no localhost forwarding) has to
# dial the WSL IP instead — and that IP is reassigned on every WSL restart, so it can never be
# hardcoded. `-- --server=ws://<host>:<port>` overrides it for one run; `hostname -I` in WSL
# prints the address. Dev convenience only: it moves WHERE the client connects, never what it
# trusts — the server remains authoritative over that socket exactly as before (I1).
func _server_url() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			return a.substr("--server=".length())
	return SERVER_URL
# The reconnect token NO LONGER survives a client relaunch (TD-086, superseding R75's persistence).
# It is expedition state, and I7/TD-006 keep expedition state out of persistence — a seat in a room
# is not identity. This path exists only so a token written by an older build is deleted on boot.
const TOKEN_PATH := "user://reconnect-token.txt"
# The display name the player last used. Like the token this is a local convenience, not game
# state — the server still assigns identity, this only spares a returning player the retyping.
const NAME_PATH := "user://display-name.txt"

var _net: NetClient
var _screen: Screen = Screen.TITLE

# ── Server-derived session state ─────────────────────────────────────────────
var _self_id := ""
var _reconnect_token := ""
var _snapshot: Dictionary = {}    # last LobbySnapshot
var _field: Dictionary = {}       # StubFieldData
var _channels: Array = []         # own perceived channels (never other players')
var _signs: Array = []            # [{channel, token}] — the only Incarnate info that exists client-side
var _probe_log: Array = []        # display strings, newest last
var _exposure := 0
var _testament: Dictionary = {}
var _archive: Array = []

# ── Client-only UI state ─────────────────────────────────────────────────────
var _selected_items: Array = []   # requisition picks before sending
var _pending_join := false        # sent CREATE/JOIN, awaiting the server's verdict
var _awaiting_resume := false     # sent RECONNECT, awaiting STATE_RESYNC or an error

# ── UI shell ─────────────────────────────────────────────────────────────────
var _root: VBoxContainer
var _status: Label
var _menu_bg: Control              # the room-setup screen's lit masonry backdrop (TD-071)
var _nave: TextureRect             # the title screen's held image (R231), TITLE screen only
var _nave_bg: ColorRect            # fills whatever the integer-scaled plate does not cover
var _setup_mode := ""              # "create" or "join" — which room-setup plate is showing
var _title_env: Control            # the title's layered environment (TD-073)
var _title_host: Control           # full-rect host it is built onto, behind the UI
var _room_scroll: Control          # the lobby's room scroll (TD-071), closed by default
var _scroll_layer: Control         # holds it above the world, below the station popup
var _menu_stone: TextureRect       # the brick surface inside it; also the torches' host
var _ui_theme: Theme               # the gothic Theme, shared by the station popup and the menu
var _name_input: LineEdit
var _code_input: LineEdit

# ── Walkable world (a render copy of server positions; never client-derived) ──
# The world is an authored node tree (scenes/main.tscn) rendered beneath the UI
# CanvasLayer. Bodies move only when the server reports a position (R104/R108);
# input only ever *sends* a MOVE intent.
const BODY := preload("res://scenes/player.tscn")
@onready var _world: Node2D = $World
@onready var _space: SpaceView = $World/SpaceView
@onready var _body_root: Node2D = $World/Bodies
@onready var _camera: Camera2D = $World/Camera2D
var _bodies: Dictionary = {}      # playerId -> Player
var _field_site: Dictionary = {}  # SiteLayout (grid + nodes) for the FIELD phase
var _last_intent := Vector2i.ZERO # last MOVE vector sent; we emit only on change
var _last_walk := false           # last walk-modifier (Shift) sent; also edge-triggered

# ── Station interaction (client affordance; server still gates with NOT_AT_*) ─
# Radii mirror @testament/shared (STATION_RADIUS / EXTRACTION_RADIUS). They only
# drive the "Press E" prompt — the server re-validates every station action, so a
# drifted client copy can never grant an action the server would deny (R106/R108).
const TILE := 16
const STATION_RADIUS := 24.0
const EXTRACTION_RADIUS := 32.0
var _active_station := ""         # kind of the station in range, or "" — a render hint
var _menu_open := false           # a station popup is up: movement is locked
var _popup_kind := ""             # the station kind the open popup was built for (for rebuilds)
var _board_selection: Dictionary = {}  # the contract card being previewed, or {} = the grid view
var _board_canvas: Control = null      # the current board canvas — for the targeted reader refresh (TD-065)
var _wood_sb: StyleBox            # Contract Board panel skin — the carved 9-slice frame (board_frame.png)
var _board_frame: NinePatchRect   # carved frame overlay, shader-lit; tracks the popup rect (TD-047)
var _stone_bg: TextureRect        # tiled stone/mortar surround, dim; Contract Board only
var _reduced_motion: bool = false # settings toggle (F9 in playtest): freeze flicker, pin glow to peak
var _title_arrived := false       # the title's arrival flourish plays once per launch, not per visit
var _settings: Settings           # persisted options (TD-084); loaded once at boot
var _pause_host: Control          # the Escape menu's own layer, above everything (TD-085)
var _pause: Control               # the open menu, or null
var _popup_tween: Tween           # the open/close animation, tracked so it can be killed on re-entry
var _prompt: Label                # bottom-center "Press E — <Station>"
var _popup_dim: ColorRect         # full-rect input blocker + dimmer behind the popup
var _popup: PanelContainer        # the reusable station menu shell
var _popup_title: Label           # station name (persistent, above the scroll)
var _popup_body: VBoxContainer    # per-station content, rebuilt on open (scrolls)
var _popup_close: Button          # Close (Esc) button — hidden for the board (frame has no room; Esc closes)
var _keyhint: Control             # bottom-of-screen keybind strip (Contract Board only)
var _popup_scroll: ScrollContainer  # sizes the popup — widened to a full board for CONTRACT_BOARD
var _toast: Label                 # transient top-center notice (e.g. a contract sealed/withdrawn)
var _toast_tween: Tween

func _ready() -> void:
	_net = NetClient.new()
	add_child(_net)
	_net.message_received.connect(_on_message)
	_net.socket_opened.connect(_on_socket_opened)
	_net.socket_closed.connect(_on_socket_closed)

	# The walkable world (scenes/main.tscn: World/SpaceView/Bodies/Camera2D) renders
	# beneath the UI CanvasLayer, which is built below. 2× integer zoom (960×540
	# window over a 480×270 frame) is set on the Camera2D in the scene.
	_camera.make_current()

	# The Escape menu gets its OWN layer, above every other, because it is the way out: a station
	# popup or a HUD drawing over it would trap the player in exactly the situation it exists for.
	var pause_layer := CanvasLayer.new()
	pause_layer.layer = 128
	add_child(pause_layer)
	_pause_host = Control.new()
	_pause_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_layer.add_child(_pause_host)

	var layer := CanvasLayer.new()
	add_child(layer)
	# The menu's backdrop: the Collegium's own masonry under two sconces, so the first screen
	# belongs to the same lit world as the Contract Board rather than reading as a settings dialog
	# ("diegetic-lite", TD-071/R227). Shipped art only — stone_tile + the torch rig — so this
	# needs no new generator. Added BEFORE the UI margin so it sits behind every screen's content,
	# and shown only on MENU.
	_menu_bg = Control.new()
	_menu_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_bg.visible = false
	layer.add_child(_menu_bg)
	# The title screen's held image: the empty nave (R231). A generated 640x360 plate drawn at an
	# INTEGER scale and centred, with its own near-black filling the remainder — never fractionally
	# stretched, so the pixel grid survives at every window size.
	_scroll_layer = Control.new()
	_scroll_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_scroll_layer)

	_title_host = Control.new()
	_title_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_title_host)

	_nave_bg = ColorRect.new()
	_nave_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nave_bg.color = NAVE_BLACK            # the plate's own darkest value, so the fill is invisible
	_nave_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nave_bg.visible = false
	layer.add_child(_nave_bg)
	# The title's environment is TitleScene (TD-073); this node survives only so the older
	# screens that reference _nave keep compiling. It is never shown.
	_nave = TextureRect.new()
	_nave.visible = false
	layer.add_child(_nave)

	_menu_stone = TextureRect.new()
	_menu_stone.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_stone.texture = load("res://assets/ui/board/stone_tile.png") as Texture2D
	_menu_stone.stretch_mode = TextureRect.STRETCH_SCALE
	_menu_stone.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_menu_stone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_menu_stone.material = BoardDecor.surface_material(get_viewport_rect().size, "res://assets/ui/board/stone_tile_n.png", 0.24, 1.0, Vector2(5.0, 4.2))
	_menu_stone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_bg.add_child(_menu_stone)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Metrics are in logical (640x360) pixels — see PixelScale. Keep them tight: a
	# 24px margin cost 13% of the viewport height at the old 960x540 base.
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	layer.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)
	# Screens can outgrow the window; they scroll while the status line below
	# stays visible (R80 — no more resizing the window to find it).
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_root = VBoxContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_theme_constant_override("separation", 5)
	scroll.add_child(_root)
	_status = Label.new()
	_status.modulate = Color(0.85, 0.7, 0.5)
	# A quiet corner indicator (R227): small and right-aligned so "connected" recedes, while an
	# actionable line ("server offline. start it with: …") keeps its full warm colour.
	_status.add_theme_font_size_override("font_size", 10)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_status)

	# Bottom-center interaction prompt (hidden until near a station).
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -180
	_prompt.offset_right = 180
	_prompt.offset_top = -56
	_prompt.offset_bottom = -32
	_prompt.modulate = Color(1.0, 0.95, 0.72)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	layer.add_child(_prompt)

	# Top-center transient toast (contract sealed/withdrawn, and future room notices).
	# Above the popup dimmer so it reads even over an open station.
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -260
	_toast.offset_right = 260
	_toast.offset_top = 20
	_toast.offset_bottom = 52
	_toast.add_theme_font_size_override("font_size", 10)
	_toast.add_theme_color_override("font_color", Color(0.97, 0.90, 0.66))
	_toast.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.02, 0.95))
	_toast.add_theme_constant_override("shadow_offset_x", 1)
	_toast.add_theme_constant_override("shadow_offset_y", 2)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	layer.add_child(_toast)

	# Reusable station popup: a full-rect dimmer that blocks the map/base UI, plus a
	# centered panel whose body is rebuilt per station. Hidden until E.
	_popup_dim = ColorRect.new()
	_popup_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_dim.color = Color(0.02, 0.015, 0.01, 0.74)   # deep, faintly warm — the crypt beyond the board
	_popup_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_dim.visible = false
	# Click-off dismiss for a taken-down writ: a LEFT-click anywhere OUTSIDE the board (on the
	# surrounding wall) returns the writ to the wall. Clicks inside the board but outside the
	# writ are caught by the reader's own dim; the writ parchment itself stays (STOP).
	# Left-button only: wheel ticks are ALSO InputEventMouseButton (WHEEL_UP/DOWN, pressed),
	# so an unguarded check made over-scrolling the writ dismiss it (TD-060 review).
	_popup_dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT \
				and _popup_kind == "CONTRACT_BOARD" and not _board_selection.is_empty():
			_select_board_card({}))
	layer.add_child(_popup_dim)
	# Stone/mortar surround: tiled behind the popup, dim so the candlelit wall reads
	# but stays recessed. Shown for the Contract Board only (set in _open_station).
	_stone_bg = TextureRect.new()
	_stone_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The Collegium wall: a seamless brick (stone_tile.png, 48x32) TILED a few times across the
	# screen (large courses that scale with the board), lit by board_surface.gdshader — the
	# diffuse/normal are sampled at UV*tile_scale so the shader tiles too. Ambient is LOW so the
	# wall sits in the dark and is REVEALED warm only where a sconce's halo reaches (the target:
	# masonry noticed in the dark, from the torchlight). Light2D can't reach Control nodes (TD-047).
	_stone_bg.texture = load("res://assets/ui/board/stone_tile.png") as Texture2D
	_stone_bg.stretch_mode = TextureRect.STRETCH_SCALE          # UV 0..1; the shader does the tiling
	_stone_bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED   # so UV*tile_scale wraps the brick
	_stone_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp pixel brick, not blurred
	_stone_bg.material = BoardDecor.surface_material(get_viewport_rect().size, "res://assets/ui/board/stone_tile_n.png", 0.24, 1.0, Vector2(5.0, 4.2))
	_stone_bg.modulate = Color(1.0, 1.0, 1.0)   # brightness comes from the shader (dark ambient + sconce)
	_stone_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stone_bg.visible = false
	_popup_dim.add_child(_stone_bg)
	# CenterContainer robustly centres the panel regardless of its size.
	# A plain full-rect Control (not a CenterContainer) so the popup's position is
	# ours to animate — we centre it manually and slide it up from the bottom.
	var pcenter := Control.new()
	pcenter.set_anchors_preset(Control.PRESET_FULL_RECT)
	pcenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_dim.add_child(pcenter)
	_popup = PanelContainer.new()
	_ui_theme = PopupTheme.build()     # 9-slice gothic panel + gold-on-charcoal controls
	_popup.theme = _ui_theme           # …cascaded to the popup AND reused by the menu (R227)
	_popup.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # soft painterly frame (v1 raster)
	# Skins swapped in per station: the Contract Board is a wooden board, its cards
	# pinned parchment. Built once; a missing texture falls back to a flat box.
	# Pass-2: the carved 9-slice frame is the board's panel skin; the plank backing
	# fills behind the notices; the stone/mortar tile is the surround. (Batch 1, T142.)
	# Painterly wooden frame sliced from the Prototype-v1 raster (TD-044): a 9-slice with
	# a transparent interior and the crest painted out (drawn separately). LINEAR-filtered.
	# Frame + backing: shader-lit like the wall once the wall proof lands (T149). Plain for now.
	_wood_sb = _texture_sb("res://assets/ui/board/frame_v1.png", 33.0, 20.0, Color(0.29, 0.19, 0.10), Color(0.45, 0.30, 0.15))
	# Board art (backing, deckled parchment split live vs flavor, tacks, decay props) is
	# loaded once, here, so the timing is exactly what it was before the T231 extraction.
	ContractBoard.load_art()
	pcenter.add_child(_popup)
	# Carved frame overlay (TD-047): the board's frame is a shader-lit NinePatch that tracks the
	# popup rect from OUTSIDE the clipping ScrollContainer, so the torches light its relief (a
	# StyleBox can't hold a material, and an in-canvas frame is clipped). Shown for the board only.
	_board_frame = NinePatchRect.new()
	_board_frame.texture = load("res://assets/ui/board/frame_v1.png") as Texture2D
	_board_frame.patch_margin_left = 33; _board_frame.patch_margin_top = 33
	_board_frame.patch_margin_right = 33; _board_frame.patch_margin_bottom = 33
	_board_frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_board_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_frame.visible = false
	_board_frame.z_index = 3
	pcenter.add_child(_board_frame)
	var ppad := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		ppad.add_theme_constant_override(side, 10)
	_popup.add_child(ppad)
	var pcol := VBoxContainer.new()
	pcol.add_theme_constant_override("separation", 8)
	ppad.add_child(pcol)
	_popup_title = Label.new()
	_popup_title.add_theme_font_size_override("font_size", 15)
	_popup_title.add_theme_color_override("font_color", Color(0.90, 0.78, 0.45))
	pcol.add_child(_popup_title)
	# Fixed-size scroll viewport so a long list (Quartermaster) never overruns the
	# window — it scrolls instead.
	var pscroll := ScrollContainer.new()
	pscroll.custom_minimum_size = Vector2(400, 240)
	pscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pcol.add_child(pscroll)
	_popup_scroll = pscroll
	_popup_body = VBoxContainer.new()
	_popup_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_body.add_theme_constant_override("separation", 8)
	pscroll.add_child(_popup_body)
	_popup_close = Button.new()
	_popup_close.text = "Close  (Esc)"
	_popup_close.pressed.connect(_close_station)
	pcol.add_child(_popup_close)

	# Keybind hint strip along the very bottom of the screen (Prototype-v1 read), shown for
	# the Contract Board only. A child of the dim so it sits over the wall, below the frame.
	_keyhint = ContractBoard.keyhint()
	_popup_dim.add_child(_keyhint)

	# Reflow the open station popup when the window resizes (e.g. fullscreen toggle),
	# so a board built for one resolution never lingers over-sized in another.
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Settings before the first screen: reduced motion has to be true from the FIRST build, not
	# applied after one has already been made with animation in it.
	_settings = Settings.load_from_disk() as Settings
	_settings.apply_audio()
	_reduced_motion = _settings.reduced_motion

	# Force the F9 reduced-motion lever on BEFORE the first screen is built, so an unattended
	# capture can verify L5 (glow pinned to peak, flame frozen) without input injection. This has
	# to precede `_show_title()`: it used to sit after it and was only honoured because
	# `--title-preview` happened to rebuild the title afterwards — a real dependency on an
	# unrelated flag's side effect, which broke the moment that rebuild was removed (T285).
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--reduced-motion"):
		_reduced_motion = true

	_reconnect_token = _load_token()
	# `-- --title-preview` fakes a reconnect token so `Return to your expedition` — which only
	# exists when there IS an expedition to return to — is capturable unattended. Display only: the
	# token is never sent. It is set HERE, before the first build, rather than deferred into a
	# second `_show_title()`; the second build discarded the first one's arrival flourish (T285) and
	# made every title capture construct the whole scene twice for nothing.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--title-preview"):
		# --no-token captures the 3-option form even when a real token happens to be on disk.
		_reconnect_token = "" if OS.get_cmdline_user_args().has("--no-token") else "preview-token"
	_net.open(_server_url())
	_show_title()

	# Dev-only: `-- --board-preview` opens the Contract Board over fixture intel, with no
	# server and no walking, so the board's art can be iterated against a screenshot
	# (DebugCapture). Render-only — it fabricates a *display* snapshot, never game state,
	# and no intent is ever sent from it. Debug builds only.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--board-preview"):
		call_deferred("_board_preview")
	# `-- --lobby-preview` shows the WAITING lobby over a fixture Collegium, so the walkable
	# screen can be captured with no server and no input (station names, roster, the room
	# scroll). Same discipline as _board_preview: a fabricated *display* snapshot, never game
	# state, and nothing is ever sent from it.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--lobby-preview"):
		call_deferred("_lobby_preview")
	# `--title-preview` is handled ABOVE, before the first `_show_title()`. (It supersedes TD-071
	# Phase B's `--menu-preview`: Phase D made the first screen the title, and moved the name/code
	# plates behind `--setup-create` / `--setup-join`.)
	# `--setup-create` is retired with the screen it opened (TD-080): New Expedition creates the
	# room and enters the Collegium, so there is nothing to capture between the two.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--setup-join"):
		call_deferred("_show_join")
	# The name rite is first-run only, so it is otherwise uncapturable once a name is on disk.
	# `--pause` enters an expedition and then opens the Escape menu, so the one screen that exists
	# to be reached BY a keypress is capturable without one.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--pause"):
		get_tree().create_timer(0.6).timeout.connect(_begin_new_expedition)
		get_tree().create_timer(2.4).timeout.connect(_open_pause)
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--options"):
		call_deferred("_show_options")
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--name-rite"):
		call_deferred("_show_name_rite")
	# `--new-expedition` presses New Expedition for us, so the ONE behaviour this spec exists for —
	# no screen between the title and the Collegium — can be verified unattended. It needs a live
	# server; without one the client reports "still connecting", which is the honest result.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--new-expedition"):
		get_tree().create_timer(0.6).timeout.connect(_begin_new_expedition)
	# T310 (TD-081): the experiment the whole Collegium plan rests on. TD-047 found that a
	# PointLight2D at energy 8 changed NOTHING on the Contract Board, and every lighting decision
	# since has been shaped by that. But `_world` is a Node2D, not a Control — so the finding may
	# not apply here at all. One light, captured with and against, before anything is built on the
	# assumption.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--light-test"):
		get_tree().create_timer(2.2).timeout.connect(_light_test)

## T310: drop ONE PointLight2D into the world layer and see whether the tiles take it.
func _light_test() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var l := PointLight2D.new()
	l.texture = tex
	l.energy = 2.0
	l.color = Color(1.0, 0.78, 0.45)
	# The Collegium is 24x16 tiles of 16px; the spawn atrium is tile (12, 8).
	l.position = Vector2(12 * 16 + 8, 8 * 16 + 8)
	_world.add_child(l)
	_log("light-test: PointLight2D added to _world at %s" % l.position)

# Fixture board: EIGHT contracts' worth of ContractIntel (canonical BOARD_SIZE=8, TD-045),
# the exact shape the server's `toContractIntel` puts on the wire (contractId, tier, origin,
# requester, targetName, siteName, primaryVerb). No trait axis — same containment as the wire.
const _PREVIEW_BOARD := [
	{"contractId": "c-alpha", "tier": "APPRENTICE", "origin": "BELIEF", "targetName": "The Hollow Vicar",
	 "siteName": "The Gall Road Ossuary", "primaryVerb": "INVESTIGATE",
	 "requester": {"name": "Maret Ives", "role": "almoner", "place": "Greymarsh"}},
	{"contractId": "c-beta", "tier": "APPRENTICE", "origin": "SIN", "targetName": "The Drowned Choir",
	 "siteName": "Hollowmere Crossing", "primaryVerb": "BANISH",
	 "requester": {"name": "", "role": "reeve", "place": "The Old Mill"}},
	{"contractId": "c-gamma", "tier": "APPRENTICE", "origin": "RELIC", "targetName": "The Unquiet Pilgrim",
	 "siteName": "The Broken Cloister", "primaryVerb": "ELIMINATE",
	 "requester": {"name": "Kestrel Vaun", "role": "lamplighter", "place": "Pilgrim's Rest"}},
	{"contractId": "c-delta", "tier": "APPRENTICE", "origin": "BELIEF", "targetName": "The Grey Congregant",
	 "siteName": "The Collapsed Chancel", "primaryVerb": "CAPTURE",
	 "requester": {"name": "Vidal Orr", "role": "chandler", "place": "Ashen Hollow"}},
	{"contractId": "c-eps", "tier": "APPRENTICE", "origin": "RELIC", "targetName": "The Sunken Congregation",
	 "siteName": "Hollowmere", "primaryVerb": "INVESTIGATE",
	 "requester": {"name": "Brother Ames", "role": "sexton", "place": "Hollowmere"}},
	{"contractId": "c-zeta", "tier": "APPRENTICE", "origin": "SIN", "targetName": "The Gallows Shepherd",
	 "siteName": "Low Fen", "primaryVerb": "ELIMINATE",
	 "requester": {"name": "", "role": "pilgrim", "place": "Low Fen"}},
	{"contractId": "c-eta", "tier": "APPRENTICE", "origin": "BELIEF", "targetName": "The Ember Cantor",
	 "siteName": "Gall", "primaryVerb": "BANISH",
	 "requester": {"name": "Sister Wren", "role": "archivist", "place": "the Sunken Nave"}},
	{"contractId": "c-theta", "tier": "APPRENTICE", "origin": "RELIC", "targetName": "The Weeping Reliquary",
	 "siteName": "Ashfen", "primaryVerb": "CAPTURE",
	 "requester": {"name": "Hald", "role": "warden", "place": "Ashfen"}},
]

# A small walkable Collegium: an open floor ringed by wall, with the three prep stations laid
# out as the server lays them out (kind + tile). Enough to prove the render, never game state.
const _PREVIEW_COLLEGIUM := {
	"grid": {"width": 20, "height": 12, "rows": [
		"####################",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"####################",
	]},
	"stations": [
		{"x": 3,  "y": 3, "kind": "CONTRACT_BOARD"},
		{"x": 10, "y": 2, "kind": "QUARTERMASTER"},
		{"x": 16, "y": 8, "kind": "DEPLOY_GATE"},
	],
}

func _lobby_preview() -> void:
	_self_id = "pv-self"
	_snapshot = {
		"phase": Protocol.PHASE_WAITING,
		"roomCode": "CZ3ZG4",
		"collegium": _PREVIEW_COLLEGIUM,
		"players": [
			{"playerId": "pv-self", "displayName": "Aldric", "isLeader": true,  "readyState": true,  "connected": true},
			{"playerId": "pv-2",    "displayName": "Wren",   "isLeader": false, "readyState": false, "connected": true},
			{"playerId": "pv-3",    "displayName": "Hald",   "isLeader": false, "readyState": false, "connected": false},
		],
		"positions": {"pv-self": {"x": 160, "y": 96}},
	}
	_show_lobby()
	if OS.get_cmdline_user_args().has("--scroll-open") and is_instance_valid(_room_scroll):
		_room_scroll.set_open(true)
	_log("lobby preview: room %s scroll_open=%s"
		% [_snapshot["roomCode"], is_instance_valid(_room_scroll) and _room_scroll.is_open()])

func _board_preview() -> void:
	# `-- --board-empty` previews the empty wall (L8); default is the 8-contract fixture.
	var pv_board: Array = [] if OS.get_cmdline_user_args().has("--board-empty") else _PREVIEW_BOARD
	# `-- --sealed` previews the taken-up state: the second fixture is the snapshot's
	# contract, so the reader's Collegium seal renders FIRM (V3-class capture checks).
	var pv_contract: Variant = _PREVIEW_BOARD[1] if OS.get_cmdline_user_args().has("--sealed") else null
	# A fixture LEADER identity, so the reader previews the leader's oath/seal affordance
	# (TD-062/V3) — with an empty players list _is_leader() is false and only the party
	# forms would ever be capturable.
	_self_id = "pv-self"
	var pv_players := [{"playerId": "pv-self", "displayName": "Aldric", "isLeader": true, "readyState": false, "connected": true}]
	_snapshot = {"phase": Protocol.PHASE_WAITING, "board": pv_board, "players": pv_players, "contract": pv_contract}
	# `-- --rite-banner` raises the CONTRACT SEALED ceremony once, for captures (V4).
	if OS.get_cmdline_user_args().has("--rite-banner"):
		RiteBanner.show.call_deferred(self, "CONTRACT SEALED", "The Drowned Choir", _reduced_motion)
	_world.visible = false
	_open_station("CONTRACT_BOARD")
	# `-- --reader` takes the second fixture down to read (threat pips + enlarged seal).
	if OS.get_cmdline_user_args().has("--reader"):
		_select_board_card.call_deferred(_PREVIEW_BOARD[1])
	# `-- --focus-first` grabs keyboard focus on the first writ so an unattended capture can
	# verify the gilt focus ring (L6) without injecting a Tab key.
	if OS.get_cmdline_user_args().has("--focus-first"):
		ContractBoard.focus_first.bind(self).call_deferred()
	# `-- --flash-preview` (implies --reader --sealed) spawns one impact flash on the reader
	# seal so a capture can show it blooming past the sheet edge, unclipped (TD-064/V1).
	if OS.get_cmdline_user_args().has("--flash-preview"):
		_flash_preview.call_deferred()
	# `-- --reader-cycle` takes a writ down and puts it back, so an unattended capture proves the
	# round trip leaves the wall intact and that NEITHER transition rebuilds the board (P123 —
	# `board live=` must appear exactly once for the whole run).
	if OS.get_cmdline_user_args().has("--reader-cycle"):
		_reader_cycle.call_deferred()
	_log("board preview: %d fixture contracts" % pv_board.size())

func _reader_cycle() -> void:
	_select_board_card(_PREVIEW_BOARD[1])
	for _i in 20:
		await get_tree().process_frame          # let the reader build, settle, and fade in
	_select_board_card({})                      # …and back to the wall
	# Then go inert: the Godot window pops under the OS cursor, and stray physical clicks kept
	# re-opening a writ before the capture fired (the known preview gotcha). Capture-only.
	for n in get_tree().get_nodes_in_group("live_notice"):
		if n is Control:
			(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log("reader cycle complete")

func _flash_preview() -> void:
	for _i in 6:
		await get_tree().process_frame          # let the deferred reader build + settle
	var seal := get_tree().root.find_child("ReaderSeal", true, false) as Control
	if seal == null:
		_log("flash preview: no ReaderSeal (pass --reader too)")
		return
	# REPEAT the bloom. It lasts ~0.76s, and the capture harness only takes whole seconds, so a
	# one-shot flash is never caught on film — it had to be verified by "it did not error", which
	# is not verification. Looping makes it reproducible from any capture time.
	while is_instance_valid(seal):
		NoticeReader.spawn_flash(_reader_ctx(_board_canvas, _board_selection), seal, 0.0)
		_log("flash preview: bloom")
		for _j in 66:
			await get_tree().process_frame

# On a window/viewport resize, re-fit an open station: recompute the board's
# scroll size and rebuild its body (the notice scatter is resolution-scaled), then
# re-center the panel. Cheap and only runs while a popup is open.
func _on_viewport_resized() -> void:
	if not _menu_open:
		return
	var vp := get_viewport_rect().size
	if _popup_kind == "CONTRACT_BOARD" and _wood_sb != null:
		_popup_scroll.custom_minimum_size = _board_inner_size()
	_rebuild_popup_body()
	await get_tree().process_frame
	if _popup_dim.visible:
		_popup.position = ((vp - _popup.size) * 0.5).floor()

# Flash a transient top-center toast: fade in, hold, fade out. Re-entrant — a new
# toast restarts the tween. Pure presentation (a server notice, not state).
func _show_toast(text: String) -> void:
	if _toast == null:
		return
	_toast.text = text
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.18)
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


# ── Inbound messages (the only source of state) ──────────────────────────────

func _on_message(type: String, payload: Variant) -> void:
	match type:
		Protocol.ROOM_CREATED:
			_snapshot = payload["snapshot"]
			_set_token(payload["reconnectToken"])
			_self_id = _snapshot["players"][0]["playerId"]  # creator is the only player
			_pending_join = false
			_show_lobby()
		Protocol.RECONNECT_TOKEN:
			_set_token(payload["reconnectToken"])
			_self_id = payload["playerId"]
			_pending_join = false
			_show_lobby()
		Protocol.LOBBY_UPDATED:
			_snapshot = payload["snapshot"]
			match _snapshot["phase"]:
				Protocol.PHASE_WAITING:
					# A joiner's first LOBBY_UPDATED precedes its RECONNECT_TOKEN;
					# without _self_id the lobby can't mark "you" yet, so wait.
					if _menu_open and _popup_kind == "CONTRACT_BOARD":
						# A stamp/lift happens only with a notice OPEN — refresh JUST the
						# reader (TD-065/P120), not the whole board (whose torch + 8-notice
						# churn was the stutter). Grid view (a ready-toggle/join, no
						# animation) keeps the full popup rebuild.
						if not _board_selection.is_empty():
							_refresh_open_reader()
						else:
							_rebuild_popup_body()
					elif _screen == Screen.LOBBY or (_pending_join and _self_id != ""):
						_show_lobby()
				Protocol.PHASE_DEPLOYING:
					if _screen == Screen.DEPLOYING:
						_show_deploying()  # party bags updated
		Protocol.CONTRACT_SELECTION:
			# The leader sealed/withdrew a charge. Authoritative selection arrives on the
			# LOBBY_UPDATED snapshot (contract). A STAMP is the party's shared ceremony
			# (TD-063/R205, author ruling): the souls-like CONTRACT SEALED banner fires for
			# every room member from this one broadcast, REPLACING the stamp toast. A lift
			# stays a quiet toast; errors stay on the toast.
			var who := str(payload.get("actorName", "The leader"))
			var tgt := str(payload.get("targetName", "a contract"))
			if payload.get("accepted", false):
				RiteBanner.show(self, "CONTRACT SEALED", tgt, _reduced_motion)
			else:
				_show_toast("%s lifted the seal on %s" % [who, tgt])
		Protocol.ROOM_DEPLOYING:
			_snapshot["phase"] = Protocol.PHASE_DEPLOYING
			_snapshot["contract"] = payload["contract"]
			_selected_items = []
			_close_station()   # a phase change invalidates any open station popup
			_show_deploying()
		Protocol.FIELD_STARTED:
			_field = payload["fieldData"]
			_field_site = payload["site"]
			_set_token(payload["reconnectToken"])
			_signs = payload["signs"]
			_channels = payload["perceivedChannels"]
			_probe_log = []
			_exposure = 0
			_snapshot["phase"] = Protocol.PHASE_FIELD
			_apply_positions(payload["positions"], true)
			_close_station()
			_show_field()
		Protocol.POSITIONS:
			# 20 Hz movement delta: move only the named bodies, prune nothing.
			_apply_positions(payload["positions"], false)
		Protocol.PROBE_RESULT:
			_ingest_probe_result(payload)
		Protocol.FIELD_TESTAMENT:
			_testament = payload["testament"]
			_close_station()
			_show_testament()
		Protocol.ARCHIVE_UPDATED:
			_archive = payload["entries"]
			if _screen == Screen.TESTAMENT:
				_show_testament()
		Protocol.STATE_RESYNC:
			_awaiting_resume = false
			_snapshot = payload["snapshot"]
			_set_token(payload["reconnectToken"])
			_self_id = payload["playerId"]  # a relaunched client holds only the token
			var fs: Variant = payload["fieldSnapshot"]
			if fs != null:
				_field = fs["fieldData"]
				_field_site = fs["site"]
				_signs = fs["signs"]
				_channels = fs["perceivedChannels"]
				_archive = fs["archiveEntries"]
				_probe_log = []
				_apply_positions(fs["positions"], true)
				_show_field()
			elif _snapshot["phase"] == Protocol.PHASE_DEPLOYING:
				_show_deploying()
			else:
				_show_lobby()
			_set_status("resynced")
		Protocol.LOBBY_ERROR:
			_pending_join = false
			# A failed resume means the seat is gone (kicked, or the room died):
			# forget the token so the client does not retry a dead seat forever.
			if _awaiting_resume or payload["code"] in [Protocol.ERR_TOKEN_EXPIRED, Protocol.ERR_TOKEN_NOT_FOUND]:
				_set_token("")
			_awaiting_resume = false
			_set_status("✝ %s: %s" % [payload["code"], payload["message"]])
			# Surface a raced rejection where the leader is looking (T146): affordance is not
			# authority — a stamp/deploy the server refuses (NOT_LEADER / NOT_AT_CONTRACT_BOARD /
			# WRONG_PHASE / NO_CONTRACT_SELECTED / UNKNOWN_CONTRACT) appears on the board's own
			# toast, not just the far-off status line. Rebuild restores the true seal state.
			if _menu_open and _popup_kind == "CONTRACT_BOARD":
				_show_toast("✝ %s" % payload["message"])
				_rebuild_popup_body()
			_log("LOBBY_ERROR %s — %s" % [payload["code"], payload["message"]])

func _ingest_probe_result(payload: Dictionary) -> void:
	_exposure = int(payload["exposure"])
	var who: String = _display_name(payload["playerId"])
	var line: String
	if payload["sign"] != null:
		var sign_data: Dictionary = payload["sign"]
		line = "%s presented %s: [%s] %s" % [who, payload["stimulus"], sign_data["channel"], sign_data["token"]]
		if not _signs.any(func(s): return s["channel"] == sign_data["channel"] and s["token"] == sign_data["token"]):
			_signs.append(sign_data)
	else:
		line = "%s presented %s: you cannot read it" % [who, payload["stimulus"]]
	_probe_log.append(line)
	if _screen == Screen.FIELD:
		_show_field()

# ── Connection lifecycle ─────────────────────────────────────────────────────

func _on_socket_opened() -> void:
	_set_status("connected")
	# Auto-resume only after a live drop. A fresh launch offers a Resume button
	# instead: instances on one machine share the token file, so resuming
	# silently would let a second window hijack the first one's identity.
	if _reconnect_token != "" and _screen == Screen.RECONNECTING:
		_awaiting_resume = true
		_net.send_message(Protocol.RECONNECT, {"token": _reconnect_token})

func _on_socket_closed() -> void:
	if _screen == Screen.TITLE or _screen == Screen.MENU or _screen == Screen.TESTAMENT:
		_set_status("server offline. start it with: pnpm dev:server")
	else:
		_show_reconnecting()

# ── Screens ──────────────────────────────────────────────────────────────────

# ── The title screen ────────────────────────────────────────────────────────
# A held image and a short list of ways in. Contemplation before preparation (R231/R232):
# no name field, no code field, no status line, and above all no figure — a title screen
# showing an Incarnate would leak the mystery the game is built on.
func _show_title() -> void:
	_screen = Screen.TITLE
	_world.visible = false
	_clear()
	_nave.visible = false
	_nave_bg.visible = false
	# Layer 1-4 (TD-073): the plate plus its independently animated cloth, props, fire and
	# atmosphere. Every asset is optional, so this renders correctly while the authored pieces
	# are still being produced (specs/title-scene/asset-manifest.md).
	if is_instance_valid(_title_env):
		_title_env.queue_free()
	_title_env = TitleScene.build(_title_host, _reduced_motion)
	_status.visible = false        # the title carries no status line (R232) — it is an image
	var vp := get_viewport_rect().size

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, vp.y * 0.17)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(spacer)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	_root.add_child(col)

	# The environment carries no title now (the concept-art plate is gone, TD-073), so the UI
	# renders the device, the title and its rule again — independent of every environment layer.
	var mark := TextureRect.new()
	mark.texture = load("res://assets/ui/board/collegium_logo.png") as Texture2D
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # or the VBox lets it grow without bound
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mark.custom_minimum_size = Vector2(44, 38)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.modulate = Color(0.80, 0.72, 0.56, 0.92)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(mark)
	col.add_child(_menu_gap(2))
	col.add_child(Widgets.engraved_line("TESTAMENT", 26, Color(0.86, 0.72, 0.42), 700))
	col.add_child(_menu_gap(3))
	var rule := Widgets.hrule(Color(0.62, 0.50, 0.31, 0.75))
	rule.custom_minimum_size = Vector2(190, 1)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(rule)
	col.add_child(_menu_gap(24))
	# The recovery path is listed FIRST and only when there is something live to return to —
	# never a dead option (R232). Canon I7 keeps expedition state ephemeral, so this rejoins a
	# running expedition; it is not a save-game load.
	var first: Button = null
	if _reconnect_token != "":
		first = _title_option(col, "Return to your expedition", func():
			if _net.is_open():
				_awaiting_resume = true
				_net.send_message(Protocol.RECONNECT, {"token": _reconnect_token})
			else:
				_set_status("still connecting, try again in a moment"))
	# New Expedition is NOT a screen (R287, the author's call): it creates the room and puts you in
	# the Collegium. `ROOM_CREATED` already routes to the lobby and the lobby already IS the walkable
	# Collegium, so this is a deletion — the form was the only thing standing in the way.
	var fresh := _title_option(col, "New Expedition", func(): _begin_new_expedition())
	_title_option(col, "Join Expedition", func(): _show_join())
	_title_option(col, "Options", func(): _show_options())
	_title_option(col, "Quit", func(): get_tree().quit())
	# Something is always marked: an unselected menu would read as the sigils having failed to load.
	# Whichever option is listed first takes it, which is the recovery path when there is one.
	(first if first != null else fresh).grab_focus.call_deferred()

	_title_version()
	_title_arrival(col)

# The build, bottom-right, dim enough to be furniture. Read from `application/config/version` in
# project.godot (which mirrors the workspace package.json) rather than written here, so the corner
# of the menu cannot quietly drift from what the repo says the build is (R266).
# NOTE: project.godot is a Godot ConfigFile — comments there start with `;`, not `#`. A `#` line
# silently breaks the section it sits in, which is how this setting first read back as empty.
func _title_version() -> void:
	var v := str(ProjectSettings.get_setting("application/config/version", ""))
	if v == "":
		return
	var l := Label.new()
	l.text = "v" + v
	l.add_theme_font_size_override("font_size", 7)
	l.add_theme_color_override("font_color", Color(0.78, 0.70, 0.54, 0.62))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Anchors AND offsets, with a margin. `set_anchors_preset` alone leaves the offsets at zero, so
	# the label collapses into the corner at zero size and never draws — the same trap the title
	# rig's own comment records for FULL_RECT.
	# Lifted clear of the connection status, which is also anchored bottom-right — they overlapped
	# (R305, spotted while capturing the join writ).
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 6)
	l.offset_top -= 13
	l.offset_bottom -= 13
	# Parented to the ENVIRONMENT, not to `_root` or the host: `_root` is the menu column and would
	# put a version string into the layout flow, while the host outlives the title screen — the
	# environment is freed on the way out (`_clear_title`), so the string leaves with it.
	_title_env.add_child(l)

# Arrival: the screen settles in rather than appearing all at once (R266). It runs ONCE per launch
# — coming back to the title from a room replays the hall, not the ceremony, because a flourish you
# have already seen on the way in reads as a stutter on the way back.
func _title_arrival(col: VBoxContainer) -> void:
	if _reduced_motion or _title_arrived:
		return
	_title_arrived = true
	# Every direct child, in column order: device, title, rule, then the options. The invisible
	# spacers are included and cost nothing — filtering them out needs a rule about which children
	# "count", and such a rule is exactly what silently stops matching after the next layout edit.
	var i := 0
	for c: Control in col.get_children():
		var to := c.modulate.a
		c.modulate.a = 0.0
		var t := c.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_interval(0.10 + 0.075 * i)
		t.tween_property(c, "modulate:a", to, 0.42)
		i += 1

# One title choice: gilt Cinzel on the nave, no button chrome — the screen is an image, and a
# row of stone-and-gold buttons would turn it back into a dialog. The SELECTED option is marked by
# a gilt sigil either side of it rather than by a focus rectangle, for the same reason.
func _title_option(host: Node, text: String, on_pressed: Callable) -> Button:
	return Widgets.choice(host, text, 13, on_pressed)

# The mark itself now lives in `Widgets.laurel` — the join writ marks focus with the same branch,
# so it is shared language rather than a thing this file owns (TD-080).
func _menu_sigil(pointing_right: bool) -> TextureRect:
	return Widgets.laurel(pointing_right)

# ── Room setup ──────────────────────────────────────────────────────────────
# One screen deeper than the title: the plate that actually asks for what its path needs
# (R233). "create" wants only a name; "join" wants a name and a Room code.
## New Expedition: no screen at all (R287). The name is IDENTITY and lives on disk (TD-006), so the
## only thing that can stop us is not having one yet — and that is asked exactly once, ever.
func _begin_new_expedition() -> void:
	var who := _load_name()
	if who == "":
		_show_name_rite()
		return
	if not _require_connection():
		return
	_pending_join = true
	_net.send_message(Protocol.CREATE_ROOM, {"displayName": who})

## First run only: one writ asking who you are. Deliberately the same object as the join screen, so
## it reads as the Collegium taking your name rather than as a settings dialog.
func _show_name_rite() -> void:
	_screen = Screen.MENU
	_world.visible = false
	_clear(true)                       # the hall stays; we never left it
	if not is_instance_valid(_title_env):
		_title_env = TitleScene.build(_title_host, _reduced_motion)
	var vp := get_viewport_rect().size
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, vp.y * 0.20)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top)
	# The writ is centred the way the title's own column is: `_root` sits inside a ScrollContainer,
	# so a child's own SHRINK_CENTER does not settle it — a centred VBox host does.
	var host := VBoxContainer.new()
	host.alignment = BoxContainer.ALIGNMENT_CENTER
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_root.add_child(host)
	var w := WritForm.build(host, vp, "THE COLLEGIUM", [["YOUR NAME", "your name", ""]])
	_name_input = w["edits"][0]
	var col: VBoxContainer = w["column"]
	WritForm.action(col, "Take the name", func():
		var who := _name_input.text.strip_edges()
		if who == "":
			_set_status("the Collegium needs a name to enter you in its roll")
			_name_input.grab_focus()
			return
		_save_name(who)
		_begin_new_expedition())
	WritForm.action(col, "Back", func(): _show_title())
	WritForm.arrive(w["sheet"], _reduced_motion)
	_name_input.grab_focus.call_deferred()

## Is the player inside an expedition — the only place a way out is needed? The title has Quit on it
## already, and a writ has its own Back.
func _in_expedition() -> bool:
	return _screen == Screen.LOBBY or _screen == Screen.DEPLOYING or _screen == Screen.FIELD

func _open_pause() -> void:
	if _pause != null:
		return
	_pause = PauseMenu.build(_pause_host, _reduced_motion,
		func(): _close_pause(),
		func():
			# Tell the server we are going before we go. The room is authoritative and would
			# eventually time us out, but leaving quietly would strand the party with a ghost until
			# it did (the lobby-resilience lesson, TD-032).
			_close_pause()
			if _net.is_open():
				_net.send_message(Protocol.LEAVE_ROOM)
			_reset_session()
			_show_title(),
		func(): get_tree().quit())

func _close_pause() -> void:
	if _pause == null:
		return
	_pause.queue_free()
	_pause = null

## Options: the same writ as everything else, because a settings screen that looked like a settings
## screen would undo four specs of work. The NAME is the point of it — TD-080 asks once and then
## leaves it on disk with no way to change it — and the rest is deliberately thin.
func _show_options() -> void:
	_screen = Screen.MENU
	_world.visible = false
	_clear(true)                       # the hall stays; we never left it
	if not is_instance_valid(_title_env):
		_title_env = TitleScene.build(_title_host, _reduced_motion)
	var vp := get_viewport_rect().size
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, vp.y * 0.16)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top)
	var host := VBoxContainer.new()
	host.alignment = BoxContainer.ALIGNMENT_CENTER
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_root.add_child(host)

	var w := WritForm.build(host, vp, "OPTIONS", [["YOUR NAME", "your name", _load_name()]])
	var name_field: LineEdit = w["edits"][0]
	var col: VBoxContainer = w["column"]

	WritForm.gap(col, 6)
	WritForm.toggle(col, "Reduced motion", _reduced_motion, func(v: bool):
		_reduced_motion = v
		_settings.reduced_motion = v
		_settings.save())
	# Real, not a prop: it drives the master bus and persists. There is simply nothing to hear yet —
	# the game ships no audio (T262 is blocked on there being no sanctioned audio tool), and a
	# slider that silently did nothing would be worse than one that is honest about it.
	WritForm.gap(col, 6)
	WritForm.slider(col, "VOLUME  (no sound ships yet)", _settings.volume, func(v: float):
		_settings.volume = v
		_settings.apply_audio()
		_settings.save())

	WritForm.action(col, "Set it down", func():
		var who := name_field.text.strip_edges()
		if who == "":
			# The same refusal the first-run rite makes: P140 must not weaken because there is now a
			# second way to set the name.
			_set_status("the Collegium needs a name to enter you in its roll")
			name_field.grab_focus()
			return
		_save_name(who)
		_show_title())
	WritForm.action(col, "Back", func(): _show_title())
	WritForm.arrive(w["sheet"], _reduced_motion)
	name_field.grab_focus.call_deferred()

## Join Expedition: the ONE dedicated scene (the author's ruling), and it is a writ on the hall.
func _show_join() -> void:
	_screen = Screen.MENU
	_setup_mode = "join"
	_world.visible = false
	_clear(true)                       # the hall stays behind it — no rebuild, no flicker (R290)
	if not is_instance_valid(_title_env):
		_title_env = TitleScene.build(_title_host, _reduced_motion)
	var vp := get_viewport_rect().size
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, vp.y * 0.20)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top)
	# The writ is centred the way the title's own column is: `_root` sits inside a ScrollContainer,
	# so a child's own SHRINK_CENTER does not settle it — a centred VBox host does.
	var host := VBoxContainer.new()
	host.alignment = BoxContainer.ALIGNMENT_CENTER
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_root.add_child(host)
	var w := WritForm.build(host, vp, "JOIN EXPEDITION", [
		["YOUR NAME", "your name", _load_name()],
		["ROOM CODE", "e.g. ABC234", ""],
	])
	_name_input = w["edits"][0]
	_code_input = w["edits"][1]
	var col: VBoxContainer = w["column"]
	var join := func():
		var who := _name_input.text.strip_edges()
		if who == "":
			_set_status("enter your name first")
			_name_input.grab_focus()
			return
		var code := _code_input.text.strip_edges().to_upper()
		if code == "":
			_set_status("enter a room code to join")
			_code_input.grab_focus()
			return
		if not _require_connection():
			return
		_save_name(who)
		_pending_join = true
		_net.send_message(Protocol.JOIN_ROOM, {"code": code, "displayName": who})
	WritForm.action(col, "Present the writ", join)
	WritForm.action(col, "Back", func(): _show_title())
	WritForm.arrive(w["sheet"], _reduced_motion)
	_code_input.text_submitted.connect(func(_t: String): join.call())
	_name_input.grab_focus.call_deferred()

# Menu control type size. The plate is budgeted to fit 360 logical px without scrolling: at the
# theme default (~17) the fields alone overflowed and the Resume block fell off the bottom.
const MENU_FS := 11

# The nave plate's authored size and its darkest value. Drawn at an INTEGER multiple and centred,
# with _nave_bg filling the remainder in the same black, so the pixel grid never softens (R231).
const NAVE_SIZE := Vector2(640, 360)
const NAVE_BLACK := Color(6.0 / 255.0, 5.0 / 255.0, 7.0 / 255.0)

# Size and centre the nave at the largest integer scale that fits the viewport (never below 1x —
# a window smaller than the plate crops rather than blurs).
func _fit_nave() -> void:
	if not is_instance_valid(_nave):
		return
	var vp := get_viewport_rect().size
	var k := maxf(1.0, floorf(minf(vp.x / NAVE_SIZE.x, vp.y / NAVE_SIZE.y)))
	_nave.size = NAVE_SIZE * k
	_nave.position = ((vp - _nave.size) * 0.5).floor()

# A small gilt section caption above a control group.
func _menu_gap(h: int) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, h)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g

# A full-width menu button on the plate. `_button` appends to _root and shrink-begins, which is
# what made the old menu a ragged left-aligned stack.
func _menu_action(host: Node, text: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", MENU_FS)
	b.pressed.connect(on_pressed)
	host.add_child(b)

# The trimmed name to act under, or "" with an inline hint when the field is empty. Refusing here
# sends NOTHING — an affordance guard, never authority: the server validates the name regardless.
# Refuse an action that needs the server, and SAY SO. `NetClient.send_message` drops the
# message when the socket is closed (`if is_open()`, no else), so Create/Join with no server
# running did nothing at all: no error, no toast, no status — the button just looked broken.
# Silence is the worst failure mode a button has. Returns true when it is safe to send.
func _require_connection() -> bool:
	if _net != null and _net.is_open():
		return true
	var msg := "no connection to the Collegium — is the server running? (pnpm dev:server)"
	_set_status("✝ " + msg)
	_show_toast("✝ " + msg)   # top-centre: the status line is small, quiet and easy to miss
	return false

func _show_lobby() -> void:
	_screen = Screen.LOBBY
	_clear()
	# The lobby's HUD is the room scroll (TD-071/R228): closed by default so the walkable
	# Collegium is unobstructed, opened with Tab. No standing labels over the world — that
	# collision with the station markers and the Seeker is what this replaces.
	if not is_instance_valid(_room_scroll):
		_room_scroll = RoomScroll.new()
		_room_scroll.ready_toggled.connect(func(): _net.send_message(Protocol.TOGGLE_READY))
		_room_scroll.leave_pressed.connect(func():
			_net.send_message(Protocol.LEAVE_ROOM)
			_reset_session()
			_show_title())
		_room_scroll.kick_requested.connect(func(pid: String):
			_net.send_message(Protocol.KICK_PLAYER, {"playerId": pid}))
		_scroll_layer.add_child(_room_scroll)
	_room_scroll.visible = true
	_room_scroll.refresh(_snapshot, _self_id)
	_render_space()
	# Initial/authoritative body sync: the lobby snapshot carries everyone's spawn
	# position, so spawn (and prune) bodies here. Without this the local body would
	# not exist until the first POSITIONS delta — i.e. it would only appear once you
	# moved. POSITIONS deltas drive movement after this (full=true also prunes leavers).
	_apply_positions(_snapshot.get("positions", {}), true)

func _show_deploying() -> void:
	_screen = Screen.DEPLOYING
	_clear()
	var c: Dictionary = _snapshot.get("contract") if _snapshot.get("contract") != null else {}
	Widgets.h1(_root, "Contract: %s" % c.get("targetName", "?"))
	_label("site: %s    tier: %s    verb: %s" % [c.get("siteName", "?"), c.get("tier", "?"), c.get("primaryVerb", "?")])
	_label("")
	_h2("Party bags")
	for p in _snapshot.get("players", []):
		_party_row(p)
	_render_space()
	# Same initial/authoritative body sync as the lobby (see _show_lobby): DEPLOYING
	# keeps the Collegium walkable, so keep bodies placed from the snapshot.
	_apply_positions(_snapshot.get("positions", {}), true)

func _show_field() -> void:
	_screen = Screen.FIELD
	_clear()
	Widgets.h1(_root, "The Field: %s" % _field.get("siteName", "?"))
	_label("target: %s" % _field.get("incarnateName", "?"))
	_label("you perceive: %s" % (", ".join(_channels) if not _channels.is_empty() else "nothing (you packed no perception gear)"))
	_label("party exposure: %d" % _exposure)
	_label("")
	_h2("Signs you can read")
	if _signs.is_empty():
		_label("(nothing yet; observe, then probe)")
	for s in _signs:
		_label("[%s]  %s" % [s["channel"], s["token"]])
	_label("")
	_h2("Probe (needs the matching kit)")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_root.add_child(row)
	for stim in Catalog.STIMULI:
		var b := Button.new()
		b.text = "Present %s" % stim
		b.pressed.connect(func(): _net.send_message(Protocol.PROBE, {"stimulus": stim}))
		row.add_child(b)
	for line in _probe_log:
		_label(line)
	_label("")
	_render_space()

func _show_testament() -> void:
	_screen = Screen.TESTAMENT
	_world.visible = false
	_clear()
	Widgets.h1(_root, "Field Testament")
	_label("outcome: %s" % _testament.get("outcome", "?"))
	_label("expedition: %s" % _testament.get("expeditionId", "?"))
	_label("")
	_h2("The Archive")
	for e in _archive:
		_label("%s at %s, %s: %s" % [e.get("targetName", "?"), e.get("siteName", "?"), e.get("outcome", "?"), e.get("notes", "")])
	_label("")
	_button("Return to the Collegium", func():
		_reset_session()
		_show_title())

func _show_reconnecting() -> void:
	_screen = Screen.RECONNECTING
	_world.visible = false
	_clear()
	Widgets.h1(_root, "Connection lost")
	if _reconnect_token == "":
		_label("No expedition to return to.")
		_button("Back to menu", func():
			_reset_session()
			_show_title())
	else:
		_label("Your party holds your place. Reconnect to resume.")
		_button("Reconnect", func():
			_set_status("reconnecting...")
			_net.open(_server_url()))
		_button("Abandon (back to menu)", func():
			_reset_session()
			_show_title()
			_net.open(_server_url()))

# ── Walkable world ───────────────────────────────────────────────────────────
# The client renders server truth and sends only intents. A body moves only when
# a server position arrives (never from input); station proximity is a display
# affordance, never an authorization (R104/R106/R108).

func _process(_delta: float) -> void:
	_follow_camera()
	_update_stations()
	_send_move_intent()
	# Keep the carved frame overlay glued to the popup (it slides in / re-centres on resize).
	if _board_frame != null and _board_frame.visible and _popup != null:
		_board_frame.global_position = _popup.global_position
		_board_frame.size = _popup.size

# Interaction: E opens the station in range, Esc closes an open popup. Discrete
# key edges (not held), read by physical location.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_E and _active_station != "" and not _menu_open:
		_open_station(_active_station)
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_ESCAPE and _pause != null:
		# The menu is its own top layer, so it answers Escape before anything underneath does.
		_close_pause()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_ESCAPE and _menu_open:
		# ESC steps back one layer for a keyboard user (T146): a taken-down writ returns to the
		# wall first (the Return button is deliberately focus-less), then ESC closes the station.
		if _popup_kind == "CONTRACT_BOARD" and not _board_selection.is_empty():
			_select_board_card({})
		else:
			_close_station()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_ESCAPE and _screen == Screen.MENU:
		# On a writ, Escape is Back — the same thing its own action does, which is what a player
		# already expects from the key.
		_show_title()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_ESCAPE and _in_expedition():
		_open_pause()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_TAB and _screen == Screen.LOBBY and not _menu_open \
			and is_instance_valid(_room_scroll) and _room_scroll.visible:
		_room_scroll.toggle()            # the Contract Board owns Tab while its popup is up
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F9:
		# Reduced-motion toggle (playtest lever L5): freeze torch flicker, pin the glow
		# to peak brightness. Motion is atmosphere only — the static board loses no info.
		_reduced_motion = not _reduced_motion
		# The key and the setting are the same thing; letting them disagree would mean the options
		# screen shows something the game is not doing.
		if _settings != null:
			_settings.reduced_motion = _reduced_motion
			_settings.save()
		_log("reduced_motion=%s" % _reduced_motion)
		if _menu_open and _popup_kind == "CONTRACT_BOARD":
			_rebuild_popup_body()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F11:
		# Fullscreen toggle. Integer scaling holds in both modes, so the pixel grid
		# never softens — an odd screen letterboxes rather than scaling fractionally.
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		get_viewport().set_input_as_handled()

# Pick the space for the current phase and hand it to the render-only SpaceView.
# Renders the grid + markers only — positions are applied by the position-bearing
# handlers (initial sync, POSITIONS deltas, field spawn, resync), never re-snapped
# on a cosmetic rebuild (that would clobber live movement with a stale snapshot).
func _render_space() -> void:
	match _phase():
		Protocol.PHASE_WAITING, Protocol.PHASE_DEPLOYING:
			var c: Variant = _snapshot.get("collegium")
			if c == null:
				_world.visible = false
				return
			_space.set_space(c["grid"], c["stations"])
			_world.visible = true
			_log("phase=%s grid=%dx%d" % [_phase(), int(c["grid"]["width"]), int(c["grid"]["height"])])
		Protocol.PHASE_FIELD:
			if _field_site.is_empty():
				_world.visible = false
				return
			_space.set_space(_field_site["grid"], _field_site["nodes"])
			_world.visible = true
			_log("phase=FIELD grid=%dx%d" % [int(_field_site["grid"]["width"]), int(_field_site["grid"]["height"])])
		_:
			_world.visible = false

# Create/move a body per playerId at its feet px. `full` (a snapshot/resync full
# set) also prunes bodies no longer present; a `false` POSITIONS delta never
# prunes and touches only named players (mirrors server delta discipline, I6).
func _apply_positions(positions: Dictionary, full: bool) -> void:
	var before := _bodies.size()
	for pid in positions:
		var p: Dictionary = positions[pid]
		var feet := Vector2(float(p["x"]), float(p["y"]))
		var b: Player = _bodies.get(pid)
		if b == null:
			b = BODY.instantiate()
			_body_root.add_child(b)
			b.setup(feet, pid == _self_id, _display_name_plain(pid))
			_bodies[pid] = b
		else:
			b.target = feet
			b.is_self = (pid == _self_id)
	if full:
		for pid in _bodies.keys():
			if not positions.has(pid):
				_bodies[pid].queue_free()
				_bodies.erase(pid)
	if _bodies.size() != before:   # only on a real join/leave, not every 20 Hz delta
		_log("bodies=%d" % _bodies.size())

func _clear_bodies() -> void:
	for b in _bodies.values():
		b.queue_free()
	_bodies.clear()

func _phase() -> String:
	return str(_snapshot.get("phase", ""))

# A body to steer exists only in a walkable phase with a rendered world.
func _walkable() -> bool:
	if not _world.visible:
		return false
	var ph := _phase()
	return ph == Protocol.PHASE_WAITING or ph == Protocol.PHASE_DEPLOYING or ph == Protocol.PHASE_FIELD

# Emit MOVE only on an intent *edge* (a key down/up), plus one {0,0} when leaving
# a walkable phase — the server keeps applying the last intent each tick, so
# resending every frame would be noise. Raw {-1,0,1}; the server normalizes.
func _send_move_intent() -> void:
	if not _walkable() or _menu_open:   # a menu open freezes the Seeker in place
		if _last_intent != Vector2i.ZERO:
			_net.send_message(Protocol.MOVE, {"dx": 0, "dy": 0})
			_last_intent = Vector2i.ZERO
		return
	var v := Vector2i(
		_dir_axis(KEY_D, KEY_RIGHT, KEY_A, KEY_LEFT),
		_dir_axis(KEY_S, KEY_DOWN, KEY_W, KEY_UP))
	# Default is run; holding Shift asks the server for the slower walk register.
	# The walk flag only matters while moving, so a shift toggle when standing
	# still (v == 0) does not spam an edge — the next real move sends the current
	# state. Speed itself is the server's decision (I1); this only sends intent.
	var walk := Input.is_physical_key_pressed(KEY_SHIFT)
	var moving := v != Vector2i.ZERO
	if v != _last_intent or (moving and walk != _last_walk):
		_last_intent = v
		_last_walk = walk
		_net.send_message(Protocol.MOVE, {"dx": v.x, "dy": v.y, "walk": walk})
		_log("MOVE dx=%d dy=%d walk=%s" % [v.x, v.y, walk])

# WASD (primary) or arrow keys, read by *physical* location so it's layout-agnostic.
func _dir_axis(pos_a: Key, pos_b: Key, neg_a: Key, neg_b: Key) -> int:
	var pos := Input.is_physical_key_pressed(pos_a) or Input.is_physical_key_pressed(pos_b)
	var neg := Input.is_physical_key_pressed(neg_a) or Input.is_physical_key_pressed(neg_b)
	return int(pos) - int(neg)

# ── Stations ─────────────────────────────────────────────────────────────────
# The prompt/popup are pure client affordances off the server-given position; the
# station action is still an intent the server re-validates (NOT_AT_*), R106/R108.

# The procedural charge prose (headline / preamble / charge / signature) now lives
# in `Notice` (scripts/board/notice.gd), keyed off ContractIntel + contractId.

# The asserted-Origin gloss shown beside the wax seal in a charge's detail. A
# claim the contract makes (falsifiable), never the hidden roll (GLOSSARY: Origin).
func _update_stations() -> void:
	if _menu_open:
		_prompt.visible = false
		return
	_active_station = _nearest_station()
	_prompt.visible = _active_station != ""
	if _prompt.visible:
		_prompt.text = "Press E: %s" % StationNames.of(_active_station)

# Kind of the station whose centre the local body stands within, else "". Reads
# the local body's server target (feet px), never an integrated guess.
func _nearest_station() -> String:
	if not _world.visible:
		return ""
	var me: Variant = _self_pos()
	if me == null:
		return ""
	var ph := _phase()
	if ph == Protocol.PHASE_WAITING or ph == Protocol.PHASE_DEPLOYING:
		var c: Variant = _snapshot.get("collegium")
		if c == null:
			return ""
		for s in c["stations"]:
			if me.distance_to(_center_px(s["x"], s["y"])) <= STATION_RADIUS:
				return str(s["kind"])
	elif ph == Protocol.PHASE_FIELD and not _field_site.is_empty():
		for n in _field_site["nodes"]:
			if str(n["kind"]) == "EXTRACTION" and me.distance_to(_center_px(n["x"], n["y"])) <= EXTRACTION_RADIUS:
				return "EXTRACTION"
	return ""

func _self_pos() -> Variant:
	var b: Player = _bodies.get(_self_id)
	if b == null:
		return null
	return b.target

func _center_px(tx: int, ty: int) -> Vector2:
	return Vector2(tx * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)

func _open_station(kind: String) -> void:
	_menu_open = true
	_popup_kind = kind
	_board_selection = {}          # a fresh open starts on the board grid, not a detail
	_prompt.visible = false
	_popup_title.text = StationNames.of(kind)
	_popup_title.visible = true                                    # board builder hides it (uses a placard)
	_popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # board builder re-centres its own
	# The Contract Board wears a wooden-board skin and fills the screen like a real
	# commission wall; every other station keeps the compact gothic-stone panel.
	_stone_bg.visible = (kind == "CONTRACT_BOARD")
	# The board's Close button is dropped (Esc still closes): v1 has no button bar, and
	# the extra row was pushing the frame's top/bottom rails off-screen. The bottom-of-screen
	# keybind strip stands in for it (board only).
	_popup_close.visible = (kind != "CONTRACT_BOARD")
	if _keyhint != null:
		_keyhint.visible = (kind == "CONTRACT_BOARD")
	if kind == "CONTRACT_BOARD":
		# Transparent panel that only supplies the content inset (the frame is drawn by the
		# shader-lit _board_frame overlay); keeps the canvas layout identical to the old skin.
		var clear := StyleBoxFlat.new()
		clear.bg_color = Color(0, 0, 0, 0)
		clear.set_content_margin_all(20)
		_popup.add_theme_stylebox_override("panel", clear)
		_popup_scroll.custom_minimum_size = _board_inner_size()
		_board_frame.material = BoardDecor.surface_material(get_viewport_rect().size, "res://assets/ui/board/frame_v1_n.png", 0.40, 1.0)
		_board_frame.visible = true
	else:
		_popup.remove_theme_stylebox_override("panel")
		_popup_scroll.custom_minimum_size = Vector2(400, 240)
		if _board_frame != null:
			_board_frame.visible = false
	_clear_popup_body()
	_build_station_content(kind)
	_animate_body_in()
	_slide_popup_in()

# Slide the popup up from just below the screen to centre, backdrop fading in with
# it. Relatively quick (~0.3s, cubic ease-out). The await lets the PanelContainer
# compute its size so we can centre it; killing any in-flight tween keeps it
# re-entrant against a fast close→open.
func _slide_popup_in() -> void:
	if _popup_tween != null:
		_popup_tween.kill()
	_popup_dim.modulate.a = 0.0
	_popup_dim.visible = true
	await get_tree().process_frame
	if not _popup_dim.visible:            # closed during the wait
		return
	var vp := get_viewport_rect().size
	var target := ((vp - _popup.size) * 0.5).floor()
	_popup.position = Vector2(target.x, vp.y + 16.0)   # start off the bottom edge
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.tween_property(_popup_dim, "modulate:a", 1.0, 0.22).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(_popup, "position", target, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _close_station() -> void:
	_menu_open = false
	_popup_kind = ""
	_board_selection = {}
	if _keyhint != null:
		_keyhint.visible = false
	if not _popup_dim.visible:
		return
	if _popup_tween != null:
		_popup_tween.kill()
	# Drop back down a little and fade out, then hide + clear.
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.tween_property(_popup_dim, "modulate:a", 0.0, 0.16).set_ease(Tween.EASE_IN)
	_popup_tween.tween_property(_popup, "position:y", _popup.position.y + 40.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_popup_tween.chain().tween_callback(func():
		_popup_dim.visible = false
		_clear_popup_body())

# A quick fade-in of the popup body — used on open and on each grid⇄detail swap.
func _animate_body_in() -> void:
	_popup_body.modulate.a = 0.0
	var t := _popup_body.create_tween().set_ease(Tween.EASE_OUT)
	t.tween_property(_popup_body, "modulate:a", 1.0, 0.12)

# Detach immediately (not just queue_free) so a rebuild never shows the old and new
# content in the same frame.
func _clear_popup_body() -> void:
	for c in _popup_body.get_children():
		_popup_body.remove_child(c)
		c.queue_free()

# Rebuild the current station's body in place — used when a station view has inner
# navigation (the Contract Board grid ⇄ a card's detail). Fades the new content in.
func _rebuild_popup_body() -> void:
	_clear_popup_body()
	_build_station_content(_popup_kind)
	_animate_body_in()

# Per-station content. v1 reuses the existing verbs; the richer per-station UIs
# (contract list, arsenal) are a later spec.
func _build_station_content(kind: String) -> void:
	match kind:
		"CONTRACT_BOARD":
			_board_canvas = ContractBoard.build(_board_ctx())
		"QUARTERMASTER":
			var slots := Label.new()
			slots.text = _slots_text()
			_popup_body.add_child(slots)
			for item in Catalog.GEAR:
				var id: String = item["id"]
				var check := CheckBox.new()
				check.text = Catalog.item_label(item)
				check.button_pressed = id in _selected_items
				# Update selection + live slot count in place — no popup rebuild, so
				# the scroll position and the other checkboxes stay put.
				check.toggled.connect(func(on: bool):
					if on:
						if id not in _selected_items and _selected_items.size() >= Catalog.BAG_SLOTS:
							check.button_pressed = false  # revert; bag is full
							_set_status("the bag holds at most %d items" % Catalog.BAG_SLOTS)
							return
						if id not in _selected_items:
							_selected_items.append(id)
					else:
						_selected_items.erase(id)
					slots.text = _slots_text())
				_popup_body.add_child(check)
			_popup_button("Requisition (replaces your bag)", func(): _net.send_message(Protocol.REQUISITION, {"itemIds": _selected_items.duplicate()}))
		"DEPLOY_GATE":
			if _is_leader():
				_popup_button("DEPLOY the expedition", func(): _net.send_message(Protocol.DEPLOY))
			else:
				_popup_label("Only the party leader can deploy.")
		"EXTRACTION":
			_popup_button("EXTRACT: leave with what you learned", func(): _net.send_message(Protocol.EXTRACT))

func _slots_text() -> String:
	return "Requisition: %d of %d slots" % [_selected_items.size(), Catalog.BAG_SLOTS]

func _popup_label(text: String, parent: Node = null) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(parent if parent != null else _popup_body).add_child(l)

func _popup_button(text: String, on_pressed: Callable, parent: Node = null) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_pressed)
	(parent if parent != null else _popup_body).add_child(b)

# ── Contract Board glue (specs/notice-board) ─────────────────────────────────
# The wall, the writs and the sign all live in `board/` now (TD-067 T231). What is left here
# is the shell's half of the contract: the two Ctx builders that hand those modules what they
# need, the selection state they render from, and the intents they call back to send. The
# socket stays here because `_net` does (S3.5).

# Take-down-to-read (R123): a dim over the board + the enlarged writ centred on it.
# Clicking the dim (off the writ) returns it to the wall. Pure view state.
# Refresh ONLY the open reader on a stamp/lift (TD-065/R211/P120): free the ReaderOverlay
# and re-show it from the fresh snapshot — the seal state, animation (via the _seal_prev
# flip), the CONTRACT SEALED banner, and scroll continuity (R199) all ride this. The board
# notices, backing, decay, and TORCHES are untouched (add_torches is never called), so there
# is no frame hitch — the seal never exists outside the open reader, so a stamp never needs
# the board rebuilt.
func _refresh_open_reader() -> void:
	if not is_instance_valid(_board_canvas) or _board_selection.is_empty():
		_rebuild_popup_body()          # reader gone — fall back to the full rebuild
		return
	var overlay := _board_canvas.find_child("ReaderOverlay", false, false)
	if overlay != null:
		overlay.free()                 # immediate (not queue_free): no one-frame double overlay
	_show_notice_reader(_board_canvas, _board_selection)

# The board's inner area (inside the wood frame), against the live viewport. Several shell
# call sites need it (the popup scroll size, the reader Ctx), so the wrapper stays here.
func _board_inner_size() -> Vector2:
	return ContractBoard.inner_size(get_viewport_rect().size)

# Everything ContractBoard needs from the shell. The shell keeps the socket (S3.5): the board
# asks for a writ to be taken down (`on_select`) and for the reader to be laid on it
# (`show_reader`) through callbacks, and never sends anything itself.
func _board_ctx() -> ContractBoard.Ctx:
	var c := ContractBoard.Ctx.new()
	c.host = self
	c.body = _popup_body
	c.title = _popup_title
	c.stone = _stone_bg
	c.snapshot = _snapshot
	c.selection = _board_selection
	c.reduced_motion = _reduced_motion
	c.viewport = get_viewport_rect().size
	c.on_select = func(intel: Dictionary): _select_board_card(intel)
	c.show_reader = func(canvas: Control, intel: Dictionary) -> Control: return _show_notice_reader(canvas, intel)
	c.logger = func(msg: String): _log(msg)
	return c

# Everything NoticeReader needs from the shell. The shell keeps the socket (S3.5): the reader
# calls back through on_seal/on_dismiss rather than sending anything itself.
func _reader_ctx(canvas: Control, intel: Dictionary) -> NoticeReader.Ctx:
	var c := NoticeReader.Ctx.new()
	c.host = self
	c.canvas = canvas
	c.intel = intel
	c.snapshot = _snapshot
	c.leader = _is_leader()
	c.reduced_motion = _reduced_motion
	c.parch = NoticeCard.parch_live()
	c.inner = _board_inner_size()
	var seeker := _display_name_plain(_self_id)
	c.seeker_name = "Seeker" if seeker.is_empty() or seeker == _self_id else seeker
	c.on_dismiss = func(): _select_board_card({})
	c.on_seal = func(cid: String, selected: bool):
		if selected:
			_net.send_message(Protocol.DESELECT_CONTRACT, {})
		else:
			_net.send_message(Protocol.SELECT_CONTRACT, {"contractId": cid})
	c.logger = func(msg: String): _log(msg)
	return c

func _show_notice_reader(canvas: Control, intel: Dictionary) -> Control:
	return NoticeReader.show(_reader_ctx(canvas, intel))

func _select_board_card(c: Dictionary) -> void:
	_board_selection = c
	if c.is_empty():
		NoticeReader.forget()            # closing forgets the scroll (R199) and the seal memory (R200)
	else:
		_log("select %s" % c.get("contractId", ""))
	# Taking a writ down / putting it back changes exactly TWO things: the reader overlay, and
	# the selected writ's lean. The board underneath — the backing shader, all 8 writs and their
	# NoticeCard.fit measuring, the decay, and add_torches' CPUParticles — is byte-identical either
	# way, so rebuilding it was pure waste and the hitch you feel on open/close. Swap the overlay
	# in place instead (P123: the TD-065 stamp lesson applied to the open/close path; S6 — update
	# the smallest subtree that reflects the change). No canvas ⇒ fall back to the full rebuild.
	if _popup_kind != "CONTRACT_BOARD" or not is_instance_valid(_board_canvas):
		var t := _popup_body.create_tween().set_ease(Tween.EASE_IN)
		t.tween_property(_popup_body, "modulate:a", 0.0, 0.07)
		t.tween_callback(_rebuild_popup_body)
		return
	var old := _board_canvas.find_child("ReaderOverlay", false, false) as Control
	ContractBoard.reset_transforms(self)
	if c.is_empty():
		# Back on the wall: retire the overlay on the same 0.07s the old cross-fade used. The
		# board never moved, so there is nothing else to restore — only focus, which the reader
		# had taken.
		if old != null:
			NoticeReader.retire(old)
		ContractBoard.focus_first.bind(self).call_deferred()
		return
	if old != null:
		old.free()                       # immediate: never two live overlays in one frame
	# Fade the reader in over the still board (the old 0.12s), so the takedown still reads as a
	# deliberate act — but the board behind it no longer blinks out and back.
	var ov := _show_notice_reader(_board_canvas, c)
	if ov != null:
		ov.modulate.a = 0.0
		var ft := ov.create_tween().set_ease(Tween.EASE_OUT)
		ft.tween_property(ov, "modulate:a", 1.0, 0.12)

# Client-side mirror of the server's ghost-proof allReady (connected players only);
# a display hint for the Accept affordance — the server remains the authority.
func _all_ready() -> bool:
	var players: Array = _snapshot.get("players", [])
	if players.is_empty():
		return false
	for p in players:
		if p.get("connected", true) and not p.get("readyState", false):
			return false
	return true

# A 9-slice StyleBox from a texture, with a flat fallback if the texture is missing
# or not yet imported (so the popup never breaks on a cold asset).
# A CanvasTexture pairs a diffuse with a NORMAL map, so Godot's 2D renderer lights the
# surface from the torch PointLight2Ds with real directional relief (TD-047 / board-lighting).
func _canvas_tex(diffuse: Texture2D, normal: Texture2D) -> CanvasTexture:
	var ct := CanvasTexture.new()
	ct.diffuse_texture = diffuse
	ct.normal_texture = normal
	ct.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return ct

func _texture_sb(path: String, margin: float, content: float, bg: Color, border: Color, mod_color: Color = Color.WHITE, normal_path: String = "") -> StyleBox:
	var tex := load(path) as Texture2D
	if tex != null:
		var sb := StyleBoxTexture.new()
		if normal_path != "":
			sb.texture = _canvas_tex(tex, load(normal_path) as Texture2D)   # normal-mapped, lit by torches
		else:
			sb.texture = tex
		sb.set_texture_margin_all(margin)
		sb.set_content_margin_all(content)
		sb.modulate_color = mod_color
		return sb
	var flat := StyleBoxFlat.new()
	flat.bg_color = bg
	flat.set_border_width_all(2)
	flat.border_color = border
	flat.set_content_margin_all(content)
	return flat

# "SIN" -> "Sin". The asserted origin, sentence-cased for display.
# Follow the local body, clamped inside the map; center on axes smaller than the
# view. Reads the body's server target, never an integrated guess.
func _follow_camera() -> void:
	if not _world.visible:
		return
	var b: Player = _bodies.get(_self_id)
	if b == null:
		return
	var bounds := _space.grid_size_px()
	if bounds == Vector2.ZERO:
		return
	var view := get_viewport_rect().size / _camera.zoom
	var half := view * 0.5
	var cam := b.position
	cam.x = bounds.x * 0.5 if bounds.x <= view.x else clampf(cam.x, half.x, bounds.x - half.x)
	cam.y = bounds.y * 0.5 if bounds.y <= view.y else clampf(cam.y, half.y, bounds.y - half.y)
	_camera.position = cam

func _display_name_plain(player_id: String) -> String:
	for p in _snapshot.get("players", []):
		if p["playerId"] == player_id:
			return p["displayName"]
	return player_id

func _log(msg: String) -> void:
	print("[client] ", msg)

# ── Helpers ──────────────────────────────────────────────────────────────────

func _player_row(p: Dictionary) -> String:
	var marks := ""
	if p.get("isLeader", false):
		marks += " ★"
	if p["playerId"] == _self_id:
		marks += " (you)"
	if not p.get("connected", true):
		marks += " (disconnected)"
	var ready_label := "ready" if p.get("readyState", false) else "not ready"
	var bag: Array = p.get("bag", [])
	var bag_note := "" if bag.is_empty() else "  |  bag: " + ", ".join(bag.map(func(i): return Catalog.short_name(i)))
	return "%s%s:  %s%s" % [p["displayName"], marks, ready_label, bag_note]

# One party member as a row: the text plus, for the leader looking at a
# disconnected teammate, a Kick button (server re-validates everything; P39
# means a connected player can never be kicked even if a stale row shows one).
func _party_row(p: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_root.add_child(row)
	var l := Label.new()
	l.text = _player_row(p)
	row.add_child(l)
	if _is_leader() and not p.get("connected", true) and p["playerId"] != _self_id:
		var pid: String = p["playerId"]
		var b := Button.new()
		b.text = "Kick"
		b.pressed.connect(func(): _net.send_message(Protocol.KICK_PLAYER, {"playerId": pid}))
		row.add_child(b)

func _display_name(player_id: String) -> String:
	for p in _snapshot.get("players", []):
		if p["playerId"] == player_id:
			return p["displayName"] + (" (you)" if player_id == _self_id else "")
	return player_id

func _is_leader() -> bool:
	for p in _snapshot.get("players", []):
		if p["playerId"] == _self_id:
			return p.get("isLeader", false)
	return false

func _reset_session() -> void:
	_self_id = ""
	_set_token("")
	_snapshot = {}
	_field = {}
	_field_site = {}
	_channels = []
	_signs = []
	_probe_log = []
	_exposure = 0
	_testament = {}
	_archive = []
	_selected_items = []
	_pending_join = false
	_last_intent = Vector2i.ZERO
	_active_station = ""
	_clear_bodies()
	if _popup_dim:
		_close_station()
	if _world:
		_world.visible = false

func _set_status(text: String) -> void:
	_status.text = text

## The reconnect token lives in MEMORY ONLY (TD-086).
##
## It used to be written to `user://reconnect-token.txt` and so outlived the client. But a room is
## **expedition state**, and canon is explicit that expedition state does not persist: I7 says rooms
## live in server memory and are lost on restart, and TD-006 lists what survives — identity,
## cosmetics, rank, customization, career stats. A seat in a room is none of those.
##
## The practical symptom was the title screen lying: it offered "Return to your expedition" on a
## fresh launch, for a room that had died with the previous server. In memory it still covers the
## case reconnect actually exists for — a network drop or a server hiccup while the client is
## running — and it can no longer promise something that is gone.
##
## The cost, stated plainly: if the CLIENT process itself dies mid-expedition, the seat is lost
## rather than resumable. That is the same bargain I7 already makes for the server.
func _set_token(token: String) -> void:
	_reconnect_token = token

func _save_name(name: String) -> void:
	var f := FileAccess.open(NAME_PATH, FileAccess.WRITE)
	if f:
		f.store_string(name)

func _load_name() -> String:
	if not FileAccess.file_exists(NAME_PATH):
		return ""
	var f := FileAccess.open(NAME_PATH, FileAccess.READ)
	return f.get_as_text().strip_edges() if f else ""

## Always empty — see `_set_token`. It also deletes any token left on disk by an older build, so an
## existing install stops offering its dead expedition on the very next launch rather than after the
## player clicks it once and gets an error.
func _load_token() -> String:
	if FileAccess.file_exists(TOKEN_PATH):
		DirAccess.remove_absolute(TOKEN_PATH)
	return ""

# ── UI builders ──────────────────────────────────────────────────────────────

## `keep_env` holds the title's environment alive across a screen change (TD-080). The join writ is
## laid over the SAME hall the player was just looking at, so rebuilding it would cost a full scene
## construction and produce a visible flicker at the one moment we are trying to make continuous.
func _clear(keep_env: bool = false) -> void:
	_close_pause()                 # never strand the Escape menu over the screen that follows
	for child in _root.get_children():
		child.queue_free()
	if is_instance_valid(_status):
		_status.visible = true     # only the title hides it; every other screen wants it back
	if is_instance_valid(_menu_bg):
		_menu_bg.visible = false      # the room setup turns it back on; other screens leave it off
	if is_instance_valid(_nave):
		_nave.visible = false
	if is_instance_valid(_room_scroll):
		_room_scroll.visible = false     # LOBBY turns it back on
	if is_instance_valid(_nave_bg):
		_nave_bg.visible = false
	if is_instance_valid(_title_env) and not keep_env:
		_title_env.queue_free()      # the title's tweens must not outlive the screen
		_title_env = null

func _h2(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	_root.add_child(l)

func _label(text: String) -> void:
	var l := Label.new()
	l.text = text
	_root.add_child(l)

func _button(text: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(on_pressed)
	_root.add_child(b)

func _make_line_edit(placeholder: String, initial: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.text = initial
	e.custom_minimum_size = Vector2(120, 0)
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(e)
	return e

# Take a control built by a _root-appending helper and hand it to another parent (the menu plate).
func _reparent_to(node: Control, host: Node) -> Control:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	host.add_child(node)
	return node
