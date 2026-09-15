extends Control

const EquipmentDatabaseScript = preload("res://scripts/EquipmentDatabase.gd")
const BuildManagerScript = preload("res://scripts/BuildManager.gd")

@onready var currency_label: Label = $CurrencyLabel
@onready var tab_container: HBoxContainer = $TabContainer
@onready var item_container: VBoxContainer = $ScrollContainer/ItemContainer
@onready var detail_panel: Panel = $DetailPanel
@onready var detail_icon: Label = $DetailPanel/DetailIcon
@onready var detail_name: Label = $DetailPanel/DetailName
@onready var detail_desc: Label = $DetailPanel/DetailDesc
@onready var action_button: Button = $DetailPanel/ActionButton
@onready var back_button: Button = $BackButton

var build_manager = null
var current_tab: int = 0 # 0: Weapons, 1: Accessories, 2: Perks
var current_items: Array = []
var selected_item_index: int = 0

func _ready() -> void:
	build_manager = BuildManagerScript.new()
	
	back_button.focus_mode = Control.FOCUS_NONE
	action_button.focus_mode = Control.FOCUS_NONE
	
	back_button.pressed.connect(_on_back_pressed)
	action_button.pressed.connect(_on_action_pressed)
	
	current_tab = 0
	selected_item_index = 0
	refresh_ui()

func _input(event: InputEvent) -> void:
	# Bボタン / ESC / Back 入力でタイトルシーンへ戻る
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return
		
	# 十字キー左右: タブの切り替え (WEAPONS ⇄ RELICS ⇄ PERKS)
	if event.is_action_pressed("ui_left"):
		current_tab = (current_tab - 1 + 3) % 3
		selected_item_index = 0
		refresh_ui()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("ui_right"):
		current_tab = (current_tab + 1) % 3
		selected_item_index = 0
		refresh_ui()
		get_viewport().set_input_as_handled()
		return
		
	# 十字キー上下: アイテムリスト内の選択移動（リスト内でループ）
	if event.is_action_pressed("ui_up"):
		if current_items.size() > 0:
			selected_item_index = (selected_item_index - 1 + current_items.size()) % current_items.size()
			update_selection()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("ui_down"):
		if current_items.size() > 0:
			selected_item_index = (selected_item_index + 1) % current_items.size()
			update_selection()
		get_viewport().set_input_as_handled()
		return
		
	# Aボタン / Enter / Space (ui_accept / jump): 選択中アイテムの装備・強化
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_on_action_pressed()
		get_viewport().set_input_as_handled()
		return

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func refresh_ui() -> void:
	if not build_manager:
		return
		
	currency_label.text = "CORE SHARDS: %d 💎" % build_manager.coins
	update_tabs()
	
	for child in item_container.get_children():
		child.queue_free()
		
	current_items.clear()
	match current_tab:
		0:
			for key in EquipmentDatabaseScript.WEAPONS.keys():
				current_items.append(EquipmentDatabaseScript.WEAPONS[key])
		1:
			for key in EquipmentDatabaseScript.ACCESSORIES.keys():
				current_items.append(EquipmentDatabaseScript.ACCESSORIES[key])
		2:
			for key in EquipmentDatabaseScript.PERKS.keys():
				current_items.append(EquipmentDatabaseScript.PERKS[key])
				
	for i in range(current_items.size()):
		var item: Dictionary = current_items[i]
		var btn := create_item_row(i, item)
		item_container.add_child(btn)
		
	if selected_item_index >= current_items.size():
		selected_item_index = 0
		
	update_selection()

func update_tabs() -> void:
	var tab_names: Array = ["WEAPONS 🔫", "RELICS 🛡️", "PERKS ⚡"]
	var tabs := tab_container.get_children()
	for i in range(tabs.size()):
		var tab_btn: Button = tabs[i] as Button
		tab_btn.focus_mode = Control.FOCUS_NONE
		if i == current_tab:
			tab_btn.modulate = Color(0.2, 0.95, 1.0, 1.0)
			tab_btn.text = "[ " + tab_names[i] + " ]"
		else:
			tab_btn.modulate = Color(0.6, 0.6, 0.7, 0.7)
			tab_btn.text = tab_names[i]

func create_item_row(index: int, item: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(380, 44)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	
	var is_unlocked: bool = build_manager.unlocked_items.has(item.get("id", ""))
	var is_equipped: bool = false
	if current_tab == 0:
		is_equipped = (build_manager.equipped_weapon == item.get("id", ""))
	elif current_tab == 1:
		is_equipped = (build_manager.equipped_accessory == item.get("id", ""))
		
	var status_text: String = ""
	if current_tab == 2:
		var lvl: int = build_manager.perk_levels.get(item.get("id", ""), 0)
		status_text = "Lv.%d / %d" % [lvl, item.get("max_rank", 5)]
	elif is_equipped:
		status_text = "[ EQUIPPED ]"
	elif is_unlocked:
		status_text = "OWNED"
	else:
		status_text = "%d 💎" % item.get("cost", 0)
		
	btn.text = "%s  %s    (%s)" % [item.get("icon", "⭐"), item.get("name", ""), status_text]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	btn.pressed.connect(func():
		selected_item_index = index
		update_selection()
		_on_action_pressed()
	)
	return btn

func update_selection() -> void:
	var rows := item_container.get_children()
	for i in range(rows.size()):
		var row: Button = rows[i] as Button
		if i == selected_item_index:
			row.modulate = Color(1.3, 1.3, 1.3, 1.0)
		else:
			row.modulate = Color(0.7, 0.7, 0.8, 0.8)
			
	back_button.modulate = Color(0.8, 0.85, 0.95, 0.9)
	back_button.text = "◀ [ BACK (B / TAP) ]"
			
	if selected_item_index < current_items.size():
		var item: Dictionary = current_items[selected_item_index]
		detail_icon.text = item.get("icon", "⭐")
		detail_name.text = item.get("name", "")
		detail_desc.text = item.get("desc", "")
		
		var is_unlocked: bool = build_manager.unlocked_items.has(item.get("id", ""))
		var is_equipped: bool = false
		if current_tab == 0:
			is_equipped = (build_manager.equipped_weapon == item.get("id", ""))
		elif current_tab == 1:
			is_equipped = (build_manager.equipped_accessory == item.get("id", ""))
			
		if current_tab == 2:
			var lvl: int = build_manager.perk_levels.get(item.get("id", ""), 0)
			if lvl >= item.get("max_rank", 5):
				action_button.text = "MAX LEVEL"
				action_button.disabled = true
			else:
				var cost: int = build_manager.get_perk_cost(item.get("id", ""))
				action_button.text = "UPGRADE (%d 💎)" % cost
				action_button.disabled = (build_manager.coins < cost)
		elif is_equipped:
			action_button.text = "EQUIPPED"
			action_button.disabled = true
		elif is_unlocked:
			action_button.text = "EQUIP"
			action_button.disabled = false
		else:
			var cost: int = item.get("cost", 0)
			action_button.text = "UNLOCK (%d 💎)" % cost
			action_button.disabled = (build_manager.coins < cost)

func _on_action_pressed() -> void:
	if selected_item_index >= current_items.size() or not build_manager:
		return
	var item: Dictionary = current_items[selected_item_index]
	var item_id: String = item.get("id", "")
	
	if current_tab == 2:
		if build_manager.upgrade_perk(item_id):
			refresh_ui()
	else:
		var is_unlocked: bool = build_manager.unlocked_items.has(item_id)
		if is_unlocked:
			var type_str := "weapon" if current_tab == 0 else "accessory"
			build_manager.equip_item(item_id, type_str)
			refresh_ui()
		else:
			var cost: int = item.get("cost", 0)
			if build_manager.unlock_item(item_id, cost):
				var type_str := "weapon" if current_tab == 0 else "accessory"
				build_manager.equip_item(item_id, type_str)
				refresh_ui()
