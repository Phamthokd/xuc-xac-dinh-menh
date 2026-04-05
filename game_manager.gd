extends Control

signal network_state_ready(state_json: String)
signal network_action_requested(action_json: String)

enum TileType { TREASURE, TRAP, SWAMP, PORTAL, GIFT, PEACEFUL, STEAL, CHAOS }
enum NetworkMode { OFFLINE, HOST, CLIENT }

const PLAYER_LABELS = ["Nguoi choi 1", "Nguoi choi 2"]
const PLAYER_TITLES = ["Hiep si Xanh", "Cung thu Do"]
const ITEM_REROLL = "Xuc xac lan hai"
const ITEM_SHIELD = "Khien bay"
const ITEM_BOOTS = "Giay +2"
const BOARD_COLS = 8
const TOP_TILES = 8
const RIGHT_TILES = 4
const BOTTOM_TILES = 8
const LEFT_TILES = 4
const TILE_DATA = [
	{"color": Color(0.9, 0.75, 0.1), "icon": "KB", "name": "Kho bau"},
	{"color": Color(0.85, 0.15, 0.15), "icon": "BG", "name": "Bay gai"},
	{"color": Color(0.3, 0.55, 0.3), "icon": "VL", "name": "Vung lay"},
	{"color": Color(0.2, 0.55, 0.9), "icon": "CD", "name": "Cong dich chuyen"},
	{"color": Color(0.9, 0.5, 0.15), "icon": "QM", "name": "Qua may man"},
	{"color": Color(0.55, 0.55, 0.6), "icon": "BY", "name": "Binh yen"},
	{"color": Color(0.8, 0.25, 0.7), "icon": "CP", "name": "Cuop diem"},
	{"color": Color(0.6, 0.15, 0.8), "icon": "?", "name": "Hon loan"},
]

var player_scores = [0, 0]
var player_positions = [0, 0]
var player_items = [[], []]
var player_skips = [0, 0]
var current_player = 0
var current_turn = 1
var max_turns = 20
var is_moving = false

var board_data = []
var tile_nodes = []
var tile_size := 80.0
var token_base_offset := Vector2(0, -28)
var token_stack_offsets := [Vector2(-22, -28), Vector2(22, -28)]
var match_seed := 0
var action_history: Array[Dictionary] = []
var network_mode := NetworkMode.OFFLINE
var local_player_index := 0
var session_code := ""
var last_event := {"title": "", "desc": ""}
var match_rng := RandomNumberGenerator.new()
var websocket := WebSocketPeer.new()
var websocket_url := "ws://127.0.0.1:8787"
var socket_connected := false
var suppress_state_emit := false
var gameplay_visible := false

@onready var board_layer: Node2D = $BoardLayer
@onready var tiles_root: Node2D = $BoardLayer/Tiles
@onready var p1_token: Sprite2D = $BoardLayer/P1_Token
@onready var p2_token: Sprite2D = $BoardLayer/P2_Token
@onready var header: Panel = $UI/Header
@onready var score_box: HBoxContainer = $UI/Header/ScoreBox
@onready var menu_button: Button = $UI/Header/MenuButton
@onready var score_p1: Label = $UI/Header/ScoreBox/P1_Info/ScoreP1
@onready var items_p1: Label = $UI/Header/ScoreBox/P1_Info/ItemsP1
@onready var score_p2: Label = $UI/Header/ScoreBox/P2_Info/ScoreP2
@onready var items_p2: Label = $UI/Header/ScoreBox/P2_Info/ItemsP2
@onready var turn_label: Label = $UI/Header/ScoreBox/TurnLabel
@onready var controls: VBoxContainer = $UI/Controls
@onready var dice_label: Label = $UI/Controls/DiceValue
@onready var roll_button: Button = $UI/Controls/RollButton
@onready var status_label: Label = $UI/StatusLabel
@onready var network_label: Label = $UI/NetworkLabel
@onready var event_pop: Panel = $UI/EventPop
@onready var event_title: Label = $UI/EventPop/Title
@onready var event_desc: Label = $UI/EventPop/Desc
@onready var close_pop: Button = $UI/EventPop/ClosePop
@onready var lobby_panel: Panel = $UI/LobbyPanel
@onready var lobby_box: Panel = $UI/LobbyPanel/LobbyMargin/LobbyBox
@onready var room_code_input: LineEdit = $UI/LobbyPanel/LobbyMargin/LobbyBox/LobbyContentMargin/LobbyRow/ModeCard/ModeMargin/ModeColumn/RoomCodeInput
@onready var server_url_input: LineEdit = $UI/LobbyPanel/LobbyMargin/LobbyBox/LobbyContentMargin/LobbyRow/ModeCard/ModeMargin/ModeColumn/ServerUrlInput
@onready var lobby_status: Label = $UI/LobbyPanel/LobbyMargin/LobbyBox/LobbyContentMargin/LobbyRow/ModeCard/ModeMargin/ModeColumn/LobbyStatus

func _ready():
	build_tile_nodes()
	start_new_match()
	server_url_input.text = infer_default_websocket_url()
	layout_scene()
	refresh_all_ui()
	show_start_menu()
	get_viewport().size_changed.connect(_on_viewport_resized)
	network_state_ready.connect(_send_state_to_socket)
	network_action_requested.connect(_send_action_to_socket)

func _process(_delta: float):
	poll_socket()

func _on_viewport_resized():
	layout_scene()
	refresh_all_ui()

func build_tile_nodes():
	for i in range(24):
		var tile_container := Control.new()
		tiles_root.add_child(tile_container)

		var bg_rect := ColorRect.new()
		tile_container.add_child(bg_rect)

		var border := ReferenceRect.new()
		border.editor_description = "border"
		border.border_width = 2
		tile_container.add_child(border)

		var index_label := Label.new()
		index_label.text = str(i + 1)
		index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile_container.add_child(index_label)

		var icon_label := Label.new()
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile_container.add_child(icon_label)

		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile_container.add_child(name_label)

		tile_nodes.append({
			"container": tile_container,
			"bg": bg_rect,
			"border": border,
			"index": index_label,
			"icon": icon_label,
			"name": name_label,
		})

func start_new_match(seed: int = -1):
	if seed < 0:
		seed = int(Time.get_unix_time_from_system())
	match_seed = seed
	match_rng.seed = seed
	action_history.clear()
	last_event = {"title": "", "desc": ""}
	player_scores = [0, 0]
	player_positions = [0, 0]
	player_items = [[], []]
	player_skips = [0, 0]
	current_player = 0
	current_turn = 1
	is_moving = false
	roll_button.disabled = false
	roll_button.show()
	dice_label.text = "1"
	event_pop.hide()
	setup_board_from_seed(seed)

func setup_board_from_seed(seed: int):
	board_data.clear()
	var board_rng := RandomNumberGenerator.new()
	board_rng.seed = seed

	for i in range(24):
		var tile_type = get_weighted_random_type(board_rng)
		board_data.append({"type": tile_type, "pos": Vector2.ZERO})

func layout_scene():
	var viewport_size = get_viewport_rect().size
	var compact = viewport_size.x < 1000.0
	var header_height = clampf(viewport_size.y * (0.14 if compact else 0.12), 84.0, 118.0)

	header.offset_bottom = header_height
	score_box.offset_left = 20.0
	score_box.offset_top = 8.0
	score_box.offset_right = -20.0
	score_box.offset_bottom = -8.0
	score_box.add_theme_constant_override("separation", 18 if compact else 28)

	var score_font = 20 if compact else 24
	var items_font = 12 if compact else 15
	var turn_font = 30 if compact else 36
	score_p1.add_theme_font_size_override("font_size", score_font)
	score_p2.add_theme_font_size_override("font_size", score_font)
	items_p1.add_theme_font_size_override("font_size", items_font)
	items_p2.add_theme_font_size_override("font_size", items_font)
	turn_label.add_theme_font_size_override("font_size", turn_font)

	network_label.offset_top = header_height + 6.0
	network_label.add_theme_font_size_override("font_size", 14 if compact else 16)
	menu_button.visible = gameplay_visible
	menu_button.offset_left = -110.0
	menu_button.offset_right = -18.0
	menu_button.offset_top = 16.0
	menu_button.offset_bottom = 54.0
	lobby_panel.self_modulate = Color(1, 1, 1, 0.97)
	lobby_panel.modulate = Color(1, 1, 1, 1)
	lobby_box.offset_left = -340.0 if compact else -420.0
	lobby_box.offset_right = 340.0 if compact else 420.0
	lobby_box.offset_top = -220.0 if compact else -200.0
	lobby_box.offset_bottom = 220.0 if compact else 200.0

	var popup_width = minf(viewport_size.x - 40.0, 520.0 if compact else 620.0)
	var popup_height = minf(viewport_size.y * 0.42, 300.0 if compact else 340.0)
	event_pop.offset_left = -popup_width * 0.5
	event_pop.offset_right = popup_width * 0.5
	event_pop.offset_top = -popup_height * 0.5
	event_pop.offset_bottom = popup_height * 0.5
	event_title.add_theme_font_size_override("font_size", 24 if compact else 30)
	event_desc.add_theme_font_size_override("font_size", 17 if compact else 20)
	close_pop.custom_minimum_size = Vector2(120, 44 if compact else 52)

	status_label.offset_top = -52.0
	status_label.add_theme_font_size_override("font_size", 18 if compact else 22)

	dice_label.custom_minimum_size = Vector2(84 if compact else 100, 84 if compact else 100)
	dice_label.add_theme_font_size_override("font_size", 54 if compact else 64)
	roll_button.custom_minimum_size = Vector2(220 if compact else 260, 64 if compact else 76)
	roll_button.add_theme_font_size_override("font_size", 22 if compact else 26)
	controls.offset_left = -roll_button.custom_minimum_size.x * 0.5
	controls.offset_right = roll_button.custom_minimum_size.x * 0.5
	controls.offset_top = -10.0
	controls.offset_bottom = 120.0 if compact else 132.0

	layout_board(viewport_size, header_height)

func layout_board(viewport_size: Vector2, header_height: float):
	var horizontal_padding = 24.0
	var top_padding = header_height + 36.0
	var bottom_padding = 120.0
	var available_size = Vector2(
		maxf(320.0, viewport_size.x - horizontal_padding * 2.0),
		maxf(260.0, viewport_size.y - top_padding - bottom_padding)
	)

	tile_size = minf(available_size.x / 11.2, available_size.y / 6.5)
	tile_size = clampf(tile_size, 50.0, 86.0)

	var step_x = tile_size * 1.45
	var step_y = tile_size * 1.34
	var board_width = step_x * float(BOARD_COLS - 1)
	var board_height = step_y * 4.0
	board_layer.position = Vector2(viewport_size.x * 0.5, top_padding + available_size.y * 0.5)

	token_base_offset = Vector2(0, -tile_size * 0.33)
	token_stack_offsets = [
		Vector2(-tile_size * 0.3, -tile_size * 0.33),
		Vector2(tile_size * 0.3, -tile_size * 0.33)
	]

	var token_scale = (tile_size * 1.12) / 1024.0
	p1_token.scale = Vector2.ONE * token_scale
	p2_token.scale = Vector2.ONE * token_scale

	for i in range(board_data.size()):
		var pos := Vector2.ZERO
		if i < TOP_TILES:
			pos = Vector2(-board_width * 0.5 + i * step_x, -board_height * 0.5)
		elif i < TOP_TILES + RIGHT_TILES:
			pos = Vector2(board_width * 0.5, -board_height * 0.5 + (i - (TOP_TILES - 1)) * step_y)
		elif i < TOP_TILES + RIGHT_TILES + BOTTOM_TILES:
			pos = Vector2(board_width * 0.5 - (i - (TOP_TILES + RIGHT_TILES)) * step_x, board_height * 0.5)
		else:
			pos = Vector2(-board_width * 0.5, board_height * 0.5 - (i - (TOP_TILES + RIGHT_TILES + BOTTOM_TILES - 1)) * step_y)

		board_data[i]["pos"] = pos
		apply_tile_layout(i, pos)

func apply_tile_layout(index: int, pos: Vector2):
	var tile_info: Dictionary = tile_nodes[index]
	var tile_type: int = board_data[index]["type"]
	var tile_meta: Dictionary = TILE_DATA[tile_type]
	var tile_container: Control = tile_info["container"]
	var bg_rect: ColorRect = tile_info["bg"]
	var border: ReferenceRect = tile_info["border"]
	var index_label: Label = tile_info["index"]
	var icon_label: Label = tile_info["icon"]
	var name_label: Label = tile_info["name"]

	tile_container.custom_minimum_size = Vector2.ONE * tile_size
	tile_container.position = pos - Vector2.ONE * tile_size * 0.5

	bg_rect.size = Vector2.ONE * tile_size
	bg_rect.color = tile_meta["color"].darkened(0.55)
	border.size = Vector2.ONE * tile_size
	border.border_color = tile_meta["color"].lightened(0.2)

	index_label.offset_top = 2.0
	index_label.offset_right = tile_size
	index_label.size = Vector2(tile_size, tile_size * 0.2)
	index_label.add_theme_font_size_override("font_size", maxi(11, int(tile_size * 0.21)))

	icon_label.text = tile_meta["icon"]
	icon_label.offset_top = tile_size * 0.18
	icon_label.offset_right = tile_size
	icon_label.size = Vector2(tile_size, tile_size * 0.4)
	icon_label.add_theme_font_size_override("font_size", maxi(16, int(tile_size * 0.28)))

	name_label.text = tile_meta["name"]
	name_label.offset_left = 4.0
	name_label.offset_top = tile_size * 0.6
	name_label.offset_right = tile_size - 4.0
	name_label.size = Vector2(tile_size - 8.0, tile_size * 0.34)
	name_label.add_theme_font_size_override("font_size", maxi(8, int(tile_size * 0.11)))

func get_weighted_random_type(rng: RandomNumberGenerator) -> int:
	var r = rng.randi_range(0, 23)
	if r < 4:
		return TileType.TREASURE
	if r < 8:
		return TileType.TRAP
	if r < 11:
		return TileType.SWAMP
	if r < 14:
		return TileType.PORTAL
	if r < 17:
		return TileType.GIFT
	if r < 20:
		return TileType.STEAL
	if r < 21:
		return TileType.CHAOS
	return TileType.PEACEFUL

func refresh_all_ui():
	update_ui()
	update_network_label()
	update_lobby_status()
	place_tokens()

func set_gameplay_visible(visible: bool):
	gameplay_visible = visible
	board_layer.visible = visible
	header.visible = visible
	controls.visible = visible
	status_label.visible = visible
	network_label.visible = visible
	if not visible:
		event_pop.hide()
	menu_button.visible = visible

func show_start_menu():
	set_gameplay_visible(false)
	lobby_panel.show()
	lobby_status.text = "Chon che do choi de bat dau."

func enter_match():
	lobby_panel.hide()
	set_gameplay_visible(true)
	refresh_all_ui()

func update_ui():
	score_p1.text = "%s (%s): %d" % [PLAYER_LABELS[0], PLAYER_TITLES[0], player_scores[0]]
	score_p2.text = "%s (%s): %d" % [PLAYER_LABELS[1], PLAYER_TITLES[1], player_scores[1]]
	turn_label.text = "Luot %d/%d" % [current_turn, max_turns]
	items_p1.text = "Vat pham: " + str(player_items[0])
	items_p2.text = "Vat pham: " + str(player_items[1])
	status_label.text = "Luot cua %s" % PLAYER_LABELS[current_player]
	roll_button.disabled = is_moving or not can_local_player_roll()

func update_network_label():
	var mode_name = "Offline"
	if network_mode == NetworkMode.HOST:
		mode_name = "Host"
	elif network_mode == NetworkMode.CLIENT:
		mode_name = "Client"

	var player_name = PLAYER_LABELS[local_player_index]
	var session_text = ""
	if session_code != "":
		session_text = " | Room %s" % session_code

	network_label.text = "Mode: %s | Local: %s%s" % [mode_name, player_name, session_text]

func can_local_player_roll() -> bool:
	if event_pop.visible:
		return false
	if network_mode == NetworkMode.OFFLINE:
		return true
	return current_player == local_player_index

func set_offline_mode():
	network_mode = NetworkMode.OFFLINE
	local_player_index = 0
	session_code = ""
	refresh_all_ui()

func host_online_match(room_code: String = ""):
	network_mode = NetworkMode.HOST
	local_player_index = 0
	session_code = room_code
	emit_current_state()
	refresh_all_ui()

func join_online_match(room_code: String = "", player_index: int = 1):
	network_mode = NetworkMode.CLIENT
	local_player_index = clampi(player_index, 0, 1)
	session_code = room_code
	refresh_all_ui()

func update_lobby_status():
	if network_mode == NetworkMode.OFFLINE:
		lobby_status.text = "Dang o che do offline."
	elif network_mode == NetworkMode.HOST:
		lobby_status.text = "Ban dang host phong %s. %s" % [session_code, _socket_status_suffix()]
	else:
		lobby_status.text = "Ban da tham gia phong %s voi vai tro %s. %s" % [session_code, PLAYER_LABELS[local_player_index], _socket_status_suffix()]

func _socket_status_suffix() -> String:
	if socket_connected:
		return "Socket da ket noi."
	return "Socket chua ket noi."

func infer_default_websocket_url() -> String:
	if OS.has_feature("web"):
		var protocol = String(JavaScriptBridge.eval("window.location.protocol", true))
		var host = String(JavaScriptBridge.eval("window.location.host", true))
		if protocol == "https:":
			return "wss://%s/ws" % host
		return "ws://%s/ws" % host
	return websocket_url

func generate_room_code() -> String:
	const CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code := ""
	for _i in range(6):
		code += CHARS[match_rng.randi_range(0, CHARS.length() - 1)]
	return code

func _on_offline_button_pressed():
	disconnect_socket()
	set_offline_mode()
	enter_match()

func _on_host_button_pressed():
	var code = room_code_input.text.strip_edges().to_upper()
	if code == "":
		code = generate_room_code()
	room_code_input.text = code
	host_online_match(code)
	connect_socket_if_needed()
	send_socket_message({
		"type": "host_room",
		"room_code": code,
		"player_index": 0,
		"state": build_match_state(),
	})
	enter_match()

func _on_join_button_pressed():
	var code = room_code_input.text.strip_edges().to_upper()
	if code == "":
		lobby_status.text = "Hay nhap ma phong truoc khi tham gia."
		return
	join_online_match(code, 1)
	connect_socket_if_needed()
	send_socket_message({
		"type": "join_room",
		"room_code": code,
		"player_index": 1,
	})
	enter_match()

func _on_menu_button_pressed():
	show_start_menu()

func emit_current_state():
	if suppress_state_emit:
		return
	var json = JSON.stringify(build_match_state())
	network_state_ready.emit(json)

func build_match_state() -> Dictionary:
	var board_types: Array[int] = []
	for tile in board_data:
		board_types.append(tile["type"])

	return {
		"version": 1,
		"match_seed": match_seed,
		"board_types": board_types,
		"player_scores": player_scores.duplicate(),
		"player_positions": player_positions.duplicate(),
		"player_items": [player_items[0].duplicate(), player_items[1].duplicate()],
		"player_skips": player_skips.duplicate(),
		"current_player": current_player,
		"current_turn": current_turn,
		"max_turns": max_turns,
		"dice_value": dice_label.text,
		"last_event": last_event.duplicate(true),
		"network_mode": network_mode,
		"local_player_index": local_player_index,
		"session_code": session_code,
		"rng_state": str(match_rng.state),
		"action_history": action_history.duplicate(true),
	}

func apply_match_state(state: Dictionary):
	if not state.has("board_types"):
		return

	match_seed = int(state.get("match_seed", 0))
	player_scores = state.get("player_scores", [0, 0]).duplicate()
	player_positions = state.get("player_positions", [0, 0]).duplicate()
	player_items = [
		state.get("player_items", [[], []])[0].duplicate(),
		state.get("player_items", [[], []])[1].duplicate()
	]
	player_skips = state.get("player_skips", [0, 0]).duplicate()
	current_player = int(state.get("current_player", 0))
	current_turn = int(state.get("current_turn", 1))
	max_turns = int(state.get("max_turns", 20))
	dice_label.text = str(state.get("dice_value", "1"))
	last_event = state.get("last_event", {"title": "", "desc": ""}).duplicate(true)
	session_code = str(state.get("session_code", session_code))

	var board_types: Array = state["board_types"]
	if board_data.size() != board_types.size():
		setup_board_from_seed(match_seed)
	for i in range(board_types.size()):
		board_data[i]["type"] = int(board_types[i])

	if state.has("rng_state"):
		match_rng.state = int(state["rng_state"])
	action_history = state.get("action_history", []).duplicate(true)
	event_pop.hide()
	layout_scene()
	refresh_all_ui()

func load_match_state_json(state_json: String) -> bool:
	var parsed = JSON.parse_string(state_json)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	apply_match_state(parsed)
	return true

func build_roll_request() -> Dictionary:
	return {
		"type": "roll_request",
		"player": current_player,
		"turn": current_turn,
		"session_code": session_code,
	}

func request_remote_roll():
	var request = build_roll_request()
	network_action_requested.emit(JSON.stringify(request))

func append_action_history(entry: Dictionary):
	action_history.append(entry.duplicate(true))
	emit_current_state()

func connect_socket_if_needed():
	websocket_url = server_url_input.text.strip_edges()
	if websocket_url == "":
		lobby_status.text = "Hay nhap WebSocket URL."
		return
	if socket_connected and websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		return
	websocket = WebSocketPeer.new()
	var err = websocket.connect_to_url(websocket_url)
	if err != OK:
		lobby_status.text = "Khong the mo socket: %s" % err
		return
	lobby_status.text = "Dang ket noi WebSocket..."

func disconnect_socket():
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.close()
	socket_connected = false

func poll_socket():
	var state = websocket.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		if socket_connected:
			socket_connected = false
			update_lobby_status()
		return

	websocket.poll()
	state = websocket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not socket_connected:
		socket_connected = true
		update_lobby_status()
		if network_mode == NetworkMode.HOST and session_code != "":
			send_socket_message({
				"type": "host_room",
				"room_code": session_code,
				"player_index": 0,
				"state": build_match_state(),
			})
		elif network_mode == NetworkMode.CLIENT and session_code != "":
			send_socket_message({
				"type": "join_room",
				"room_code": session_code,
				"player_index": local_player_index,
			})

	while state == WebSocketPeer.STATE_OPEN and websocket.get_available_packet_count() > 0:
		var packet = websocket.get_packet()
		var text = packet.get_string_from_utf8()
		_handle_socket_message(text)

func send_socket_message(payload: Dictionary):
	if websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var text = JSON.stringify(payload)
	websocket.send_text(text)

func _send_state_to_socket(state_json: String):
	if network_mode != NetworkMode.HOST:
		return
	var parsed = JSON.parse_string(state_json)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	send_socket_message({
		"type": "state_update",
		"room_code": session_code,
		"state": parsed,
	})

func _send_action_to_socket(action_json: String):
	var parsed = JSON.parse_string(action_json)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	parsed["room_code"] = session_code
	parsed["sender"] = local_player_index
	send_socket_message(parsed)

func _handle_socket_message(text: String):
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	match str(parsed.get("type", "")):
		"room_hosted":
			session_code = str(parsed.get("room_code", session_code))
			room_code_input.text = session_code
			update_lobby_status()
			if parsed.has("state") and typeof(parsed["state"]) == TYPE_DICTIONARY:
				suppress_state_emit = true
				apply_match_state(parsed["state"])
				suppress_state_emit = false
		"room_joined":
			session_code = str(parsed.get("room_code", session_code))
			room_code_input.text = session_code
			update_lobby_status()
			if parsed.has("state") and typeof(parsed["state"]) == TYPE_DICTIONARY:
				suppress_state_emit = true
				apply_match_state(parsed["state"])
				suppress_state_emit = false
		"state_update":
			if network_mode == NetworkMode.CLIENT and parsed.has("state") and typeof(parsed["state"]) == TYPE_DICTIONARY:
				suppress_state_emit = true
				apply_match_state(parsed["state"])
				suppress_state_emit = false
		"action_request":
			if network_mode == NetworkMode.HOST:
				_handle_remote_action_request(parsed)
		"error":
			lobby_status.text = str(parsed.get("message", "Socket error."))

func _handle_remote_action_request(message: Dictionary):
	var action_type = str(message.get("action", message.get("type", "")))
	if action_type == "roll_request":
		var request_player = int(message.get("player", -1))
		if request_player == current_player:
			await _perform_authoritative_roll()

func _perform_authoritative_roll():
	if is_moving:
		return
	if player_skips[current_player] > 0:
		player_skips[current_player] -= 1
		show_event("MAT LUOT", "Ban dang bi lay. Luot nay bi bo qua.")
		append_action_history({"type": "skip_turn", "player": current_player, "turn": current_turn})
		return

	var bonus_steps = 0
	if ITEM_BOOTS in player_items[current_player]:
		player_items[current_player].erase(ITEM_BOOTS)
		bonus_steps = 2
		status_label.text = "Giay +2 kich hoat. +2 buoc."
		update_ui()
		await get_tree().create_timer(1.0).timeout

	is_moving = true
	roll_button.disabled = true

	for _i in range(10):
		dice_label.text = str(match_rng.randi_range(1, 6))
		await get_tree().create_timer(0.05).timeout

	var base_roll = match_rng.randi_range(1, 6)
	var roll = base_roll + bonus_steps
	dice_label.text = str(base_roll)
	status_label.text = "Dang di chuyen %d buoc..." % roll
	append_action_history({
		"type": "roll_turn",
		"player": current_player,
		"turn": current_turn,
		"base_roll": base_roll,
		"bonus_steps": bonus_steps,
	})
	await animate_move(roll)

func place_tokens():
	p1_token.position = get_token_offset_pos(player_positions[0], 0)
	p2_token.position = get_token_offset_pos(player_positions[1], 1)

func get_token_offset_pos(tile_index: int, player_index: int) -> Vector2:
	var base_pos = board_data[tile_index]["pos"]
	if player_positions[0] == player_positions[1]:
		return base_pos + token_stack_offsets[player_index]
	return base_pos + token_base_offset

func _on_roll_button_pressed():
	if is_moving:
		return
	if network_mode == NetworkMode.CLIENT:
		request_remote_roll()
		return
	await _perform_authoritative_roll()

func animate_move(steps: int):
	var token = p1_token if current_player == 0 else p2_token
	var pos_index = player_positions[current_player]

	for i in range(steps):
		pos_index = (pos_index + 1) % board_data.size()
		var target_pos = board_data[pos_index]["pos"] + token_base_offset
		if i == steps - 1:
			target_pos = get_token_offset_pos(pos_index, current_player)

		var tween = create_tween()
		tween.tween_property(token, "position", target_pos, 0.18).set_trans(Tween.TRANS_SINE)
		await tween.finished

	player_positions[current_player] = pos_index
	await handle_tile_event(pos_index)

func handle_tile_event(index: int):
	var tile = board_data[index]
	var has_shield = ITEM_SHIELD in player_items[current_player]

	match tile["type"]:
		TileType.TREASURE:
			player_scores[current_player] += 3
			show_event("KHO BAU", "+3 diem. Mot kho bau lung linh xuat hien.")
		TileType.TRAP:
			if has_shield:
				player_items[current_player].erase(ITEM_SHIELD)
				show_event("CHAN BAY", "Khien bay da bao ve ban.")
			else:
				player_scores[current_player] = max(0, player_scores[current_player] - 2)
				show_event("BAY GAI", "-2 diem. Ban vua dam phai bay.")
		TileType.SWAMP:
			if has_shield:
				player_items[current_player].erase(ITEM_SHIELD)
				show_event("CHAN LAY", "Khien bay giup ban vuot qua vung lay.")
			else:
				player_skips[current_player] = 1
				show_event("VUNG LAY", "Lun sau. Ban mat luot ke tiep.")
		TileType.PORTAL:
			var target = match_rng.randi_range(0, board_data.size() - 1)
			show_event("CONG DICH CHUYEN", "Dich chuyen den o %d." % [target + 1])
			await get_tree().create_timer(1.0).timeout
			player_positions[current_player] = target
			place_tokens()
			append_action_history({"type": "portal", "player": current_player, "target": target})
			await handle_tile_event(target)
			return
		TileType.GIFT:
			receive_random_item()
			show_event("QUA MAY MAN", "Ban nhan duoc mot vat pham.")
		TileType.STEAL:
			var other = 1 - current_player
			var stolen = min(2, player_scores[other])
			player_scores[other] -= stolen
			player_scores[current_player] += stolen
			show_event("CUOP DIEM", "Lay %d diem tu doi thu." % stolen)
		TileType.CHAOS:
			await handle_chaos()
		TileType.PEACEFUL:
			show_event("BINH YEN", "Mot noi yen a, khong co gi xay ra.")

	update_ui()
	append_action_history({
		"type": "tile_event",
		"player": current_player,
		"tile_index": index,
		"tile_type": tile["type"],
		"scores": player_scores.duplicate(),
		"items": [player_items[0].duplicate(), player_items[1].duplicate()],
		"skips": player_skips.duplicate(),
	})

func receive_random_item():
	var items = [ITEM_REROLL, ITEM_SHIELD, ITEM_BOOTS]
	var item = items[match_rng.randi_range(0, items.size() - 1)]
	if player_items[current_player].size() < 3:
		player_items[current_player].append(item)
	else:
		player_items[current_player][0] = item

func handle_chaos():
	var r = match_rng.randi_range(0, 3)
	match r:
		0:
			player_scores[current_player] += 3
			show_event("HON LOAN", "+3 diem. May man mim cuoi.")
		1:
			player_scores[current_player] = max(0, player_scores[current_player] - 3)
			show_event("HON LOAN", "-3 diem. Van rui bua vay.")
		2:
			show_event("HON LOAN", "Tien len 2 buoc.")
			await get_tree().create_timer(1.0).timeout
			await animate_move(2)
		3:
			receive_random_item()
			show_event("HON LOAN", "Nhan vat pham ngau nhien.")

func show_event(title: String, desc: String):
	last_event = {"title": title, "desc": desc}
	event_title.text = title
	event_desc.text = desc
	event_pop.show()

func _on_close_pop_pressed():
	event_pop.hide()
	next_turn()

func next_turn():
	if current_player == 1:
		current_turn += 1

	if current_turn > max_turns:
		end_game()
		return

	current_player = 1 - current_player
	is_moving = false
	update_ui()
	append_action_history({"type": "next_turn", "current_player": current_player, "current_turn": current_turn})

func end_game():
	var winner = PLAYER_LABELS[0]
	if player_scores[1] > player_scores[0]:
		winner = PLAYER_LABELS[1]
	elif player_scores[1] == player_scores[0]:
		winner = "Hoa nhau"

	show_event("TRAN DAU KET THUC", "Nguoi thang: %s\nDiem so: %d / %d" % [winner, player_scores[0], player_scores[1]])
	roll_button.hide()
	append_action_history({"type": "game_over", "winner": winner, "scores": player_scores.duplicate()})
