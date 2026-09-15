extends Node2D

@export var horizon_y: float = 430.0
@export var scroll_speed: float = 120.0

var distance_ref: float = 0.0
var target_zone: int = 1
var current_zone_blend: float = 1.0

# パララックスオフセット
var offset_stars: float = 0.0
var offset_far_buildings: float = 0.0
var offset_mid_buildings: float = 0.0
var offset_grid: float = 0.0

# 星データ
var stars: Array[Dictionary] = []
# 遠景ビルデータ
var far_buildings: Array[Dictionary] = []
# 中景ビルデータ
var mid_buildings: Array[Dictionary] = []
# ホバーカーデータ
var hover_cars: Array[Dictionary] = []
# 浮遊パーティクル
var dust_particles: Array[Dictionary] = []

func _ready() -> void:
	init_stars()
	init_buildings()
	init_hover_cars()
	init_dust()

func init_stars() -> void:
	stars.clear()
	for i in range(45):
		stars.append({
			"pos": Vector2(randf_range(0, 720), randf_range(10, horizon_y - 80)),
			"size": randf_range(1.0, 2.4),
			"twinkle_speed": randf_range(1.5, 4.0),
			"twinkle_phase": randf_range(0, TAU),
			"color": Color(randf_range(0.7, 1.0), randf_range(0.8, 1.0), 1.0)
		})

func init_buildings() -> void:
	# 遠景ビル (幅 40~80, 高さ 140~260)
	far_buildings.clear()
	var x: float = 0.0
	while x < 1440.0:
		var w := randf_range(45.0, 85.0)
		var h := randf_range(160.0, 290.0)
		var win_rows := int(h / 24.0)
		var win_cols := int(w / 16.0)
		var windows: Array[bool] = []
		for r in range(win_rows * win_cols):
			windows.append(randf() > 0.45)
			
		far_buildings.append({
			"x": x,
			"w": w,
			"h": h,
			"has_antenna": randf() > 0.4,
			"antenna_h": randf_range(20.0, 45.0),
			"windows": windows,
			"win_rows": win_rows,
			"win_cols": win_cols
		})
		x += w + randf_range(-10.0, 15.0)
		
	# 中景ビル (幅 50~110, 高さ 90~180)
	mid_buildings.clear()
	x = 0.0
	while x < 1440.0:
		var w := randf_range(60.0, 110.0)
		var h := randf_range(100.0, 200.0)
		var has_sign := randf() > 0.6
		var sign_type := randi() % 4
		mid_buildings.append({
			"x": x,
			"w": w,
			"h": h,
			"has_sign": has_sign,
			"sign_type": sign_type,
			"sign_color": Color(randf_range(0.2, 1.0), randf_range(0.4, 1.0), randf_range(0.8, 1.0))
		})
		x += w + randf_range(5.0, 25.0)

func init_hover_cars() -> void:
	hover_cars.clear()
	for i in range(6):
		hover_cars.append({
			"pos": Vector2(randf_range(0, 720), randf_range(120, horizon_y - 40)),
			"speed": randf_range(140.0, 320.0) * (1.0 if randf() > 0.4 else -1.0),
			"trail_len": randf_range(25.0, 55.0),
			"color": Color(0.2, 0.95, 1.0) if randf() > 0.5 else Color(1.0, 0.25, 0.4)
		})

func init_dust() -> void:
	dust_particles.clear()
	for i in range(25):
		dust_particles.append({
			"pos": Vector2(randf_range(0, 720), randf_range(0, 720)),
			"vel": Vector2(randf_range(-40.0, -100.0), randf_range(-15.0, 15.0)),
			"size": randf_range(1.5, 3.2),
			"alpha": randf_range(0.2, 0.6)
		})

func update_zone_by_distance(dist: float) -> void:
	distance_ref = dist
	if dist < 1000.0:
		target_zone = 1
	elif dist < 2000.0:
		target_zone = 2
	else:
		target_zone = 3

func _process(delta: float) -> void:
	current_zone_blend = lerp(current_zone_blend, float(target_zone), 3.0 * delta)
	
	offset_stars = fmod(offset_stars + scroll_speed * 0.05 * delta, 720.0)
	offset_far_buildings = fmod(offset_far_buildings + scroll_speed * 0.2 * delta, 1440.0)
	offset_mid_buildings = fmod(offset_mid_buildings + scroll_speed * 0.5 * delta, 1440.0)
	offset_grid = fmod(offset_grid + scroll_speed * delta, 60.0)
	
	# ホバーカー更新
	for car in hover_cars:
		car.pos.x += car.speed * delta
		if car.speed > 0 and car.pos.x > 780.0:
			car.pos.x = -60.0
			car.pos.y = randf_range(120, horizon_y - 40)
		elif car.speed < 0 and car.pos.x < -80.0:
			car.pos.x = 780.0
			car.pos.y = randf_range(120, horizon_y - 40)
			
	# ダスト更新
	for d in dust_particles:
		d.pos += d.vel * delta
		if d.pos.x < -10.0:
			d.pos.x = 730.0
			d.pos.y = randf_range(0, 720)
			
	queue_redraw()

func get_zone_colors() -> Dictionary:
	# ゾーンに応じたカラーパレット（シアン/マゼンタ -> アシッドグリーン/オレンジ -> パープル/ブルー）
	var z := current_zone_blend
	var sky_top: Color
	var sky_bot: Color
	var sun_color: Color
	var ring_color: Color
	var far_bldg_color: Color
	var mid_bldg_color: Color
	var grid_col: Color
	
	if z <= 2.0:
		var t := clampf(z - 1.0, 0.0, 1.0)
		sky_top = Color(0.03, 0.04, 0.10).lerp(Color(0.08, 0.03, 0.05), t)
		sky_bot = Color(0.12, 0.06, 0.22).lerp(Color(0.20, 0.08, 0.04), t)
		sun_color = Color(0.95, 0.15, 0.55).lerp(Color(0.95, 0.55, 0.10), t)
		ring_color = Color(0.15, 0.90, 1.0).lerp(Color(0.30, 0.95, 0.30), t)
		far_bldg_color = Color(0.07, 0.09, 0.18).lerp(Color(0.12, 0.08, 0.06), t)
		mid_bldg_color = Color(0.04, 0.06, 0.12).lerp(Color(0.07, 0.05, 0.04), t)
		grid_col = Color(0.15, 0.70, 1.0, 0.35).lerp(Color(0.35, 0.90, 0.20, 0.35), t)
	else:
		var t := clampf(z - 2.0, 0.0, 1.0)
		sky_top = Color(0.08, 0.03, 0.05).lerp(Color(0.04, 0.02, 0.12), t)
		sky_bot = Color(0.20, 0.08, 0.04).lerp(Color(0.15, 0.05, 0.30), t)
		sun_color = Color(0.95, 0.55, 0.10).lerp(Color(0.70, 0.20, 0.95), t)
		ring_color = Color(0.30, 0.95, 0.30).lerp(Color(0.20, 0.80, 1.0), t)
		far_bldg_color = Color(0.12, 0.08, 0.06).lerp(Color(0.09, 0.06, 0.18), t)
		mid_bldg_color = Color(0.07, 0.05, 0.04).lerp(Color(0.05, 0.04, 0.11), t)
		grid_col = Color(0.35, 0.90, 0.20, 0.35).lerp(Color(0.75, 0.25, 0.95, 0.35), t)
		
	return {
		"sky_top": sky_top, "sky_bot": sky_bot,
		"sun": sun_color, "ring": ring_color,
		"far_bldg": far_bldg_color, "mid_bldg": mid_bldg_color,
		"grid": grid_col
	}

func _draw() -> void:
	var sw: float = 720.0
	var sh: float = 720.0
	var colors := get_zone_colors()
	var time: float = Time.get_ticks_msec() * 0.001
	
	# 1. スカイグラデーション (帯描画)
	var sky_bands := 14
	var band_h := horizon_y / float(sky_bands)
	for i in range(sky_bands):
		var t0 := float(i) / float(sky_bands)
		var col := (colors.sky_top as Color).lerp(colors.sky_bot as Color, t0)
		draw_rect(Rect2(0, i * band_h, sw, band_h + 1.0), col, true)
		
	# 地面側アンダーレイ
	draw_rect(Rect2(0, horizon_y, sw, sh - horizon_y), Color(0.01, 0.02, 0.05), true)
	
	# 2. 星空
	for s in stars:
		var sx := fmod(s.pos.x - offset_stars + sw, sw)
		var sy: float = s.pos.y
		var alpha: float = 0.4 + 0.5 * sin(time * s.twinkle_speed + s.twinkle_phase)
		var scol: Color = s.color
		scol.a = alpha
		draw_circle(Vector2(sx, sy), s.size, scol)
		
	# 3. 巨大サイバー惑星/月 (デジタルワイヤーフレーム & グロー)
	var sun_pos := Vector2(sw * 0.65, horizon_y - 90.0)
	var sun_radius: float = 85.0
	var sun_c: Color = colors.sun
	
	# 外側大気グロー
	for r in range(4):
		var glow_c := sun_c
		glow_c.a = 0.06 * float(4 - r)
		draw_circle(sun_pos, sun_radius + float(r * 18), glow_c)
		
	# 惑星本体
	draw_circle(sun_pos, sun_radius, Color(sun_c.r * 0.4, sun_c.g * 0.4, sun_c.b * 0.4, 0.85))
	draw_circle(sun_pos, sun_radius, Color(sun_c.r, sun_c.g, sun_c.b, 0.95), false, 2.0)
	
	# 惑星のサイバーグリッドライン (水平縞模様)
	for py in range(-int(sun_radius), int(sun_radius), 14):
		var chord: float = sqrt(max(0.0, sun_radius * sun_radius - py * py))
		draw_line(Vector2(sun_pos.x - chord, sun_pos.y + py), Vector2(sun_pos.x + chord, sun_pos.y + py), Color(sun_c.r, sun_c.g, sun_c.b, 0.4), 1.2)
		
	# 惑星のリング (楕円軌道)
	var ring_c: Color = colors.ring
	ring_c.a = 0.6
	var ring_points: PackedVector2Array = []
	for a in range(32):
		var angle := float(a) / 32.0 * TAU
		var rx := cos(angle) * (sun_radius * 1.7)
		var ry := sin(angle) * (sun_radius * 0.35)
		# 斜め傾き
		var rot_x := rx * 0.94 - ry * 0.34
		var rot_y := rx * 0.34 + ry * 0.94
		ring_points.append(sun_pos + Vector2(rot_x, rot_y))
	if ring_points.size() > 2:
		for p_idx in range(ring_points.size()):
			var next_p := ring_points[(p_idx + 1) % ring_points.size()]
			draw_line(ring_points[p_idx], next_p, ring_c, 2.0)
			
	# 4. 遠景メガコーポビル群 (パララックス 0.2x)
	var far_col: Color = colors.far_bldg
	var win_col := Color(1.0, 0.95, 0.6, 0.7)
	for b in far_buildings:
		var bw: float = float(b["w"])
		var bh: float = float(b["h"])
		var bx: float = fmod(float(b["x"]) - offset_far_buildings + 2880.0, 1440.0) - 100.0
		if bx > sw + 100.0 or bx + bw < -100.0:
			continue
		var by: float = horizon_y - bh
		var brect := Rect2(bx, by, bw, bh)
		draw_rect(brect, far_col, true)
		draw_rect(brect, Color(far_col.r * 1.5, far_col.g * 1.5, far_col.b * 1.5, 0.6), false, 1.0)
		
		# アンテナと赤い航空警告灯
		if b.get("has_antenna", false):
			var ant_x: float = bx + bw * 0.5
			var ant_y: float = by - float(b.get("antenna_h", 20.0))
			draw_line(Vector2(ant_x, by), Vector2(ant_x, ant_y), Color(0.4, 0.5, 0.6, 0.8), 1.5)
			var beacon_blink := int(time * 3.0 + float(b["x"])) % 2 == 0
			var beacon_col := Color(1.0, 0.1, 0.1, 1.0 if beacon_blink else 0.2)
			draw_circle(Vector2(ant_x, ant_y), 2.5, beacon_col)
			
		# 窓の明かり
		var rows: int = int(b["win_rows"])
		var cols: int = int(b["win_cols"])
		var pad_x: float = bw / float(cols + 1)
		var pad_y: float = bh / float(rows + 1)
		var w_idx: int = 0
		var win_arr: Array = b["windows"]
		for r in range(rows):
			for c in range(cols):
				if w_idx < win_arr.size() and win_arr[w_idx]:
					var wx := bx + pad_x * float(c + 1)
					var wy := by + pad_y * float(r + 1)
					draw_rect(Rect2(wx - 2, wy - 3, 4, 6), win_col, true)
				w_idx += 1
				
	# 5. 中景ビル群 & サイバーサイン (パララックス 0.5x)
	var mid_col: Color = colors.mid_bldg
	for b in mid_buildings:
		var bw: float = float(b["w"])
		var bh: float = float(b["h"])
		var bx: float = fmod(float(b["x"]) - offset_mid_buildings + 2880.0, 1440.0) - 120.0
		if bx > sw + 120.0 or bx + bw < -120.0:
			continue
		var by: float = horizon_y - bh
		var brect := Rect2(bx, by, bw, bh)
		draw_rect(brect, mid_col, true)
		draw_line(Vector2(bx, by), Vector2(bx + bw, by), Color(0.3, 0.8, 1.0, 0.5), 2.0)
		
		# サイバーネオン看板
		if b.get("has_sign", false):
			var sign_rect := Rect2(bx + 8, by + 12, bw - 16, 24)
			var scol: Color = b["sign_color"]
			var blink := (int(time * 4.0 + float(b["x"])) % 6 != 0)
			scol.a = 0.85 if blink else 0.2
			draw_rect(sign_rect, Color(0.02, 0.02, 0.05, 0.9), true)
			draw_rect(sign_rect, scol, false, 1.8)
			
			# 看板の記号/文字風ライン
			draw_line(Vector2(sign_rect.position.x + 4, sign_rect.position.y + 12), Vector2(sign_rect.position.x + sign_rect.size.x - 4, sign_rect.position.y + 12), scol, 2.0)
			
	# 6. 空中ハイウェイ & ホバーカー (光跡)
	for car in hover_cars:
		var start_p: Vector2 = car.pos
		var end_p := start_p - Vector2(car.trail_len * (1.0 if car.speed > 0 else -1.0), 0)
		var car_col: Color = car.color
		draw_line(start_p, end_p, car_col, 2.5)
		draw_circle(start_p, 2.5, Color(1.0, 1.0, 1.0, 0.9))
		
	# 7. 近景パースペクティブグリッド床
	var gcol: Color = colors.grid
	for y in range(int(horizon_y), int(sh), 20):
		var alpha: float = (float(y - horizon_y) / (sh - horizon_y)) * 0.7
		var line_col := gcol
		line_col.a = alpha
		draw_line(Vector2(0, y), Vector2(sw, y), line_col, 1.2)
		
	var gx := -offset_grid
	while gx < sw + 60.0:
		var col := gcol
		col.a = 0.45
		draw_line(Vector2(gx, horizon_y), Vector2((gx - sw * 0.5) * 2.2 + sw * 0.5, sh), col, 1.2)
		gx += 60.0
		
	# 8. サイバーダスト / 浮遊微粒子
	for d in dust_particles:
		var pcol := Color(0.2, 0.9, 1.0, d.alpha)
		draw_rect(Rect2(d.pos, Vector2(d.size, d.size)), pcol, true)
