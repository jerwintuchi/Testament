extends Node2D
## Testament client — the Phase 4 protocol walk: lobby → requisition → field → probe.
##
## Render + input only (trust boundary): every screen transition is caused by a
## server event; user input only ever *sends* an intention. All session state
## below is a render copy of what the server said, never locally derived.

enum Screen { MENU, LOBBY, DEPLOYING, FIELD, TESTAMENT, RECONNECTING }

# The wire-protocol contract, codegen'd from src/shared (pnpm gen:protocol). The
# server references the same names, so message types, error codes, phases, and the
# gear catalog never drift (TD-029/TD-030: preload, not a global class_name).
const Protocol = preload("res://protocol/protocol.gd")
const WaxSeal = preload("res://scripts/ui/wax_seal.gd")
const OrnamentScrollbar = preload("res://scripts/ui/ornament_scrollbar.gd")
const VerbBadge = preload("res://scripts/ui/verb_badge.gd")
const Notice = preload("res://scripts/ui/notice.gd")
const BoardGeo = preload("res://scripts/ui/board_geometry.gd")  # pure board layout/keep-out/seed math
const BoardDecor = preload("res://scripts/ui/board_decor.gd")   # torches + crest render factories
const BoardBar = preload("res://scripts/ui/board_bar.gd")       # bottom legend/assignment/status bar
const Fonts = preload("res://scripts/ui/fonts.gd")              # shared font builders (Cinzel)
const PopupTheme = preload("res://scripts/ui/popup_theme.gd")   # the station popup's gothic Theme
const RiteBanner = preload("res://scripts/ui/rite_banner.gd")   # the CONTRACT SEALED ceremony overlay

const SERVER_URL := "ws://localhost:3001"
# The reconnect token survives a client relaunch (R75). It is an opaque server
# secret, not game state — the one thing the client is allowed to remember.
const TOKEN_PATH := "user://reconnect-token.txt"

var _net: NetClient
var _screen: Screen = Screen.MENU

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
var _reader_open_cid := ""             # which notice the reader currently shows (R199 scroll continuity)
var _reader_scroll_mem := 0            # its last scroll offset, restored on a same-notice rebuild
var _seal_prev: Dictionary = {}        # cid -> sealed? at last build — detects stamp/lift for the ceremony (R200)
const SEAL_COOLDOWN_MS := 900          # stamp/lift interaction lockout ≈ the press length (R209)
var _seal_cooldown_until := 0          # Time.get_ticks_msec() until which the stamp is locked
var _focus_cid: String = ""            # contractId of the keyboard-focused writ, kept across rebuilds
var _wood_sb: StyleBox            # Contract Board panel skin — the carved 9-slice frame (board_frame.png)
var _backing_tex: Texture2D       # plank backing 9-slice, behind the notices
var _board_frame: NinePatchRect   # carved frame overlay, shader-lit; tracks the popup rect (TD-047)
var _parch_live: Array = []       # deckled LIVE parchment (warm, inner light) — 2 tear seeds (T143)
var _parch_flavor: Array = []     # deckled FLAVOR parchment (aged, foxed) — 2 tear seeds
var _tack_tex: Array = []         # nail · wax · pin · ribbon, seeded per live notice
var _cobweb_tex: Texture2D        # grayscale-additive corner decay strand (tinted at runtime)
var _votive_tex: Texture2D        # dead votive candle, ambient sacred-decay prop
var _stone_bg: TextureRect        # tiled stone/mortar surround, dim; Contract Board only
var _reduced_motion: bool = false # settings toggle (F9 in playtest): freeze flicker, pin glow to peak
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

	var layer := CanvasLayer.new()
	add_child(layer)
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
	_stone_bg.texture = load("res://assets/ui/stone_tile.png") as Texture2D
	_stone_bg.stretch_mode = TextureRect.STRETCH_SCALE          # UV 0..1; the shader does the tiling
	_stone_bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED   # so UV*tile_scale wraps the brick
	_stone_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp pixel brick, not blurred
	_stone_bg.material = _surface_material("res://assets/ui/stone_tile_n.png", 0.24, 1.0, Vector2(5.0, 4.2))
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
	_popup.theme = PopupTheme.build()  # 9-slice gothic panel + gold-on-charcoal controls
	_popup.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # soft painterly frame (v1 raster)
	# Skins swapped in per station: the Contract Board is a wooden board, its cards
	# pinned parchment. Built once; a missing texture falls back to a flat box.
	# Pass-2: the carved 9-slice frame is the board's panel skin; the plank backing
	# fills behind the notices; the stone/mortar tile is the surround. (Batch 1, T142.)
	# Painterly wooden frame sliced from the Prototype-v1 raster (TD-044): a 9-slice with
	# a transparent interior and the crest painted out (drawn separately). LINEAR-filtered.
	# Frame + backing: shader-lit like the wall once the wall proof lands (T149). Plain for now.
	_wood_sb = _texture_sb("res://assets/ui/frame_v1.png", 33.0, 20.0, Color(0.29, 0.19, 0.10), Color(0.45, 0.30, 0.15))
	_backing_tex = load("res://assets/ui/backing_v1.png") as Texture2D
	# Batch-2 detail assets (T143/T144): deckled parchment split live vs flavor, tacks,
	# and decay props. A missing texture is simply skipped (fallbacks below tolerate []).
	for i in 2:
		var lv := load("res://assets/ui/parch_v1_%d.png" % i) as Texture2D   # deckled cards on v1 painted paper
		if lv != null:
			_parch_live.append(lv)
		var fv := load("res://assets/ui/parch_flavor_%d.png" % i) as Texture2D
		if fv != null:
			_parch_flavor.append(fv)
	for tk in ["nail", "wax", "pin", "ribbon"]:
		var t := load("res://assets/ui/tack_%s.png" % tk) as Texture2D
		if t != null:
			_tack_tex.append(t)
	_cobweb_tex = load("res://assets/ui/cobweb.png") as Texture2D
	_votive_tex = load("res://assets/ui/votive.png") as Texture2D
	pcenter.add_child(_popup)
	# Carved frame overlay (TD-047): the board's frame is a shader-lit NinePatch that tracks the
	# popup rect from OUTSIDE the clipping ScrollContainer, so the torches light its relief (a
	# StyleBox can't hold a material, and an in-canvas frame is clipped). Shown for the board only.
	_board_frame = NinePatchRect.new()
	_board_frame.texture = load("res://assets/ui/frame_v1.png") as Texture2D
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
	_keyhint = _build_keyhint()
	_popup_dim.add_child(_keyhint)

	# Reflow the open station popup when the window resizes (e.g. fullscreen toggle),
	# so a board built for one resolution never lingers over-sized in another.
	get_viewport().size_changed.connect(_on_viewport_resized)

	_reconnect_token = _load_token()
	_net.open(SERVER_URL)
	_show_menu()

	# Dev-only: `-- --board-preview` opens the Contract Board over fixture intel, with no
	# server and no walking, so the board's art can be iterated against a screenshot
	# (DebugCapture). Render-only — it fabricates a *display* snapshot, never game state,
	# and no intent is ever sent from it. Debug builds only.
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--reduced-motion"):
		# Force the F9 reduced-motion lever on at startup so an unattended capture can
		# verify L5 (glow pinned to peak, flame frozen) without input injection.
		_reduced_motion = true
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--board-preview"):
		call_deferred("_board_preview")

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
		_focus_first_notice.call_deferred()
	# `-- --flash-preview` (implies --reader --sealed) spawns one impact flash on the reader
	# seal so a capture can show it blooming past the sheet edge, unclipped (TD-064/V1).
	if OS.get_cmdline_user_args().has("--flash-preview"):
		_flash_preview.call_deferred()
	_log("board preview: %d fixture contracts" % pv_board.size())

func _flash_preview() -> void:
	for _i in 6:
		await get_tree().process_frame          # let the deferred reader build + settle
	var seal := get_tree().root.find_child("ReaderSeal", true, false) as Control
	if seal != null:
		_spawn_seal_flash(seal, 0.0)            # bloom immediately; capture catches it mid-bloom

# Give keyboard nav a starting point on the board (T146 / L6): restore the writ that held
# focus before a rebuild (by contractId), else focus the reading-first (top-left) writ, so
# Tab immediately walks the grid and the corner reticle shows. (Groups aren't ordered, so
# reading order is derived geometrically: top row, then left-most.)
func _focus_first_notice() -> void:
	var cards := get_tree().get_nodes_in_group("live_notice")
	cards.sort_custom(func(a: Control, b: Control) -> bool:
		if absf(a.position.y - b.position.y) > 8.0:
			return a.position.y < b.position.y
		return a.position.x < b.position.x)
	if cards.is_empty():
		return
	if _focus_cid != "":
		for c in cards:
			if c is Control and str((c as Control).get_meta("cid", "")) == _focus_cid:
				(c as Control).grab_focus()
				return
	(cards[0] as Control).grab_focus()

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
	if _screen == Screen.MENU or _screen == Screen.TESTAMENT:
		_set_status("server offline. start it with: pnpm dev:server")
	else:
		_show_reconnecting()

# ── Screens ──────────────────────────────────────────────────────────────────

func _show_menu() -> void:
	_screen = Screen.MENU
	_world.visible = false
	_clear()
	_h1("TESTAMENT")
	_label("The Collegium is hiring. We seek truth, not certainty.")
	_name_input = _make_line_edit("display name", "Seeker")
	_button("Create Room", func():
		_pending_join = true
		_net.send_message(Protocol.CREATE_ROOM, {"displayName": _name_input.text}))
	_label("")
	_code_input = _make_line_edit("room code (e.g. ABC234)", "")
	_button("Join Room", func():
		_pending_join = true
		_net.send_message(Protocol.JOIN_ROOM, {"code": _code_input.text.strip_edges().to_upper(), "displayName": _name_input.text}))
	if _reconnect_token != "":
		_label("")
		_button("Resume unfinished expedition", func():
			if _net.is_open():
				_awaiting_resume = true
				_net.send_message(Protocol.RECONNECT, {"token": _reconnect_token})
			else:
				_set_status("still connecting, try again in a moment"))

func _show_lobby() -> void:
	_screen = Screen.LOBBY
	_clear()
	_h1("Lobby: room %s" % _snapshot.get("roomCode", "?"))
	_label("share the code aloud; the Collegium sends up to four")
	for p in _snapshot.get("players", []):
		_party_row(p)
	_label("")
	_button("Toggle Ready", func(): _net.send_message(Protocol.TOGGLE_READY))
	_label("Walk to the Contract Board and press E to accept.")
	_button("Leave Room", func():
		_net.send_message(Protocol.LEAVE_ROOM)
		_reset_session()
		_show_menu())
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
	_h1("Contract: %s" % c.get("targetName", "?"))
	_label("site: %s    tier: %s    verb: %s" % [c.get("siteName", "?"), c.get("tier", "?"), c.get("primaryVerb", "?")])
	_label("")
	_label("Walk to the Quartermaster (E) to requisition, the Deploy Gate (E) to deploy.")
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
	_h1("The Field: %s" % _field.get("siteName", "?"))
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
	_label("Walk to the Extraction and press E to leave.")
	_render_space()

func _show_testament() -> void:
	_screen = Screen.TESTAMENT
	_world.visible = false
	_clear()
	_h1("Field Testament")
	_label("outcome: %s" % _testament.get("outcome", "?"))
	_label("expedition: %s" % _testament.get("expeditionId", "?"))
	_label("")
	_h2("The Archive")
	for e in _archive:
		_label("%s at %s, %s: %s" % [e.get("targetName", "?"), e.get("siteName", "?"), e.get("outcome", "?"), e.get("notes", "")])
	_label("")
	_button("Return to the Collegium", func():
		_reset_session()
		_show_menu())

func _show_reconnecting() -> void:
	_screen = Screen.RECONNECTING
	_world.visible = false
	_clear()
	_h1("Connection lost")
	if _reconnect_token == "":
		_label("No expedition to return to.")
		_button("Back to menu", func():
			_reset_session()
			_show_menu())
	else:
		_label("Your party holds your place. Reconnect to resume.")
		_button("Reconnect", func():
			_set_status("reconnecting...")
			_net.open(SERVER_URL))
		_button("Abandon (back to menu)", func():
			_reset_session()
			_show_menu()
			_net.open(SERVER_URL))

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
	elif event.physical_keycode == KEY_ESCAPE and _menu_open:
		# ESC steps back one layer for a keyboard user (T146): a taken-down writ returns to the
		# wall first (the Return button is deliberately focus-less), then ESC closes the station.
		if _popup_kind == "CONTRACT_BOARD" and not _board_selection.is_empty():
			_select_board_card({})
		else:
			_close_station()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F9:
		# Reduced-motion toggle (playtest lever L5): freeze torch flicker, pin the glow
		# to peak brightness. Motion is atmosphere only — the static board loses no info.
		_reduced_motion = not _reduced_motion
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

const _STATION_LABEL := {
	"CONTRACT_BOARD": "Contract Board", "QUARTERMASTER": "Quartermaster",
	"DEPLOY_GATE": "Deploy Gate", "EXTRACTION": "Extraction",
}

# The procedural charge prose (headline / preamble / charge / signature) now lives
# in `Notice` (scripts/ui/notice.gd), keyed off ContractIntel + contractId.

# The asserted-Origin gloss shown beside the wax seal in a charge's detail. A
# claim the contract makes (falsifiable), never the hidden roll (GLOSSARY: Origin).
const ORIGIN_GLOSS := {
	"BELIEF": "a corrupted thought",
	"SIN":    "a corrupted deed",
	"RELIC":  "corrupted matter",
}

func _update_stations() -> void:
	if _menu_open:
		_prompt.visible = false
		return
	_active_station = _nearest_station()
	_prompt.visible = _active_station != ""
	if _prompt.visible:
		_prompt.text = "Press E: %s" % _STATION_LABEL.get(_active_station, _active_station)

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
	_popup_title.text = _STATION_LABEL.get(kind, kind)
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
		_board_frame.material = _surface_material("res://assets/ui/frame_v1_n.png", 0.40, 1.0)
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
			_build_contract_board()
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

# ── The Notice Board (specs/notice-board) ────────────────────────────────────
# A wooden installation, not a menu: portrait parchment notices tacked at seeded
# angles across the board (no scroll). The 4 live contracts are clickable; a few
# decorative flavor notices are inert ambiance. Clicking a live notice "takes it
# down" — it enlarges to centre over the dimmed board (a writ), where the party
# signs the charge. Every notice string comes from ContractIntel + contractId via
# `Notice`; nothing here is trait-derived or authoritative (I1/I3).

# Inert ambient notices — pure flavor (P65). No contractId, never selectable.
const FLAVOR_NOTICES := [
	{ "head": "ATTENTION", "body": "All bearers of unsanctioned relics must present them at the Reliquary before the next bell." },
	{ "head": "A PLEA", "body": "My brother went to the fens with the last party and has not returned. Leave any word with the Almoner." },
	{ "head": "NOTICE OF DECAY", "body": "The east chancel is closed by order of the Wardens. The ground is no longer trustworthy." },
	{ "head": "OBSERVANCE", "body": "Vespers are moved to the crypt until the upper nave is reconsecrated." },
]
# Live-contract anchor centres (fractions of the board's inner area). NOT a row —
# a loose scatter across the whole board so the wall reads like a maintained
# commission board (TD: dense organic scatter). Spread across quadrants so that,
# even at the largest sizes, live notices overlap only at corners and never bury
# another contract's headline/target; a seeded jitter loosens the grid further.
# Ash & Ember ink ramp. The headline is INK, never wax and never a per-verb hue: wax is
# the palette's lowest-luminance colour and fails the contrast floor as text.
const INK := Color("2A2115")
const INK_SOFT := Color("3D3120")   # darker: legible on v1's warm painted paper
# Live-tone floor (T145 / L1): a live writ's paper never composites darker than this warm
# ivory, so ink (INK/INK_SOFT) always clears the 4.5:1 contrast floor regardless of where on
# the wall the notice lands. Enforced on every live-paper modulate (incl. hover).
const TONE_FLOOR := Color("CBB583")
# Minimum interactive size for a live notice (T145 / L6): a touch/click target is never
# smaller than 44x44 even on a cramped viewport. The grid already exceeds this; this is the guard.
const HIT_MIN := Vector2(44.0, 44.0)
# The live-notice stack (backlight, shadow, card) draws at this z — above the wall vignette
# (z 2), below the bar (4) / placard (5) / reader (10). Keeps the writs off the shadowed wall.
const LIVE_Z := 3

# Clamp a colour so no channel falls below the live-tone floor (alpha untouched).
func _floor_tone(c: Color) -> Color:
	return Color(maxf(c.r, TONE_FLOOR.r), maxf(c.g, TONE_FLOOR.g), maxf(c.b, TONE_FLOOR.b), c.a)

# A gilt keyboard-focus ring (T146 / L6): a gold border + soft warm glow, drawn as a control's
# `focus` stylebox so Tab-traversal is always visible on the dark wall. Reused by the live
# notices and the seal stamp so keyboard focus reads the same everywhere.
func _focus_ring() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.95, 0.80, 0.38)          # gilt gold
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0.90, 0.68, 0.26, 0.55)    # warm bleed off the gilt edge
	sb.shadow_size = 5
	return sb

# A keyboard-focus reticle (T146 / L6): four BRIGHT corner brackets over a FAINT full-edge
# outline — the selection read from the reference. Drawn via the `draw` signal so it needs no
# separate script or asset; sits over its card, hidden until the card takes focus. Returns the
# reticle Control (add as the card's last child; toggle its visibility on focus).
func _focus_reticle() -> Control:
	var r := Control.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.visible = false
	r.draw.connect(func() -> void:
		var s := r.size
		var bright := Color(0.99, 0.87, 0.48)
		var faint := Color(0.93, 0.80, 0.44, 0.26)
		var arm := clampf(minf(s.x, s.y) * 0.24, 7.0, 18.0)
		# Faint hairline on all four edges.
		r.draw_rect(Rect2(Vector2.ZERO, s), faint, false, 1.0)
		# Bright L-brackets at each corner (thin, offset in a hair so the arms read as a frame).
		var corners := [
			[Vector2(0.5, 0.5), Vector2(1, 0), Vector2(0, 1)],
			[Vector2(s.x - 0.5, 0.5), Vector2(-1, 0), Vector2(0, 1)],
			[Vector2(0.5, s.y - 0.5), Vector2(1, 0), Vector2(0, -1)],
			[Vector2(s.x - 0.5, s.y - 0.5), Vector2(-1, 0), Vector2(0, -1)],
		]
		for c in corners:
			var o: Vector2 = c[0]
			r.draw_line(o, o + (c[1] as Vector2) * arm, bright, 1.0)
			r.draw_line(o, o + (c[2] as Vector2) * arm, bright, 1.0))
	r.resized.connect(r.queue_redraw)
	return r

# Theme a ScrollContainer's vertical bar to the board's idiom: a sunk wood/parchment channel
# with a slim brass grabber, in place of Godot's flat grey default. Reader + station scroll.
# Normalised inside BoardGeo.live_bounds(), not inside the whole canvas.
# Flavor scraps fill the gaps and the edges. Drawn BEHIND the live notices, so they
# may tuck under a contract (dense clutter) without ever stealing its click — they
# are inert (MOUSE_FILTER_IGNORE), pure ambiance (P65).
# Grid composition (Prototype-v1): flavor scraps are pinned in the side margins, clear
# of the centred grid and the torches — a couple of aged notes, not a scatter.
# Live-notice sizes span from small notes to big posters (dramatic variety). The
# pick is seeded from contractId and is PURELY aesthetic — size never encodes
# tier/importance (all contracts are equal-weight; the mystery is the mechanic).
# Sizes are FRACTIONS of the board's inner canvas, not pixels: the same wall must read
# at 640x360 (TD-042) and at any logical viewport PixelScale hands us. They were authored
# as pixels against an 840x364 canvas and converted here; ratios are unchanged.

# Reserved bands, as fractions of the inner canvas: the hanging placard along the top,
# and the flanking torch sconces down each side. Live paper never enters either.
# Torches now hang on the STONE WALL (outside the frame), so the board interior no
# longer reserves a wide side band for them — the grid fills nearly the full width,
# the way Prototype v1's writs do (dense, only a slim breathing margin from the frame).

# Snap to whole pixels: a parchment on a half-pixel is a blurred parchment (Nearest).
# Axis-aligned footprint of a `size` rect rotated by `tilt` degrees about its centre.
# The notice keeps its own size; only its *collision* footprint grows.
# Aged-parchment tints, seeded per notice — warm variety like a real board, without
# encoding anything (the wax seal carries Origin; this is pure aesthetics).

func _dump_notes(notes: Control) -> void:
	await get_tree().process_frame
	_log("notes children=%d canvas_global=%s" % [notes.get_child_count(), notes.get_global_rect()])
	for c in notes.get_children():
		var ct: Control = c
		_log("  %s pos=%v size=%v scale=%v min=%v" % [ct.get_class(), ct.position, ct.size, ct.scale, ct.custom_minimum_size])

func _build_contract_board() -> void:
	var board: Array = _snapshot.get("board", [])
	# The carved placard is the board's title now — hide the plain text header.
	_popup_title.visible = false
	# One canvas the wood frame wraps; notices are placed on it absolutely.
	var inner := _board_inner_size()
	var canvas := Control.new()
	canvas.custom_minimum_size = inner
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Text renders crisp: the popup panel is LINEAR (soft painted frame), but the notice
	# layer resets to NEAREST so labels stay sharp. Raster nodes (paper/backing/crest)
	# re-assert LINEAR on themselves, so only the fonts change.
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_popup_body.add_child(canvas)
	_board_canvas = canvas             # remembered so a stamp can refresh only the reader (TD-065)
	# Plank backing fills behind the notices (Batch 1). Backmost layer; the carved
	# frame is the popup panel skin, the stone surround shows around it.
	if _backing_tex != null:
		var backing := NinePatchRect.new()
		backing.texture = _backing_tex
		backing.set_anchors_preset(Control.PRESET_FULL_RECT)
		backing.patch_margin_left = 12
		backing.patch_margin_top = 12
		backing.patch_margin_right = 12
		backing.patch_margin_bottom = 12
		backing.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # painterly raster, keep it soft
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Torch-lit via the surface shader (TD-047): the dark backing_v1 is pre-lifted in-shader
		# (diffuse_gain) then lit by the torch rig — tests that a fragment shader preserves the
		# NinePatch 9-slice AND takes the dynamic light (the frame conversion depends on this).
		backing.material = _surface_material("res://assets/ui/backing_v1_n.png", 0.56, 1.25)  # TD-050: plank grain reads at rest, still below the parchment/frame key
		backing.modulate = Color(1.0, 1.0, 1.0)
		# z_index MUST stay >= 0: at -2 the plank drew BEHIND the popup's opaque panel
		# background and vanished, so the dark stone wall showed through ("see-through board").
		# Tree order (added before the notices) already keeps it behind the cards.
		backing.z_index = 0
		canvas.add_child(backing)
		# Age + use: a tiling grain/speckle overlay so the planks read weathered, not a flat
		# stretched slab (dark specks + faint lengthwise streaks, low alpha). Above the backing,
		# below the notices. Runtime texture, no import.
		var grain := TextureRect.new()
		grain.texture = BoardGeo.wood_grain_texture()
		grain.set_anchors_preset(Control.PRESET_FULL_RECT)
		grain.stretch_mode = TextureRect.STRETCH_TILE
		grain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		grain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grain.z_index = 0
		canvas.add_child(grain)
	# Flanking torches now hang on the STONE WALL beside the inset board (Prototype v1),
	# not inside the frame — banner + sconce + additive glow at each flank of the masonry
	# margin. Rendered on the stone layer in viewport space. Reduced-motion (F9) freezes it.
	# TD-059: the banner is now a normal-mapped surface lit by the SAME torch rig as the wall —
	# built here so the rig-uniform packing stays in `_surface_material` (P72/P102), passed in.
	var banner_mat := _surface_material("res://assets/ui/banner_v1_n.png", 0.36, 1.05, Vector2.ONE, 2.4)
	BoardDecor.add_torches(_stone_bg, get_viewport_rect().size, _reduced_motion, banner_mat)
	# The papers live in their own layer beneath the placard and the reader. A hovered
	# notice raises to front WITHIN this layer only, so dense overlap never lets a
	# paper float above the hanging sign (or over an open reading).
	var notes := Control.new()
	notes.set_anchors_preset(Control.PRESET_FULL_RECT)
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(notes)
	# Flavor scraps now read as a few small notes pinned in the side margins (as in the
	# reference), not a scatter across the wall — the grid of live writs owns the centre.
	# A light tilt keeps them from looking machine-placed; they draw behind the grid.
	# Prototype v1 is a clean framed grid — no side scraps intruding over the writs.
	# Flavor notices are opt-in (`--flavor`) until they get their own uncluttered band.
	var flavor_n := mini(BoardGeo.FLAVOR_SIDE_SLOTS.size(), FLAVOR_NOTICES.size()) if OS.get_cmdline_user_args().has("--flavor") else 0
	for i in flavor_n:
		var fslot: Vector2 = BoardGeo.FLAVOR_SIDE_SLOTS[i] + BoardGeo.seed_jitter("flavor-%d" % i) * 0.4
		var fsz := BoardGeo.notice_size(BoardGeo.FLAVOR_SIZE_FRACS, i, inner)
		var fnode := _make_flavor_notice(FLAVOR_NOTICES[i], i)
		_place(notes, fnode, fslot, fsz, BoardGeo.seed_tilt("flavor-%d" % i) * 0.6)
		if OS.is_debug_build():
			_log("  flavor[%d] want=%v got=%v pos=%v" % [i, fsz, fnode.size, fnode.position])
	# Live notices are laid out by the keep-out solver first (T145), so no petition can
	# ever bury another, then placed at the resolved rects. Flavor stays behind them.
	var placed := BoardGeo.layout_live(board, inner)
	var footprints: Array = []
	var min_hit := Vector2(INF, INF)   # smallest live hit-target, self-checked ≥ HIT_MIN (T145)
	for idx in placed.size():
		var intel: Dictionary = board[idx]
		var cid := str(intel.get("contractId", ""))
		# TD-061 (R192): the grid cell is the disjoint CEILING, not the writ. Each writ takes
		# its own content-fitted, seeded size inside the cell — non-uniform on purpose ("the
		# variability and uniqueness of each contract"), and long site names always fit.
		var fit := _fit_writ(intel, placed[idx]["size"])
		var size: Vector2 = fit["size"]
		var centre: Vector2 = placed[idx]["centre"]
		# A subtle hand-pinned lean (±~2.7°) so the writs read as tacked paper, not a printed
		# grid — small enough that the keep-out solver's cell gaps stay disjoint (self-checked).
		var tilt := BoardGeo.seed_tilt(cid) * 0.42
		# The whole live stack rides ABOVE the wall vignette (z 2): the vignette shapes the
		# corners of the WALL, never the writs (its own stated intent), so a live paper never
		# sinks below the legibility floor no matter where on the board it lands (T145 / L1, L3).
		var hit_size := Vector2(maxf(size.x, HIT_MIN.x), maxf(size.y, HIT_MIN.y))
		min_hit = Vector2(minf(min_hit.x, hit_size.x), minf(min_hit.y, hit_size.y))
		var pos := (centre - size * 0.5).floor()
		# Per-notice backlight: a warm amber pool behind the writ (additive), so the paper owns
		# its own light and reads even with the torches frozen or in a dim gutter (L3). Larger
		# than the paper so it haloes the wood around the sheet.
		var glow := TextureRect.new()
		glow.texture = BoardGeo.backlight_gradient()
		glow.material = BoardGeo.additive_material()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var gsz := size * 1.55
		glow.size = gsz
		glow.position = (centre - gsz * 0.5).floor()
		glow.z_index = LIVE_Z
		notes.add_child(glow)
		# Cast shadow: the paper's own silhouette in translucent black, offset down-right (the
		# board's ONE light), so each notice sits proud of the wood instead of printed on it.
		var shadow := TextureRect.new()
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.stretch_mode = TextureRect.STRETCH_SCALE
		shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		if not _parch_live.is_empty():
			shadow.texture = _parch_live[idx % _parch_live.size()]
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.33)
		shadow.size = size
		shadow.pivot_offset = size * 0.5
		shadow.rotation_degrees = tilt
		shadow.position = pos + Vector2(3.0, 5.0)
		shadow.z_index = LIVE_Z
		notes.add_child(shadow)
		var node := _make_live_notice(intel, idx, fit["tfs"], fit["sfs"])
		node.custom_minimum_size = hit_size
		node.size = size
		node.pivot_offset = size * 0.5
		node.rotation_degrees = tilt
		node.position = pos
		node.z_index = LIVE_Z
		node.add_to_group("live_notice")   # keyboard entry point (T146 / L6): first-in-order gets focus
		notes.add_child(node)
		footprints.append(Rect2(centre - BoardGeo.rotated_extent(size, tilt) * 0.5, BoardGeo.rotated_extent(size, tilt)))
	var live := placed.size()
	# Self-check for the playtest (T145): no live petition may bury another (rotation included),
	# and every live hit-target clears the 44x44 minimum.
	var hit_ok := live == 0 or (min_hit.x >= HIT_MIN.x and min_hit.y >= HIT_MIN.y)
	_log("keepout live=%d ok=%s minhit=%dx%d hit_ok=%s" % [live, live > 0 and BoardGeo.all_disjoint(footprints, 0.0), int(min_hit.x) if live > 0 else 0, int(min_hit.y) if live > 0 else 0, hit_ok])
	if OS.is_debug_build():
		_log("keepout inner=%v bounds=%s" % [inner, BoardGeo.live_bounds(inner)])
		for i in footprints.size():
			_log("  live[%d] fp=%s" % [i, footprints[i]])
	# Empty board (L8): no live petitions → a solemn scrap over the bare wall, never a
	# blank popup. (T146 refines the styling; this is the honest empty state.)
	if live == 0:
		# A solemn empty state (T146 / L8), never a blank popup. Two-line: a title read + a
		# quieter subtitle, above the vignette (z LIVE_Z) so the wall's shadow never swallows it.
		var ebox := VBoxContainer.new()
		ebox.alignment = BoxContainer.ALIGNMENT_CENTER
		ebox.add_theme_constant_override("separation", 4)
		ebox.custom_minimum_size = Vector2(360, 60)
		ebox.size = Vector2(360, 60)
		ebox.position = Vector2((inner.x - 360.0) * 0.5, inner.y * 0.5 - 30.0).floor()
		ebox.z_index = LIVE_Z
		ebox.add_child(_card_label("The wall stands empty.", 17, Color(0.86, 0.78, 0.58), true, true))
		ebox.add_child(_card_label("No petitions stand before the Collegium.", 12, Color(0.66, 0.58, 0.44), true, true))
		canvas.add_child(ebox)
	if OS.is_debug_build():
		_dump_notes.call_deferred(notes)
	if OS.get_cmdline_user_args().has("--board-debug"):
		for fp in footprints:
			var mark := Panel.new()
			var sb2 := StyleBoxFlat.new()
			sb2.bg_color = Color(0, 0, 0, 0)
			sb2.border_color = Color(1, 0, 0)
			sb2.set_border_width_all(1)
			mark.add_theme_stylebox_override("panel", sb2)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.position = (fp as Rect2).position
			mark.size = (fp as Rect2).size
			mark.z_index = 20
			canvas.add_child(mark)
	# Sacred-decay ambiance (cobweb + votive), tucked into corners proven empty of any
	# live petition so it never occludes a headline (DESIGN — decay is clutter, not cover).
	_add_decay(canvas, inner, footprints)
	# Warm-dark vignette over the whole wall: a lit pool at the centre falling to
	# near-black at the corners (Prototype-v1 ambience). A runtime radial gradient (no
	# PNG import); above the papers so their edges sink into shadow, below placard/reader.
	var vig := TextureRect.new()
	vig.texture = BoardGeo.vignette_gradient()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.z_index = 2
	canvas.add_child(vig)
	# The legend / active-assignment bar along the bottom (Prototype v1).
	_add_board_bar(canvas, inner)
	# The carved sign hangs over the top of the board, above the papers (own layer).
	_place_placard(canvas)
	# The heraldic crest is drawn as a popup-tracking OVERLAY (created in _init, synced in
	# _process) so it can crown over the top edge — not clipped by the ScrollContainer.
	_log("board live=%d flavor=%d" % [live, flavor_n])
	# If a notice has been taken down, lay it on the reader over the dimmed board.
	if not _board_selection.is_empty():
		_show_notice_reader(canvas, _board_selection)
	elif live > 0:
		# Grid view: seed keyboard focus so Tab walks the writs and the corner reticle shows
		# from the first frame (T146 / L6). Restores the prior writ across a rebuild.
		_focus_first_notice.call_deferred()

# The board's inner area (inside the wood frame): the popup scroll region, minus a
# little breathing room. Absolute notice placement is normalised to this.
#
# The floor must never exceed the viewport, or the canvas grows past the frame and the
# notices hang off the wall. At the 640x360 base (TD-042) the old 640x320 floor was
# larger than the popup's own scroll region (568x232) — the board spilled its edges.
func _board_inner_size() -> Vector2:
	# Thin wrapper over BoardGeo (many call sites need it against the live viewport).
	return BoardGeo.inner_size(get_viewport_rect().size)

# Place a notice on the canvas: top-left from a normalised centre, rotated about
# its own centre so it hangs at a human angle.
func _place(canvas: Control, node: Control, center_norm: Vector2, size: Vector2, tilt: float) -> void:
	node.custom_minimum_size = size
	node.size = size
	node.pivot_offset = size * 0.5
	node.rotation_degrees = tilt
	# Keep the paper (plus a little rotation slack) inside the wooden frame even when
	# a big size lands under a jittered edge slot.
	var inner := _board_inner_size()
	# Reserve the top band for the hanging placard so papers sit below the sign
	# (matching the reference) rather than jamming up behind it. Fractions, not pixels:
	# 72px was a fifth of the whole board once the base became 640x360 (TD-042).
	var top_reserve := inner.y * BoardGeo.TOP_RESERVE_FRAC
	var pos := inner * center_norm - size * 0.5
	pos.x = clampf(pos.x, 8.0, maxf(8.0, inner.x - size.x - 8.0))
	pos.y = clampf(pos.y, top_reserve, maxf(top_reserve, inner.y - size.y - 8.0))
	node.position = pos.floor()
	canvas.add_child(node)

# ── Keep-out (T145) ──────────────────────────────────────────────────────────
# A live petition must always be readable: no live notice may bury another. Flavor
# scraps are drawn behind and may tuck under freely — clutter, never occlusion.
#
# Deterministic: same seed -> same board. Pure geometry over Rect2s, resolved before
# any node is added, then self-checked and logged for the playtest (`keepout ... ok=`).

# Height of the bottom legend / active-assignment bar. Shared by the bar builder and
# the live-bounds reserve so cards can never be laid over the bar.
# Push overlapping rects apart along their centre-to-centre axis until disjoint.
# Lay out the live notices as a clean, framed GRID (the Prototype-v1 composition —
# the reference contract board is a tidy grid of pinned writs, not an organic scatter;
# this supersedes the scatter solver / TD-040). Cells are centred in the live bounds
# (below the placard, inside the torch reserves); each card is a portrait rect inset in
# its cell. Disjoint by construction, so the keep-out self-check always passes.
# The requester's signature line for a notice foot (trait-free intel): "— <name>,
# <role>" or "— an unnamed <role>" for an anonymous petitioner. Diegetic fill only.
func _notice_sig(req: Variant) -> String:
	if typeof(req) != TYPE_DICTIONARY:
		return ""
	var nm := str((req as Dictionary).get("name", ""))
	var role := str((req as Dictionary).get("role", "petitioner"))
	# Kept short so it stays one line on the card foot; the full "name, role of place"
	# is shown in the reader. Anonymous petitioners read as "— an unnamed <role>".
	if nm == "":
		return "— an unnamed %s" % role
	return "— %s" % nm

# A live contract notice: a clickable landscape parchment — sacred headline, target,
# site, requester signature, and an Origin wax seal as a corner badge. No prose here
# (glanceable); the full writ is read only when taken down.
# Fit one writ inside its grid cell (TD-061 / R192, P111): a seeded width, then the text
# measured with the SAME font/sizes/wrap the labels render with (ThemeDB.fallback_font is
# the default theme font — no custom default is set), plus the card's furniture headroom
# (pad 13 top / 4 bottom / 7 sides, VBox separation 1 — mirrors _make_live_notice). If the
# cell can't hold the block at 9/7, the fonts step down once to 8/6 — the guarantee that a
# long site ("at Hollowmere Crossing") never clips at the sheet edge.
func _fit_writ(intel: Dictionary, cell: Vector2) -> Dictionary:
	var cid := str(intel.get("contractId", ""))
	var u_w := float(absi((cid + "|w").hash()) % 1000) / 999.0
	var u_h := float(absi((cid + "|h").hash()) % 1000) / 999.0
	var w := clampf(floorf(cell.x * (0.84 + 0.16 * u_w)), HIT_MIN.x, cell.x)
	var font := ThemeDB.fallback_font
	var target := str(intel.get("targetName", "?"))
	var site := "at %s" % intel.get("siteName", "?")
	var text_w := w - 14.0                    # pad margins 7+7
	# Labels insert the theme's `line_spacing` (default 3) BETWEEN wrapped lines, which
	# get_multiline_string_size does not count — the TD-061 fit was ~6px short on two
	# 2-line blocks, clipping "Ossuary" at the sheet edge (TD-062/R196, P113).
	var ls := float(ThemeDB.get_default_theme().get_constant("line_spacing", "Label"))
	var chosen := [8, 6]                      # fallback if even stepping down can't fit
	var need := 0.0
	for fs in [[9, 7], [8, 6]]:
		var th := font.get_multiline_string_size(target, HORIZONTAL_ALIGNMENT_CENTER, text_w, fs[0]).y
		th += ls * maxf(0.0, roundf(th / font.get_height(fs[0])) - 1.0)
		var sh := font.get_multiline_string_size(site, HORIZONTAL_ALIGNMENT_CENTER, text_w, fs[1]).y
		sh += ls * maxf(0.0, roundf(sh / font.get_height(fs[1])) - 1.0)
		need = 13.0 + 4.0 + th + 1.0 + sh + 2.0   # headroom + text block + safety (measure == render)
		if need <= cell.y:
			chosen = fs
			break
	# Seeded slack: even a short writ varies, growing part of the way into its remaining
	# cell room — but the content floor (and the 44px hit floor) always wins.
	var h := clampf(ceilf(need + u_h * maxf(0.0, cell.y - need) * 0.6), HIT_MIN.y, cell.y)
	return {"size": Vector2(w, floorf(h)), "tfs": chosen[0], "sfs": chosen[1]}

func _make_live_notice(intel: Dictionary, idx: int, tfs: int = 9, sfs: int = 7) -> Control:
	var sel := not _board_selection.is_empty() and str(_board_selection.get("contractId", "")) == str(intel.get("contractId", ""))
	var card := Button.new()
	card.flat = true
	card.clip_contents = true   # a long target never spills its writ onto the wall below
	# Keyboard reachable (T146 / L6): Tab traverses the writs in board (reading) order, Enter/
	# Space takes one down. The focus mark is a corner-bracket reticle (added below), not a
	# stylebox ring, so all four states stay flat.
	card.focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		card.add_theme_stylebox_override(st, empty)
	if sel:
		card.rotation_degrees = 0.0   # the one taken down hangs straight
	card.pressed.connect(func(): _select_board_card(intel))
	var tint := BoardGeo.parch_tint(str(intel.get("contractId", "")))
	var bg := TextureRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	# Obey the notice rect, not the texture's own 182x118: EXPAND_KEEP_SIZE (default)
	# floors the min size to the full texture, so the paper overflowed the keep-out
	# footprint and buried its neighbours. IGNORE_SIZE lets FULL_RECT shrink it to fit.
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # v1 painted paper stays soft/painterly
	if not _parch_live.is_empty():
		bg.texture = _parch_live[idx % _parch_live.size()]
	# Lift the paper toward v1's bright, lit ivory, then floor it so no seed/tint ever drops a
	# live writ below the legibility floor (T145 / L1). The stack also rides above the vignette.
	bg.modulate = _floor_tone(tint.lightened(0.16))
	card.add_child(bg)
	# Paper curl: a soft inner shadow fading up from the foot, so the sheet lifts off the
	# wall and shades itself (never a dead-flat rectangle). Above the paper, under the text.
	var curl := TextureRect.new()
	curl.texture = BoardGeo.curl_gradient()
	curl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curl.stretch_mode = TextureRect.STRETCH_SCALE
	curl.anchor_left = 0.06; curl.anchor_right = 0.94
	curl.anchor_top = 1.0; curl.anchor_bottom = 1.0
	curl.offset_top = -11.0; curl.offset_bottom = -2.0
	card.add_child(curl)
	# Faint impressed watermark ring behind the writ (the aged-official read in the
	# reference): a barely-there ink circle, inert, drawn above the paper, under the text.
	var mark := Panel.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.anchor_left = 0.20
	mark.anchor_right = 0.80
	mark.anchor_top = 0.28
	mark.anchor_bottom = 0.72
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0, 0, 0, 0)
	msb.set_border_width_all(2)
	msb.border_color = Color(0.26, 0.18, 0.10, 0.14)
	msb.set_corner_radius_all(60)
	mark.add_theme_stylebox_override("panel", msb)
	card.add_child(mark)
	# Lift toward the viewer AND raise above neighbours, so an overlapped notice is
	# never occluded while you read/click it (dense scatter can stack corners).
	# Hover takes precedence over the Tab position: moving the mouse onto a writ grabs focus, so
	# the reticle jumps straight to the hovered writ (and Tab keeps working from there). (T146.)
	card.mouse_entered.connect(func(): card.grab_focus(); card.move_to_front(); _hover_card(card, 1.05); bg.modulate = _floor_tone(tint.lightened(0.26)))
	card.mouse_exited.connect(func(): _hover_card(card, 1.03 if sel else 1.0); bg.modulate = _floor_tone(tint.lightened(0.16)))
	var verb := str(intel.get("primaryVerb", ""))
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 7)
	# Room at the top for the corner furniture: the verb badge (upper-left) and the wax
	# seal (upper-right) both straddle the top edge, so the text column starts below them.
	pad.add_theme_constant_override("margin_top", 13)
	pad.add_theme_constant_override("margin_bottom", 4)
	card.add_child(pad)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	pad.add_child(v)
	# No sacred-register type WORD on the card: the corner verb badge (keyed by the bottom
	# legend) already carries it, and a long headline like "RITE OF BANISHMENT" both wrapped
	# under the badge/seal and read illegibly faint. The card now leads with the target
	# (Prototype v1), leaving room so every card keeps its site line.
	# Centre the target/site block so the portrait writ fills top-to-bottom (Prototype v1).
	var gap_top := Control.new()
	gap_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap_top)
	v.add_child(_card_label(str(intel.get("targetName", "?")), tfs, INK, true, true))
	v.add_child(_card_label("at %s" % intel.get("siteName", "?"), sfs, INK_SOFT, true, true))
	# Threat/reward are deliberately NOT shown on the wall (trait-free board; knowledge is
	# not a number) — you learn threat only by taking the notice down to read. The
	# requester's signature is shown in the reader, not on the glanceable card, so a
	# two-line target never fights the foot for the short portrait's vertical room.
	var gap_bot := Control.new()
	gap_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap_bot)
	# Corner furniture (own children, above the text): the PRIMARY-VERB badge stamped in
	# the upper-left (its legend is the bottom-left key). The asserted-Origin wax seal is
	# RETIRED from the writ (TD-060): the petition-type badge is the only corner mark —
	# a sealed assertion of genus implied a certainty the Collegium doesn't have.
	card.add_child(_notice_tack(str(intel.get("contractId", ""))))
	card.add_child(_verb_corner_badge(verb))
	if sel:
		var ring := Panel.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.set_anchors_preset(Control.PRESET_FULL_RECT)
		var rb := StyleBoxFlat.new()
		rb.bg_color = Color(0, 0, 0, 0)
		rb.set_border_width_all(2)
		rb.border_color = Color(0.90, 0.74, 0.36)
		rb.shadow_color = Color(0.85, 0.62, 0.24, 0.55)   # warm glow bleeding off the gilt edge
		rb.shadow_size = 6
		ring.add_theme_stylebox_override("panel", rb)
		card.add_child(ring)
	# Keyboard-focus reticle (T146 / L6): the last child so its brackets draw over the writ.
	# Focus is tracked by contractId so a board rebuild (a ready-toggle, a seal) restores it.
	var cid := str(intel.get("contractId", ""))
	card.set_meta("cid", cid)
	var reticle := _focus_reticle()
	card.add_child(reticle)
	card.focus_entered.connect(func():
		_focus_cid = cid
		reticle.visible = true
		reticle.queue_redraw())
	card.focus_exited.connect(func(): reticle.visible = false)
	return card

# An inert flavor notice: aged parchment, a header + a few lines, never clickable.
func _make_flavor_notice(f: Dictionary, idx: int) -> Control:
	var note := Panel.new()
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.modulate = Color(0.58, 0.55, 0.52)   # older, greyed hard so live notices always pop
	var sb := StyleBoxEmpty.new()
	note.add_theme_stylebox_override("panel", sb)
	var bg := TextureRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # fit the scrap to the notice rect
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _parch_flavor.is_empty():
		bg.texture = _parch_flavor[idx % _parch_flavor.size()]   # already aged + foxed (T143)
	bg.modulate = BoardGeo.parch_tint("flavor-%d" % idx).darkened(0.12)
	note.add_child(bg)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 11)
	note.add_child(pad)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 3)
	pad.add_child(v)
	v.add_child(_card_label(str(f.get("head", "")), 10, Color(0.32, 0.16, 0.09), true, true))
	v.add_child(_card_label(str(f.get("body", "")), 8, Color(0.36, 0.27, 0.16), true, false))
	return note

# A thin ruled line (a scribe's rule under a heading).
func _hrule(color: Color) -> Control:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

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

func _show_notice_reader(canvas: Control, intel: Dictionary) -> void:
	# The whole reader (dim + centred reader row) lives under ONE named container so a
	# stamp/lift can refresh JUST the reader in place (TD-065/R211) — free this and re-show,
	# without rebuilding the board notices/torches (the stutter). Pass-through mouse so the
	# dim still catches click-off and the reader still reads.
	var overlay := Control.new()
	overlay.name = "ReaderOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 10   # above the placard (z 5) so a taken-down writ covers the sign too
	# Capture hardening: under `-- --reader` (unattended `--board-preview` captures) the
	# click-off dismiss is suppressed — the Godot window pops under the OS cursor and stray
	# physical clicks kept toggling the taken-down writ closed mid-capture (known gotcha).
	# Debug-preview only; the Return button still dismisses.
	if not (OS.is_debug_build() and OS.get_cmdline_user_args().has("--reader")):
		# Left-button only — wheel ticks are ALSO InputEventMouseButton (WHEEL_UP/DOWN,
		# pressed), so an unguarded check made over-scrolling the writ dismiss it.
		dim.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_select_board_card({}))
	overlay.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.z_index = 10
	overlay.add_child(cc)
	# Reader + the quill-line scrollbar side by side (TD-061 / R194): the ornament rides
	# OUTSIDE the sheet, on the dimmed board, mirroring the reader's scroll both ways.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	cc.add_child(row)
	var rdr := _build_notice_reader(intel)
	row.add_child(rdr)
	var orn := OrnamentScrollbar.new()
	orn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	orn.custom_minimum_size = Vector2(18, rdr.custom_minimum_size.y * 0.82)
	row.add_child(orn)
	orn.attach(rdr.find_child("ReaderScroll", true, false) as ScrollContainer)
	# Scroll continuity (TD-062/R199, P114): a snapshot rebuild of the SAME open notice
	# (stamping/unstamping the seal) restores the prior offset — the pin-to-top belongs to
	# a FRESH open only. `--reader-foot` (debug capture) rides the same path.
	var cid := str(intel.get("contractId", ""))
	var target := 0
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--reader-foot"):
		target = 100000
	elif cid == _reader_open_cid:
		target = _reader_scroll_mem
	_reader_open_cid = cid
	_reset_reader_scroll.call_deferred(rdr, target)

# Settle a freshly-(re)built reader at `target` (0 = the headline; a remembered offset on
# a same-notice rebuild, R199; 100000 = the debug foot pin). The one-shot set lost a race
# with a late reflow/focus pass, so the value is held across several frames; afterwards
# the scrollbar feeds `_reader_scroll_mem` so the NEXT rebuild can restore the reader.
func _reset_reader_scroll(rdr: Control, target: int) -> void:
	var sc: ScrollContainer = null
	for _i in 8:
		if not is_instance_valid(rdr):
			return
		sc = rdr.find_child("ReaderScroll", true, false) as ScrollContainer
		if sc != null:
			get_viewport().gui_release_focus()   # no focused footer control to follow
			sc.scroll_vertical = target
		await get_tree().process_frame
	if sc != null:
		_reader_scroll_mem = int(sc.scroll_vertical)
		var track := sc
		sc.get_v_scroll_bar().value_changed.connect(func(_v):
			if is_instance_valid(track):
				_reader_scroll_mem = int(track.scroll_vertical))

func _build_notice_reader(intel: Dictionary) -> Control:
	# The enlarged parchment poster. A solid parchment-tinted FILL sits behind the
	# torn parchment TEXTURE, so the sheet reads as real parchment and any torn/
	# transparent edge blends into matching parch (never the dark board). The text
	# is padded well inside the intact centre so it never rides a tear.
	var tint := BoardGeo.parch_tint(str(intel.get("contractId", "")))
	# The reader IS the parchment sprite (torn shape), enlarged — no rectangular
	# backing behind it (that was the "square"). The reading is padded well inside
	# the intact centre so no glyph rides a tear; the dimmed board shows past the
	# torn edges, exactly like a poster taken off the wall.
	var reader := Control.new()
	reader.mouse_filter = Control.MOUSE_FILTER_STOP   # clicks on the writ don't dismiss
	var inner := _board_inner_size()
	reader.custom_minimum_size = Vector2(min(486.0, inner.x - 40.0), min(inner.y - 24.0, 396.0))
	if not _parch_live.is_empty():
		var bg := TextureRect.new()
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # fill the enlarged reader sheet
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp deckled edge, no blur
		bg.texture = _parch_live[absi(str(intel.get("contractId", "")).hash()) % _parch_live.size()]
		bg.modulate = tint
		reader.add_child(bg)
	var scroll := ScrollContainer.new()   # a long writ scrolls within the sheet
	scroll.name = "ReaderScroll"          # found by _reset_reader_scroll to pin it to the top
	# The scroll (= the CLIP boundary) is inset to the parchment's intact centre, not the
	# reader's full rect: with a full-rect scroll the pad margins live INSIDE the scrolled
	# content, so once scrolled the text rode up over the torn edge and past the sheet
	# (TD-060 review). Clipping is forced explicitly so no glyph ever escapes the sheet.
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	# TD-061 (R193): the text consumes the sheet — insets tightened (34/30 → 26/22) and the
	# internal scrollbar retired (SHOW_NEVER: wheel scrolling lives on, the bar is the
	# external ornament, R194), so its width goes to text too. The clip boundary still sits
	# inside the solid parchment (R189: no glyph ever rides the torn edge).
	scroll.offset_left = 26.0
	scroll.offset_right = -26.0
	scroll.offset_top = 22.0
	scroll.offset_bottom = -22.0
	scroll.clip_contents = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.follow_focus = false            # a focused footer control must not drag the writ down
	reader.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	scroll.add_child(pad)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.custom_minimum_size = Vector2(min(418.0, inner.x - 108.0), 0)   # sheet width minus the R193 insets
	col.add_theme_constant_override("separation", 6)
	pad.add_child(col)
	var ink := Color(0.20, 0.11, 0.04)
	# Secondary text (site, gloss, preamble, Archive, seal caption): the old 0.38/0.27/0.15 was
	# only a shade off the parchment and washed out. Darkened to a firm brown that reads.
	var ink_soft := Color(0.26, 0.16, 0.07)
	# Headline (sacred register), inked by charge + rule.
	var rverb := str(intel.get("primaryVerb", ""))
	var head := _card_label(Notice.headline(rverb), 12, INK, true, true)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(head)
	col.add_child(_hrule(Color(0.42, 0.28, 0.16, 0.7)))
	var title := _card_label(str(intel.get("targetName", "?")), 21, ink, true, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(title)
	var site := _card_label("at %s" % intel.get("siteName", "?"), 12, ink_soft, true, true)
	site.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(site)
	# Asserted genus (text-only gloss — the Origin wax seal is retired, TD-060: the
	# assertion is a falsifiable claim and reads as prose, never pressed in wax).
	var org := str(intel.get("origin", "SIN"))
	var org_lbl := _card_label("Asserted %s: %s" % [_origin_word(org), ORIGIN_GLOSS.get(org, "")], 12, ink_soft, true, true)
	org_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(org_lbl)
	# Preamble + the petitioner's plea + the charge (procedural, verb-faithful). The plea
	# replaces the retired threat pips (TD-061): danger reads as the DREAD in the
	# petitioner's own words, banded by tier — words from a person, never a meter (P110).
	var pre := _card_label(Notice.preamble(intel), 12, ink_soft, true, true)
	pre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(pre)
	var plea := _card_label(Notice.plea(intel), 12, ink_soft, true, true)
	plea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(plea)
	var charge := _card_label(Notice.charge(intel), 14, ink, true, true)
	charge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(charge)
	# Honest empty Archive (no fabricated signs/notes/reward).
	var arch := _card_label("From the Archive: no prior testament on record.", 11, ink_soft, true, true)
	arch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(arch)
	# The signature of the petitioner who reported it.
	var sig := _card_label(Notice.signature(intel.get("requester", {})), 12, ink, true, true)
	sig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(sig)
	col.add_child(_hrule(Color(0.42, 0.28, 0.16, 0.7)))
	# The seal: the leader stamps to take up the charge (reversible).
	col.add_child(_seal_block(intel, ink, ink_soft))
	# Return to the board. Built inline (not via _popup_button) so it takes no keyboard
	# focus — a focused footer button is what dragged the freshly-opened writ to its foot.
	var ret := Button.new()
	ret.text = "Return to the board"
	ret.focus_mode = Control.FOCUS_NONE
	ret.pressed.connect(func(): _select_board_card({}))
	col.add_child(ret)
	return reader

# The seal (TD-041): the leader stamps their seal on the open charge to take it up,
# and clicks the stamped seal again to lift it — a reversible SELECT/DESELECT over
# the Contract Board. Non-leaders see the seal's state read-only. Affordance is not
# authority: the server validates (a raced NOT_* / WRONG_PHASE surfaces in status).
func _seal_block(intel: Dictionary, ink: Color, ink_soft: Color) -> Control:
	var cid := str(intel.get("contractId", ""))
	var sel_c: Variant = _snapshot.get("contract")
	var selected := sel_c != null and str(sel_c.get("contractId", "")) == cid
	var leader := _is_leader()

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)

	# The stamp target: a clickable area holding a wax seal (faint until stamped) and
	# a caption. The whole area is the hit target so "stamp your seal" reads as one act.
	var stamp := Button.new()
	stamp.flat = true
	stamp.clip_contents = false
	# Interaction lockout (TD-064/R209, made robust TD-065/R212): the stamp is disabled for a
	# short window after a stamp/lift so the ceremony can't be interrupted or spam-fired. The
	# REAL spam guard is a time-check in the click handler below (independent of this disabled
	# state, so it can neither be defeated nor stick); this disable is visual feedback only and
	# ALWAYS re-enables — an unconditional buffered timer (no strict deadline recheck, which
	# used to miss by a frame and leave the button stuck until reopen). Affordance ≠ authority
	# (P119): the server still validates.
	var cool_left := _seal_cooldown_until - Time.get_ticks_msec()
	stamp.disabled = (not leader) or cool_left > 0
	if leader and cool_left > 0:
		get_tree().create_timer(cool_left / 1000.0 + 0.08).timeout.connect(func():
			if is_instance_valid(stamp):
				stamp.disabled = false)
	# Keyboard reachable for the leader only (T146 / L6): a non-leader's seal is read-only, so it
	# takes no focus. The gilt ring marks it when Tabbed to; Enter/Space stamps.
	stamp.focus_mode = Control.FOCUS_ALL if leader else Control.FOCUS_NONE
	stamp.custom_minimum_size = Vector2(0, 76)
	stamp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamp.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if leader else Control.CURSOR_ARROW
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled"]:
		stamp.add_theme_stylebox_override(st, empty)
	stamp.add_theme_stylebox_override("focus", _focus_ring() if leader else empty)
	if leader:
		stamp.pressed.connect(func():
			# The spam guard (TD-065/R212): a hard time-check, independent of the button's
			# disabled state, so the lockout can neither be defeated (a queued click firing
			# after re-enable) nor stick. A click inside the window sends nothing.
			var now := Time.get_ticks_msec()
			if now < _seal_cooldown_until:
				return
			# One stamp per window: open the lockout, disable for feedback, send the intent.
			_seal_cooldown_until = now + SEAL_COOLDOWN_MS
			stamp.disabled = true
			if selected:
				_log("seal %s accepted=false" % cid)
				_net.send_message(Protocol.DESELECT_CONTRACT, {})
			else:
				_log("seal %s accepted=true" % cid)
				_net.send_message(Protocol.SELECT_CONTRACT, {"contractId": cid}))

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	stamp.add_child(row)

	# The wax seal: a faint imprint waiting to be pressed, or a firm seal once stamped —
	# the generic COLLEGIUM seal (TD-060): the leader stamps the order's device, not a genus.
	var seal := WaxSeal.new()
	seal.name = "ReaderSeal"                            # found by --flash-preview (V1 capture)
	seal.custom_minimum_size = Vector2(46, 46)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Unsealed = the empty dashed socket (TD-063/R203 — the dash carries its own low
	# opacity, so the control's modulate stays 1.0 for every role).
	seal.set_faint(not selected)
	row.add_child(seal)

	# The OATH (TD-062/R198, author ruling: named-target form): the leader speaks in the
	# first person; the how-to lives in the hover tooltip, never on the sheet. Non-leaders
	# read the party form. `<name>` = the local Seeker's lobby name ("Seeker" in preview).
	var target := str(intel.get("targetName", "the charge"))
	var seeker := _display_name_plain(_self_id)
	if seeker.is_empty() or seeker == _self_id:   # unresolved id (e.g. preview) → the generic
		seeker = "Seeker"
	var caption: String
	if selected:
		caption = "It is witnessed. %s is ours to answer." % target
	elif leader:
		caption = "I, %s, take up the charge against %s. Let it be witnessed." % [seeker, target]
	else:
		caption = "Awaiting the leader's seal."
	if leader:
		stamp.tooltip_text = "Click the seal to lift it" if selected else "Click the seal to stamp it"
	var cap := _card_label(caption, 12, ink if selected else ink_soft, true, false)
	cap.custom_minimum_size = Vector2(220, 0)
	row.add_child(cap)

	# The ceremony (TD-062/R200): if this rebuild FLIPPED the seal's state, the new seal
	# plays the press (stamp) or the peel (lift). Pure theatre: no state, no message; a
	# reduced-motion client renders the end state only (P115).
	var prev: Variant = _seal_prev.get(cid)
	_seal_prev[cid] = selected
	if prev != null and bool(prev) != selected and not _reduced_motion:
		_animate_seal(seal, selected)
	box.add_child(stamp)
	return box

# The stamp/lift theatre (R200; reworked TD-063/R204: SLOWER and HEAVIER, and it may
# displace NOTHING — the flash lives under the SEAL's own subtree, never the HBox row
# (whose layout shoved the caption sideways), and the sheet-thump is gone (it moved the
# prose under the reader's eyes). Runs on the freshly rebuilt seal after one frame (so
# the container has sized it); if another rebuild lands mid-tween the nodes are freed
# and the tweens die with them — safe. (P116)
func _animate_seal(seal: Control, sealed: bool) -> void:
	await get_tree().process_frame
	if not is_instance_valid(seal):
		return
	seal.pivot_offset = seal.size * 0.5
	if sealed:
		# The press: a hovering wind-up, an accelerating drop, a deep squash on impact
		# with the wax flash blooming, and a heavy wobbling settle (~0.82s total). The
		# flash lives on its OWN overlay above the board (TD-064/R207), not under the seal:
		# the seal sits inside the reader's clipped ScrollContainer, which trapped the
		# flash's radius at the sheet edge. Spawn it timed to the impact (~0.40s in).
		_spawn_seal_flash(seal, 0.40)
		seal.scale = Vector2(2.2, 2.2)
		seal.modulate.a = 0.0
		var t := seal.create_tween()
		t.tween_property(seal, "modulate:a", 0.85, 0.10)                                   # hover in
		t.parallel().tween_property(seal, "scale", Vector2(2.05, 2.05), 0.10)
		t.tween_property(seal, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)  # the fall
		t.parallel().tween_property(seal, "modulate:a", 1.0, 0.30)
		t.tween_property(seal, "scale", Vector2(1.22, 0.80), 0.09)                          # impact squash
		t.tween_property(seal, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # heavy settle
	else:
		# The peel: the firm wax lifts, rises and fades, then the empty dashed socket
		# remains (the block's true unsealed render).
		seal.set_faint(false)
		seal.modulate.a = 1.0
		var t := seal.create_tween()
		t.tween_property(seal, "scale", Vector2(1.55, 1.55), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(seal, "modulate:a", 0.0, 0.28)
		t.tween_callback(func():
			if is_instance_valid(seal):
				seal.set_faint(true)
				seal.scale = Vector2.ONE
				seal.modulate.a = 1.0)

# The impact flash on its OWN overlay (TD-064/R207): a warm additive bloom centred on the
# seal's on-screen position, drawn ABOVE the board so its full radius shows (the seal lives
# inside the reader's clipped ScrollContainer, which trapped a child flash at the sheet
# edge). The seal's centre stays fixed (it only scales about its pivot), so we capture it
# once. The overlay is independent of the seal's lifecycle — a snapshot rebuild that frees
# the seal leaves the bloom to finish and free its own layer (no leak, no orphan).
func _spawn_seal_flash(seal: Control, delay: float) -> void:
	var gt := seal.get_global_transform_with_canvas()
	var centre := gt * (seal.size * 0.5)         # seal centre in logical (canvas) space
	var fsz := seal.size * 2.3 * gt.get_scale()
	var lay := CanvasLayer.new()
	lay.layer = 95                               # above the popup dim/reader and the rite banner (90)
	add_child(lay)
	var flash := TextureRect.new()
	flash.texture = BoardGeo.backlight_gradient()
	flash.material = BoardGeo.additive_material()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.stretch_mode = TextureRect.STRETCH_SCALE
	flash.size = fsz
	flash.pivot_offset = fsz * 0.5
	flash.position = centre - fsz * 0.5
	flash.scale = Vector2(0.6, 0.6)
	# Overdriven warm core (>1) so the additive burst reads even over the bright parchment
	# (additive on a light surface saturates); still candlelit/in-register, no bloom shader.
	flash.modulate = Color(1.3, 1.0, 0.58, 0.0)
	lay.add_child(flash)
	var ft := flash.create_tween()
	ft.tween_interval(delay)                     # bloom on IMPACT, not on the wind-up
	ft.tween_property(flash, "modulate:a", 0.92, 0.04)
	ft.parallel().tween_property(flash, "scale", Vector2(1.8, 1.8), 0.42)
	ft.tween_property(flash, "modulate:a", 0.0, 0.30)
	ft.tween_callback(lay.queue_free)

# A seeded position jitter (fractions of the inner board) so notices don't sit on a
# grid — organic like a real wall. Deterministic per seed string (same board twice
# → identical scatter).
# A seeded hang angle (degrees), ~ -6.5°..+6.5° — a looser wall than a fixed pattern.
# The carved "notice board" placard, hung at top-centre over the wall on two nails.
# Flanking wall torches (Batch 1, T142): a grayscale-additive glow behind the papers
# + an animated flame + an iron sconce at each inner edge. Flame/glow are white+alpha
# VFX sources tinted to the flame ramp through an ADD-blend material, so the composite
# stays on-palette. Reduced motion freezes the flicker and pins the glow to peak
# brightness — the light is load-bearing, only the pulse is decorative.
# A rect is "clear" when no live footprint intersects it — decay may only sit in space
# no petition claims (keep-out heritage; DESIGN binds cobweb/votive to empty corners).
# Sacred-decay props: one cobweb in a clear top corner (grayscale-additive, tinted cold
# and dim like the glow) + a dead votive at a clear base corner. Both inert, behind the
# papers, and skipped entirely if their corner is occupied — clutter, never occlusion.
func _add_decay(canvas: Control, inner: Vector2, footprints: Array) -> void:
	if _cobweb_tex != null:
		var wsz := 40.0
		# prefer the top-left corner; if a petition claims it, mirror into the top-right.
		for spec in [[Vector2(3, 3), 1.0], [Vector2(inner.x - wsz - 3, 3), -1.0]]:
			var pos: Vector2 = spec[0]
			var flip: float = spec[1]
			if BoardGeo.decay_clear(Rect2(pos, Vector2(wsz, wsz)), footprints):
				var web := TextureRect.new()
				web.texture = _cobweb_tex
				web.mouse_filter = Control.MOUSE_FILTER_IGNORE
				web.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				web.material = BoardGeo.additive_material()
				web.modulate = Color(0.62, 0.66, 0.72, 0.34)  # cold, dim (tinted VFX) — TD-050: a whisper, not a focal detail
				web.position = pos
				if flip < 0.0:                                  # mirror for the right corner
					web.scale.x = -1.0
					web.position.x = pos.x + wsz
				web.z_index = -1
				canvas.add_child(web)
				break
	if _votive_tex != null:
		var vsz := Vector2(14, 22)
		for pos in [Vector2(6, inner.y - vsz.y - 4), Vector2(inner.x - vsz.x - 6, inner.y - vsz.y - 4)]:
			if BoardGeo.decay_clear(Rect2(pos, vsz), footprints):
				var vot := TextureRect.new()
				vot.texture = _votive_tex
				vot.mouse_filter = Control.MOUSE_FILTER_IGNORE
				vot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				vot.position = pos
				vot.z_index = -1
				canvas.add_child(vot)
				break

# The bottom bar (Prototype v1): left = the order's verbs, centre = the sealed charge
# (ACTIVE ASSIGNMENT), right = the status key. Trait-free — reads the snapshot's
# authoritative `contract`, never a roll. Inert display.
# The bottom-of-screen keybind strip (Prototype v1): one row of key-chips + captions,
# centred just above the bottom edge. Built once; shown for the Contract Board only.
func _build_keyhint() -> Control:
	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.visible = false
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	# Grow UPWARD from the bottom edge — the Control default (GROW_BOTH) would put half the
	# strip below y=vp.y (off-screen), leaving only a sliver visible. z above the frame.
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.z_index = 6
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.03, 0.96)
	sb.border_color = Color(0.46, 0.33, 0.15)
	sb.border_width_top = 2
	sb.content_margin_top = 7; sb.content_margin_bottom = 7
	sb.content_margin_left = 14; sb.content_margin_right = 14
	bar.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	bar.add_child(row)
	for pair in [["Tab", "Navigate"], ["Enter", "Take down"], ["Click", "View Contract"], ["Esc", "Back"]]:
		var cell := HBoxContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_theme_constant_override("separation", 8)
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.14, 0.11, 0.07)
		csb.border_color = Color(0.44, 0.32, 0.15)
		csb.set_border_width_all(1)
		csb.set_corner_radius_all(3)
		csb.content_margin_left = 7; csb.content_margin_right = 7
		csb.content_margin_top = 1; csb.content_margin_bottom = 1
		chip.add_theme_stylebox_override("panel", csb)
		chip.add_child(_card_label(pair[0], 8, Color(0.90, 0.80, 0.52), false, true))
		cell.add_child(chip)
		cell.add_child(_card_label(pair[1], 8, Color(0.74, 0.66, 0.50), false, false))
		row.add_child(cell)
	return bar

func _add_board_bar(canvas: Control, inner: Vector2) -> void:
	# Delegated to the BoardBar module (render-only). Main supplies the authoritative
	# contract + the pre-formatted requester signature; positioning stays here (needs inner/z).
	var contract: Variant = _snapshot.get("contract", null)
	var sig := _notice_sig((contract as Dictionary).get("requester", {})) if contract != null else ""
	var row := BoardBar.build(inner, contract, sig)
	var barh := BoardGeo.bar_height(inner)
	row.position = Vector2(floorf(inner.x * 0.02), floorf(inner.y - barh - 6.0))
	row.z_index = 4
	canvas.add_child(row)

# One dark gilt-edged panel in the bottom bar: a small gold caption over ink-on-parch body.
# The header's rect, in inner-canvas space. Fractional (TD-042), so it survives a resize.
func _place_placard(canvas: Control) -> void:
	var inner := _board_inner_size()
	var pr := BoardGeo.placard_rect(inner)
	var placard := _board_header()
	placard.custom_minimum_size = pr.size
	placard.size = pr.size
	placard.position = pr.position.floor()
	# z_index wins over tree order absolutely, so a hovered paper (which raises to the
	# front of its own layer) can never draw over the hanging sign.
	placard.z_index = 5
	canvas.add_child(placard)

# A radial warm-dark vignette (runtime, no PNG import): clear at the centre, near-black
# at the corners — the torch-lit pool that gives the board its Prototype-v1 ambience.
# The Contract Board's header (TD-053; TD-058): a carved walnut sign, reinforced with forged
# iron straps + bronze bolts, hung at the very top of the board and carrying an engraved two-line
# title. The institution ("THE COLLEGIUM") outranks the thing ("Contract Board"). TD-058 dropped
# the crowning bronze medallion (a repeated pain point at its 17x22 device slot — see TD-054/056/
# 057) and reclaimed its height for the contracts: the sign is now the whole header, hung flush at
# the top, with nothing floating above it. Pure render; inert to input.
func _board_header() -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# No medallion (TD-058): the sign hangs flush at the top of the header rect, so the full rect
	# is the sign itself. (Header height is zero-sum against the writs: live_bounds.h = 184.24 -
	# placard_h, split across two rows — dropping the seat gave the contracts ~27px back.)
	var sign_top := 0.0
	var ptex := load("res://assets/ui/board_header.png") as Texture2D
	if ptex != null:
		# Authored at its exact on-screen size (204x38 — the internal resolution is a fixed
		# 640x360, so placard_rect is deterministic), hence NEAREST + 1:1, no downscale mush
		# (TD-050). The 9-slice only matters off-base: it keeps the end straps un-smeared and
		# the grain runs horizontally, so the centre stretches cleanly.
		# The contact shadow is drawn here, not baked, so it holds at any stretched width.
		var shadow := NinePatchRect.new()
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
		shadow.offset_top = sign_top + 3.0
		shadow.offset_left = 2.0
		shadow.offset_right = 3.0
		shadow.offset_bottom = 4.0
		shadow.texture = ptex
		shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.55)
		_patch_header(shadow)
		root.add_child(shadow)
		var sign := NinePatchRect.new()
		sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sign.set_anchors_preset(Control.PRESET_FULL_RECT)
		sign.offset_top = sign_top
		sign.texture = ptex
		sign.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# TD-059d: light the sign through the SAME board_surface.gdshader as the wall/frame/banner so
		# it belongs to the scene instead of reading as a flat, self-lit plaque on a torch-lit wall.
		# The header sits at the top centre, far from the corner sconces, so it takes the scene's cool
		# ambient (its carved relief in board_header_n) with only a whisper of torch reach — which is
		# exactly the cool-dark the top of the frame beside it already sits in. The gilt title is a
		# separate Godot Label drawn over this, so legibility is unaffected by how dim the wood goes.
		sign.material = _surface_material("res://assets/ui/board_header_n.png", 0.86, 1.0, Vector2.ONE, 1.6)
		_patch_header(sign)
		root.add_child(sign)
	else:
		var plaque := Panel.new()
		plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plaque.set_anchors_preset(Control.PRESET_FULL_RECT)
		plaque.offset_top = sign_top
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.20, 0.15, 0.11)
		psb.set_border_width_all(2)
		psb.border_color = Color(0.09, 0.06, 0.04)
		plaque.add_theme_stylebox_override("panel", psb)
		root.add_child(plaque)
	# The engraved title, centred in the sign's plank field between the top and bottom rails.
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.offset_top = sign_top + 4.0
	stack.offset_bottom = -5.0
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	root.add_child(stack)
	stack.add_child(_engraved_line("THE COLLEGIUM", 13, Color(0.86, 0.72, 0.42), 700))
	stack.add_child(_header_gap(1))
	stack.add_child(_engraved_line("Contract Board", 8, Color(0.62, 0.50, 0.31), 400))
	return root

# The sign's 9-slice margins (source 204x38, end straps inside 36/11).
func _patch_header(np: NinePatchRect) -> void:
	np.patch_margin_left = 36
	np.patch_margin_top = 11
	np.patch_margin_right = 36
	np.patch_margin_bottom = 11

func _header_gap(h: int) -> Control:
	var g := Control.new()
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.custom_minimum_size = Vector2(0, h)
	return g

# One line of ENGRAVED lettering: a dark incised cut with a lit face riding a pixel below it,
# so the glyphs read as chiselled into the plank rather than inked onto it (carved cathedral
# signage). Both labels share the rect; only the face carries the soft down-right AO.
func _engraved_line(text: String, size: int, face_color: Color, weight: int) -> Control:
	var font := Fonts.cinzel(weight)
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0, size + 1)
	for pass_i in 2:
		var is_cut := pass_i == 0
		var l := _card_label(text, size, Color(0.05, 0.03, 0.01, 0.92) if is_cut else face_color, false, true)
		if font != null:
			l.add_theme_font_override("font", font)
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position.y = -1.0 if is_cut else 0.0
		if not is_cut:
			# Aged gilt: worn back off full strength so it reads as centuries-old leaf.
			l.modulate = Color(1, 1, 1, 0.94)
			l.add_theme_constant_override("shadow_offset_x", 1)
			l.add_theme_constant_override("shadow_offset_y", 1)
			l.add_theme_color_override("font_shadow_color", Color(0.04, 0.02, 0.01, 0.85))
		row.add_child(l)
	return row

# Lift a card toward the viewer on hover (scale from its centre pivot).
func _hover_card(card: Control, s: float) -> void:
	if not is_instance_valid(card):
		return
	var t := card.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale", Vector2(s, s), 0.09)

# The primary-verb type badge, anchored in a notice's upper-left corner (Prototype v1).
func _verb_corner_badge(verb: String) -> Control:
	var badge := VerbBadge.new()
	badge.set_verb(verb)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 0.0; badge.anchor_right = 0.0
	badge.anchor_top = 0.0; badge.anchor_bottom = 0.0
	badge.offset_left = 5.0; badge.offset_right = 20.0
	badge.offset_top = 4.0; badge.offset_bottom = 19.0
	return badge

# A tack pinning a notice's top edge — nail · wax · pin · ribbon, chosen by the
# contractId so a given notice always wears the same tack (deterministic). Static decor.
func _notice_tack(cid: String) -> Control:
	var tack := TextureRect.new()
	tack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tack.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _tack_tex.is_empty():
		tack.texture = _tack_tex[absi((cid + "|tack").hash()) % _tack_tex.size()]
	tack.anchor_left = 0.5; tack.anchor_right = 0.5
	tack.anchor_top = 0.0; tack.anchor_bottom = 0.0
	tack.offset_left = -6.0; tack.offset_right = 6.0
	tack.offset_top = -5.0; tack.offset_bottom = 9.0
	return tack

func _card_label(text: String, size: int, color: Color, do_wrap: bool, center: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if do_wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _select_board_card(c: Dictionary) -> void:
	_board_selection = c
	if c.is_empty():
		_reader_open_cid = ""            # closing forgets the scroll (R199) …
		_reader_scroll_mem = 0
		_seal_prev.clear()               # … and the seal transition memory (R200)
	else:
		_log("select %s" % c.get("contractId", ""))
	# Cross-fade: fade the current view out, then rebuild (which fades the new in).
	var t := _popup_body.create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(_popup_body, "modulate:a", 0.0, 0.07)
	t.tween_callback(_rebuild_popup_body)

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

# A ShaderMaterial that lights a board surface from the torch rig (TD-047). Light2D does
# not reach these Control nodes, so board_surface.gdshader samples the normal map + the
# uniform torch lights itself. One rig (BoardDecor.torch_rig) feeds every surface (P72).
func _surface_material(normal_path: String, ambient: float = 0.42, diffuse_gain: float = 1.0, tile: Vector2 = Vector2.ONE, radius_scale: float = 1.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/ui/board_surface.gdshader") as Shader
	mat.set_shader_parameter("normal_tex", load(normal_path) as Texture2D)
	mat.set_shader_parameter("ambient", ambient)
	mat.set_shader_parameter("diffuse_gain", diffuse_gain)
	mat.set_shader_parameter("tile_scale", tile)   # >1 tiles a small seamless texture (the stone brick)
	var vp := get_viewport_rect().size
	var rig := BoardDecor.torch_rig(vp)
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var rads := PackedFloat32Array()
	for t in rig:
		uvs.append(t["uv"])
		var c: Color = t["color"]; c.a = 0.9             # energy in alpha (dimmed for the dungeon grade, TD-048)
		cols.append(c)
		# radius_scale widens ONE surface's reach without touching the shared torch_rig (P95/P102):
		# the board's tight 0.24 halo keeps the wall dungeon-dark, but the banner (hung above its
		# foot sconce) needs the throw to climb the cloth so its torch-lit gradient reads (TD-059).
		rads.append(t["radius"] * radius_scale)
	mat.set_shader_parameter("light_uv", uvs)
	mat.set_shader_parameter("light_col", cols)
	mat.set_shader_parameter("light_rad", rads)
	# `--lights-off` (debug, V1) kills the torch lights so a capture shows flat neutral wood —
	# the relief/warmth must vanish, proving the shader (not a baked diffuse) does the lighting.
	mat.set_shader_parameter("light_count", 0 if OS.get_cmdline_user_args().has("--lights-off") else rig.size())
	mat.set_shader_parameter("aspect", vp.x / maxf(1.0, vp.y))
	return mat

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
func _origin_word(origin: String) -> String:
	if origin.is_empty():
		return "?"
	return origin.substr(0, 1) + origin.substr(1).to_lower()

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

func _set_token(token: String) -> void:
	_reconnect_token = token
	if token == "":
		DirAccess.remove_absolute(TOKEN_PATH)
	else:
		var f := FileAccess.open(TOKEN_PATH, FileAccess.WRITE)
		if f:
			f.store_string(token)

func _load_token() -> String:
	if not FileAccess.file_exists(TOKEN_PATH):
		return ""
	var f := FileAccess.open(TOKEN_PATH, FileAccess.READ)
	return f.get_as_text().strip_edges() if f else ""

# ── UI builders ──────────────────────────────────────────────────────────────

func _clear() -> void:
	for child in _root.get_children():
		child.queue_free()

func _h1(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 17)
	_root.add_child(l)

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
	e.custom_minimum_size = Vector2(280, 0)
	_root.add_child(e)
	return e
