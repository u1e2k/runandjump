extends RefCounted

# スキル定義データベース

const SKILLS = {
	"triple_jump": {
		"id": "triple_jump",
		"name": "TRIPLE JUMP",
		"desc": "空中でさらに+1回ジャンプ可能になる",
		"icon": "🦘",
		"max_rank": 2
	},
	"rapid_fire": {
		"id": "rapid_fire",
		"name": "RAPID BLASTER",
		"desc": "自動ショットの連射速度+30%",
		"icon": "⚡",
		"max_rank": 3
	},
	"multishot": {
		"id": "multishot",
		"name": "TWIN LASER",
		"desc": "自動ショットの弾数が+1",
		"icon": "🎯",
		"max_rank": 2
	},
	"stomp_shock": {
		"id": "stomp_shock",
		"name": "STOMP SHOCKWAVE",
		"desc": "踏みつけ時に周囲の敵を吹き飛ばす",
		"icon": "💥",
		"max_rank": 2
	},
	"magnet": {
		"id": "magnet",
		"name": "MAGNET AURA",
		"desc": "EXPジェムの吸引範囲が2倍",
		"icon": "🧲",
		"max_rank": 3
	},
	"spike_boots": {
		"id": "spike_boots",
		"name": "SPIKE BOOTS",
		"desc": "トゲダメージ無効＆トゲで大バウンド",
		"icon": "🛡️",
		"max_rank": 1
	},
	"heal_max_hp": {
		"id": "heal_max_hp",
		"name": "MAX HP & HEAL",
		"desc": "最大HP+1 ＆ 体力を全回復",
		"icon": "❤️",
		"max_rank": 5
	}
}

static func get_random_skills(count: int, player_skills: Dictionary) -> Array:
	var pool: Array = []
	for key in SKILLS.keys():
		var skill_info: Dictionary = SKILLS[key]
		var current_rank: int = player_skills.get(key, 0)
		if current_rank < skill_info["max_rank"]:
			pool.append(skill_info)
			
	pool.shuffle()
	var result: Array = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	return result
