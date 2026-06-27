extends Node2D

var mosquito_tex = preload("res://Game Jam Asstes/mosquito.png")
var dead_tex = preload("res://Game Jam Asstes/deadmosquito.png")
var dead_golden_tex = preload("res://Game Jam Asstes/deadmosquito.png") # yehi rahne do

var buzz_sfx = preload("res://Game Jam Asstes/buzz.mp3")
var trumpet_sfx = preload("res://Game Jam Asstes/mosquitotrumpet.mp3")
var singer_sfx = preload("res://Game Jam Asstes/Mosquitosinger.mp3")
var catlaugh_sfx = preload("res://Game Jam Asstes/catlaugh.mp3")
var slap_sfx = preload("res://Game Jam Asstes/slap.mp3")

# RANDOM ke liye array
var mosquito_sounds = []

var score = 0; var active = []; var game_over = false
var timer = 0.0; var spawn_time = 1.4
var hit_radius = 55; var max_mosquitoes = 4

func _ready():
	randomize()
	mosquito_sounds = [buzz_sfx, trumpet_sfx, singer_sfx] # yahan se random pick hoga

func play_one_shot(sound):
	var p = AudioStreamPlayer.new()
	p.stream = sound; p.volume_db = -1
	add_child(p); p.play(); p.finished.connect(p.queue_free)

func update_sounds():
	for i in range(active.size()):
		var m = active[i]
		var a = m.get_meta("audio")
		if i == 0:
			a.volume_db = -3
			if not a.playing: a.play()
		else:
			a.volume_db = -80

func _process(delta):
	if game_over: return
	timer += delta
	if timer >= spawn_time:
		timer = 0
		if active.size() <= max_mosquitoes:
			spawn_mosquito()
		spawn_time = max(0.85, spawn_time - 0.008)
	$UI/CountLabel.text = "Near You: %d/%d" % [active.size(), max_mosquitoes]
	if active.size() > max_mosquitoes: end_game()

func get_inside_pos(): return Vector2(randi_range(150,1130), randi_range(150,570))
func get_outside_pos():
	var side = randi_range(0,3)
	if side==0: return Vector2(-80, randi_range(120,600))
	if side==1: return Vector2(1360, randi_range(120,600))
	if side==2: return Vector2(randi_range(120,1160), -80)
	return Vector2(randi_range(120,1160),800)

func spawn_mosquito():
	var a = Node2D.new(); a.position = get_outside_pos()
	var s = Sprite2D.new(); s.texture = mosquito_tex; s.scale = Vector2(0.24,0.24)
	var r = randf(); var mtype = "normal"; var speed = randf_range(3.5,4.5)
	if r < 0.12:
		mtype = "golden"; s.modulate = Color(1,0.9,0.2); s.scale = Vector2(0.28,0.28)
	elif r < 0.32:
		mtype = "fast"; s.modulate = Color(1,0.2,0.2); speed = randf_range(2.5,3.0) # sahi laal
	else:
		s.modulate = Color(1,1,1)
	a.add_child(s)
	a.set_meta("type", mtype)
	a.set_meta("sprite", s)
	
	# --- RANDOM SFX ---
	var audio = AudioStreamPlayer.new()
	audio.stream = mosquito_sounds.pick_random() # har baar random
	a.add_child(audio); audio.play()
	a.set_meta("audio", audio)
	
	add_child(a); active.append(a)
	update_sounds()
	
	var entry = create_tween()
	entry.tween_property(a, "position", get_inside_pos(), 0.9)
	entry.tween_callback(func():
		var move = create_tween(); move.set_loops()
		move.tween_property(a, "position", a.position + Vector2(randf_range(-25,25), randf_range(-18,18)), speed)
		a.set_meta("move", move)
	)

func _input(event):
	if game_over: return
	var tapped = false; var pos = Vector2.ZERO
	if event is InputEventMouseButton and event.pressed: tapped = true; pos = event.position
	if event is InputEventScreenTouch and event.pressed: tapped = true; pos = event.position
	if tapped:
		for m in active.duplicate():
			if pos.distance_to(m.position) < hit_radius:
				play_one_shot(slap_sfx)
				m.get_meta("audio").stop()
				if m.has_meta("move"): m.get_meta("move").kill()
				active.erase(m); update_sounds()
				score += 1
				$UI/ScoreLabel.text = "Killed: %d" % score
				var spr = m.get_meta("sprite")
				spr.texture = dead_golden_tex if m.get_meta("type")=="golden" else dead_tex
				var fall = create_tween()
				fall.tween_property(m, "position:y", m.position.y+700, 0.75)
				fall.tween_callback(m.queue_free)
				break

func end_game():
	game_over = true
	$UI/GameOver.text = "Haargya Choomu!!"
	$UI/GameOver.visible = true
	play_one_shot(catlaugh_sfx)
	set_process(false)
