extends RefCounted

const EquipmentDatabaseScript = preload("res://scripts/EquipmentDatabase.gd")
const SAVE_PATH: String = "user://runandjump_save.json"

var coins: int = 150 # 初回ボーナスコイン
var equipped_weapon: String = "pulse_laser"
var equipped_accessory: String = "none"
var unlocked_items: Array = ["pulse_laser", "none"]
var perk_levels: Dictionary = {
	"max_hp": 0,
	"fire_rate": 0,
	"magnet": 0
}

func _init() -> void:
	load_data()

func save_data() -> void:
	var data: Dictionary = {
		"coins": coins,
		"equipped_weapon": equipped_weapon,
		"equipped_accessory": equipped_accessory,
		"unlocked_items": unlocked_items,
		"perk_levels": perk_levels
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var d: Dictionary = json.data
		coins = int(d.get("coins", coins))
		equipped_weapon = str(d.get("equipped_weapon", "pulse_laser"))
		equipped_accessory = str(d.get("equipped_accessory", "none"))
		if d.has("unlocked_items") and d["unlocked_items"] is Array:
			unlocked_items = d["unlocked_items"]
		if d.has("perk_levels") and d["perk_levels"] is Dictionary:
			perk_levels = d["perk_levels"]

func unlock_item(item_id: String, cost: int) -> bool:
	if coins >= cost and not unlocked_items.has(item_id):
		coins -= cost
		unlocked_items.append(item_id)
		save_data()
		return true
	return false

func equip_item(item_id: String, type: String) -> void:
	if not unlocked_items.has(item_id):
		return
	if type == "weapon":
		equipped_weapon = item_id
	elif type == "accessory":
		equipped_accessory = item_id
	save_data()

func upgrade_perk(perk_id: String) -> bool:
	var current_lvl: int = perk_levels.get(perk_id, 0)
	var perk_info: Dictionary = EquipmentDatabaseScript.PERKS.get(perk_id, {})
	if perk_info.is_empty() or current_lvl >= perk_info.get("max_rank", 5):
		return false
		
	var base_cost: int = perk_info.get("base_cost", 40)
	var mult: float = perk_info.get("cost_multiplier", 1.5)
	var cost: int = int(float(base_cost) * pow(mult, current_lvl))
	
	if coins >= cost:
		coins -= cost
		perk_levels[perk_id] = current_lvl + 1
		save_data()
		return true
	return false

func get_perk_cost(perk_id: String) -> int:
	var current_lvl: int = perk_levels.get(perk_id, 0)
	var perk_info: Dictionary = EquipmentDatabaseScript.PERKS.get(perk_id, {})
	if perk_info.is_empty():
		return 9999
	var base_cost: int = perk_info.get("base_cost", 40)
	var mult: float = perk_info.get("cost_multiplier", 1.5)
	return int(float(base_cost) * pow(mult, current_lvl))
