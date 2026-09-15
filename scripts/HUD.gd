extends CanvasLayer

signal skill_selected(skill_id: String)
signal open_build_menu
signal start_game_requested
signal pause_requested
signal resume_requested
signal restart_requested
signal quit_to_title_requested

@onready var score_label: Label = $ScoreLabel
@onready var distance_label: Label = $DistanceLabel
@onready var combo_label: Label = $ComboLabel
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/HPText
@onready var level_label: Label = $LevelLabel
@onready var exp_bar: ProgressBar = $ExpBar

@onready var title_panel: Control = $TitlePanel
@onready var menu_start_btn: Button = $TitlePanel/MenuContainer/StartButton
@onready var menu_build_btn: Button = $TitlePanel/MenuContainer/BuildButton

@onready var game_over_panel: Control = $GameOverPanel
@onready var retry_hint_label: Label = $GameOverPanel/RetryHint

# レベルアップスキル選択UI
@onready var level_up_modal: Control = $LevelUpModal
@onready var card_container: HBoxContainer = $LevelUpModal/CardContainer

# ポーズモーダルUI
@onready var pause_modal: Control = $PauseModal
@onready var pause_btn_resume: Button = $PauseModal/PauseMenu/ResumeButton
@onready var pause_btn_retry: Button = $PauseModal/PauseMenu/RetryButton
@onready var pause_btn_quit: Button = $PauseModal/PauseMenu/QuitButton
@onready var hud_pause_button: Button = $PauseHUDButton

var combo_count: int = 0
var combo_timer: float = 0.0

var current_offered_skills: Array = []
var selected_card_index: int = 0
var is_leveling_up: bool = false
var is_paused: bool = false
var pause_menu_index: int = 0
var title_menu_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.visible = false
	title_panel.visible = true
	combo_label.visible = false
	level_up_modal.visible = false
	pause_modal.visible = false
	
	menu_start_btn.pressed.connect(func(): start_game_requested.emit())
	menu_build_btn.pressed.connect(func(): open_build_menu.emit())
	
	hud_pause_button.pressed.connect(func():
		if not is_paused and not title_panel.visible and not is_leveling_up and not game_over_panel.visible:
			pause_requested.emit()
	)
	
	pause_btn_resume.pressed.connect(func(): resume_requested.emit())
	pause_btn_retry.pressed.connect(func(): restart_requested.emit())
	pause_btn_quit.pressed.connect(func(): quit_to_title_requested.emit())
	
	update_title_menu()

func _process(delta: float) -> void:
	if not get_tree().paused and combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			combo_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_paused:
		if event.is_action_pressed("ui_up"):
			pause_menu_index = (pause_menu_index - 1 + 3) % 3
			update_pause_menu()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			pause_menu_index = (pause_menu_index + 1) % 3
			update_pause_menu()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			match pause_menu_index:
				0: resume_requested.emit()
				1: restart_requested.emit()
				2: quit_to_title_requested.emit()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("pause_game") or event.is_action_pressed("ui_cancel"):
			resume_requested.emit()
			get_viewport().set_input_as_handled()
		return
		
	if is_leveling_up:
		if event.is_action_pressed("ui_left"):
			if current_offered_skills.size() > 0:
				selected_card_index = (selected_card_index - 1 + current_offered_skills.size()) % current_offered_skills.size()
				update_card_highlights()
				get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			if current_offered_skills.size() > 0:
				selected_card_index = (selected_card_index + 1) % current_offered_skills.size()
				update_card_highlights()
				get_viewport().set_input_as_handled()
		elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			confirm_selection()
			get_viewport().set_input_as_handled()
			
	elif title_panel.visible:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			title_menu_index = 1 - title_menu_index
			update_title_menu()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			if title_menu_index == 0:
				start_game_requested.emit()
			else:
				open_build_menu.emit()
			get_viewport().set_input_as_handled()
			
	elif not game_over_panel.visible:
		if event.is_action_pressed("pause_game"):
			pause_requested.emit()
			get_viewport().set_input_as_handled()

func show_pause() -> void:
	is_paused = true
	pause_menu_index = 0
	pause_modal.visible = true
	update_pause_menu()

func hide_pause() -> void:
	is_paused = false
	pause_modal.visible = false

func update_pause_menu() -> void:
	var btns := [pause_btn_resume, pause_btn_retry, pause_btn_quit]
	var labels := ["RESUME RUN", "RETRY RUN", "QUIT TO TITLE"]
	for i in range(btns.size()):
		if i == pause_menu_index:
			btns[i].modulate = Color(1.3, 1.3, 1.3, 1.0)
			btns[i].text = "▶ [ " + labels[i] + " ]"
		else:
			btns[i].modulate = Color(0.65, 0.7, 0.8, 0.8)
			btns[i].text = "  " + labels[i]

func update_title_menu() -> void:
	if title_menu_index == 0:
		menu_start_btn.modulate = Color(1.3, 1.3, 1.3, 1.0)
		menu_start_btn.text = "▶ [ START RUN ]"
		menu_build_btn.modulate = Color(0.6, 0.7, 0.8, 0.8)
		menu_build_btn.text = "  LOADOUT & BUILD"
	else:
		menu_start_btn.modulate = Color(0.6, 0.7, 0.8, 0.8)
		menu_start_btn.text = "  START RUN"
		menu_build_btn.modulate = Color(1.3, 1.3, 1.3, 1.0)
		menu_build_btn.text = "▶ [ LOADOUT & BUILD ]"

func update_stats(score: int, distance: float) -> void:
	score_label.text = "SCORE: %06d" % score
	distance_label.text = "%dm" % int(distance)

func update_hp(current: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current
	hp_label.text = "HP: %d / %d" % [current, max_hp]

func update_exp(current: int, target: int, level: int) -> void:
	level_label.text = "LV.%d" % level
	exp_bar.max_value = target
	exp_bar.value = current

func add_combo() -> void:
	combo_count += 1
	combo_timer = 2.5
	combo_label.text = "STOMP x%d!" % combo_count
	combo_label.visible = true
	
	combo_label.scale = Vector2(1.4, 1.4)
	var tween := create_tween()
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15)

func show_title() -> void:
	title_panel.visible = true
	game_over_panel.visible = false
	level_up_modal.visible = false
	pause_modal.visible = false
	hud_pause_button.visible = false
	title_menu_index = 0
	update_title_menu()

func hide_title() -> void:
	title_panel.visible = false
	hud_pause_button.visible = true

func show_level_up(skills: Array) -> void:
	is_leveling_up = true
	current_offered_skills = skills
	selected_card_index = 0
	level_up_modal.visible = true
	
	for child in card_container.get_children():
		child.queue_free()
		
	for i in range(skills.size()):
		var skill: Dictionary = skills[i]
		var card := create_skill_card(i, skill)
		card_container.add_child(card)
		
	update_card_highlights()

func create_skill_card(index: int, skill: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 260)
	btn.flat = true
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.offset_left = 10
	vbox.offset_right = -10
	
	var icon_lbl := Label.new()
	icon_lbl.text = skill.get("icon", "⭐")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 42)
	vbox.add_child(icon_lbl)
	
	var name_lbl := Label.new()
	name_lbl.text = skill.get("name", "SKILL")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0))
	vbox.add_child(name_lbl)
	
	var desc_lbl := Label.new()
	desc_lbl.text = skill.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(desc_lbl)
	
	btn.add_child(vbox)
	
	btn.pressed.connect(func():
		selected_card_index = index
		confirm_selection()
	)
	return btn

func update_card_highlights() -> void:
	var cards := card_container.get_children()
	for i in range(cards.size()):
		var card: Button = cards[i] as Button
		if i == selected_card_index:
			card.modulate = Color(1.3, 1.3, 1.3, 1.0)
			card.scale = Vector2(1.06, 1.06)
		else:
			card.modulate = Color(0.65, 0.65, 0.75, 0.8)
			card.scale = Vector2(0.96, 0.96)

func confirm_selection() -> void:
	if not is_leveling_up:
		return
	if selected_card_index < current_offered_skills.size():
		var chosen: Dictionary = current_offered_skills[selected_card_index]
		is_leveling_up = false
		level_up_modal.visible = false
		skill_selected.emit(chosen.get("id", ""))

func show_game_over(final_score: int, high_score: int, earned_coins: int) -> void:
	game_over_panel.visible = true
	level_up_modal.visible = false
	pause_modal.visible = false
	hud_pause_button.visible = false
	var score_text: Label = $GameOverPanel/ScoreText
	score_text.text = "SCORE: %d\nBEST: %d\n+ %d SHARDS 💎" % [final_score, high_score, earned_coins]
	
	retry_hint_label.modulate.a = 0.0
	var tween := create_tween().set_loops()
	tween.tween_property(retry_hint_label, "modulate:a", 1.0, 0.25)
	tween.tween_property(retry_hint_label, "modulate:a", 0.2, 0.25)

func hide_game_over() -> void:
	game_over_panel.visible = false
