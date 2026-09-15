extends RefCounted

# 装備品（武器・アクセサリー）データベース

const WEAPONS = {
	"pulse_laser": {
		"id": "pulse_laser",
		"name": "PULSE LASER",
		"type": "weapon",
		"desc": "高速直線ビーム。安定した連射と長射程。",
		"icon": "🔫",
		"cost": 0,
		"unlocked": true,
		"damage": 1,
		"interval": 0.7,
		"bullet_speed": 650.0,
		"bullet_count": 1
	},
	"scatter_shot": {
		"id": "scatter_shot",
		"name": "SCATTER SHOT",
		"type": "weapon",
		"desc": "扇状に3発の拡散弾を発射。近距離で大ダメージ。",
		"icon": "💥",
		"cost": 80,
		"unlocked": false,
		"damage": 1,
		"interval": 0.9,
		"bullet_speed": 550.0,
		"bullet_count": 3
	},
	"plasma_cannon": {
		"id": "plasma_cannon",
		"name": "PLASMA CANNON",
		"type": "weapon",
		"desc": "巨大な高密度プラズマ弾。敵を一撃で貫通粉砕。",
		"icon": "🔮",
		"cost": 150,
		"unlocked": false,
		"damage": 3,
		"interval": 1.2,
		"bullet_speed": 450.0,
		"bullet_count": 1
	}
}

const ACCESSORIES = {
	"none": {
		"id": "none",
		"name": "EMPTY SLOT",
		"type": "accessory",
		"desc": "アクセサリー未装備",
		"icon": "⚪",
		"cost": 0,
		"unlocked": true
	},
	"feather_charm": {
		"id": "feather_charm",
		"name": "FEATHER CHARM",
		"type": "accessory",
		"desc": "重力が15%軽減され、ふわっと長滞空ジャンプが可能。",
		"icon": "🪶",
		"cost": 60,
		"unlocked": false
	},
	"spike_guard": {
		"id": "spike_guard",
		"name": "SPIKE GUARD",
		"type": "accessory",
		"desc": "最初からトゲのダメージを無効化し大バウンド可能。",
		"icon": "🛡️",
		"cost": 100,
		"unlocked": false
	},
	"vampire_ring": {
		"id": "vampire_ring",
		"name": "VAMPIRE RING",
		"type": "accessory",
		"desc": "敵を5体倒すごとにHPが5回復する。",
		"icon": "🩸",
		"cost": 120,
		"unlocked": false
	}
}

const PERKS = {
	"max_hp": {
		"id": "max_hp",
		"name": "HULL INTEGRITY",
		"desc": "初期最大HP +15",
		"icon": "💖",
		"base_cost": 40,
		"cost_multiplier": 1.5,
		"max_rank": 5
	},
	"fire_rate": {
		"id": "fire_rate",
		"name": "RAPID CHARGER",
		"desc": "初期攻撃速度 +10%",
		"icon": "⚡",
		"base_cost": 50,
		"cost_multiplier": 1.5,
		"max_rank": 5
	},
	"magnet": {
		"id": "magnet",
		"name": "GRAVITY CORE",
		"desc": "初期EXP吸引範囲 +25%",
		"icon": "🧲",
		"base_cost": 35,
		"cost_multiplier": 1.4,
		"max_rank": 4
	}
}
