tool
extends Node2D

export (Color) var COR = Color(1.0, 1.0, 1.0, 1.0)
export (float) var ALTURA = 0
export (float) var LARGURA = 0
export (float) var RESOLUCAO = 15
export (float) var TENSAO = 0.025
export (float) var AMORTECIMENTO = 0.001
export (int) var PASSES = 1
export (float) var DISPERSAO = 0.01
export (bool) var simulate_water = true 
export (float) var water_distorcion:int = 3
export (bool) var emit_particles: bool = true
export (Texture) var water_texture = preload("res://addons/polygon2dwater/water_texture.png")

var water_particles = preload("res://addons/polygon2dwater/particles.tscn")
var water_shader = preload("res://addons/polygon2dwater/water.shader")
var droplet_texture = preload("res://addons/polygon2dwater/droplets.png")
var timer_queuefree_droplets = Timer.new()

var refreshing = false
var initialized = false
var vecs_positions = []
var vecs_velocity = []
var left_vec = []
var right_vec = []

var randomizator = RandomNumberGenerator.new()
var water
var area
var _col

var timer_box = Timer.new()

func _ready():
	randomizator.randomize()
	if Engine.is_editor_hint() == false:
		create_water_block()
	set_process(true)
	#self.z_index = 4096
	
	#timer_box.wait_time = 1
	#timer_box.autostart = true
	#timer_box.connect("timeout", self, "_on_timer_box_timeout")
	#add_child(timer_box)
	
	timer_queuefree_droplets.wait_time = 1
	timer_queuefree_droplets.autostart = true
	timer_queuefree_droplets.connect("timeout", self, "_on_timer_droplets_timeout")
	add_child(timer_queuefree_droplets)

func _on_timer_box_timeout():
	if Engine.is_editor_hint() == false:
		create_water_block()
		
func _on_timer_droplets_timeout():
	for d in get_tree().get_nodes_in_group("water_droplets"):
		yield(get_tree().create_timer(.5), "timeout")
		if weakref(d).get_ref():
			d.queue_free()
		break

func _process(delta):
	if refreshing: return
	if Engine.is_editor_hint() == false:
		_dynamic_physics()
	else:
		update()
	
func _dynamic_physics():
	if !weakref(water).get_ref(): return
	
	for i in vecs_positions.size() - 2:
		var target_y = -ALTURA - vecs_positions[i].y
		vecs_velocity[i] += (TENSAO * target_y) - (AMORTECIMENTO * vecs_velocity[i])
		vecs_positions[i].y += vecs_velocity[i]
		
		water.polygon[i] = vecs_positions[i]
	
	#dispersão
	for i in vecs_positions.size() - 2:
		left_vec[i] = 0
		right_vec[i] = 0
	
	for j in PASSES:
		for i in vecs_positions.size() - 2:
			if i > 0:
				left_vec[i] = DISPERSAO * (vecs_positions[i].y - vecs_positions[i - 1].y)
				vecs_velocity[i - 1] += left_vec[i]
			if i < vecs_positions.size() - 3:
				right_vec[i] = DISPERSAO * (vecs_positions[i].y - vecs_positions[i + 1].y)
				vecs_velocity[i + 1] += right_vec[i]
		for i in vecs_positions.size() - 2:
			if i > 0:
				vecs_positions[i - 1].y += left_vec[i]
			if i < vecs_positions.size() - 3:
				vecs_positions[i + 1].y += right_vec[i]
		
func create_water_block():
	refreshing = true
	var water_block
	var area
	var col
	
	if !weakref(water).get_ref() and !initialized:
		water_block = Polygon2D.new()
		area = Area2D.new()
		col = CollisionPolygon2D.new()
	else:
		water_block = $"./water_base"
		area = $"./water_base/water_area"
		col = $"./water_base/water_area/water_col"
	
	var distance_beetween_vecs = LARGURA / RESOLUCAO
	var vecs = PoolVector2Array([])
	
	vecs.insert(0, Vector2(0, -ALTURA))
	for i in RESOLUCAO:
		vecs.insert(i+1, Vector2(distance_beetween_vecs * (i + 1),-ALTURA))
	
	vecs.insert(RESOLUCAO + 1, Vector2(LARGURA, 0))
	vecs.insert(RESOLUCAO + 2, Vector2(0, 0))
	
	if !initialized:
		water_block.name = "water_base"
	
	water_block.polygon = []
	water_block.polygon = vecs
	water_block.color = COR
	
	col.polygon = []
	col.polygon = water_block.polygon
	
	if !initialized:
		if simulate_water:
			var new_material = ShaderMaterial.new()
			new_material.shader = water_shader
			new_material.set_shader_param("blue_tint", COR)
			new_material.set_shader_param("sprite_scale", Vector2(1,1))
			new_material.set_shader_param("scale_x", water_distorcion)
			water_block.material = new_material

		if water_texture != null:
			water_block.texture = water_texture
	
	if !initialized:
		water_block.antialiased = true
		area.name = "water_area"
		area.add_to_group("water_area")
		
		col.name = "water_col"
		
		self.add_child(water_block)
		water_block.add_child(area)
		area.add_child(col)
	
		area.connect("body_entered", self, "body_emerged")
		area.connect("body_exited", self, "body_not_emerged")
	
	for i in water_block.polygon.size():
		vecs_positions.insert(i, water_block.polygon[i])
		vecs_velocity.insert(i, 0)
		left_vec.insert(i, 0)
		right_vec.insert(i, 0)
	
	water = $"./water_base"
	_col = $"./water_base/water_area/water_col"
	initialized = true
	refreshing = false

func body_emerged(body):
	if (body is RigidBody2D) or (body is KinematicBody2D) or (body is StaticBody2D):
		
		var force_applied = 11
		if body is RigidBody2D:
			force_applied = body.linear_velocity.y * 0.01
		
		var body_pos = body.position.x - self.position.x
		var closest_vec_pos_x = 9999999
		var closest_vec = 0
		for i in vecs_positions.size() - 2:
			var distance_diference = vecs_positions[i].x - body_pos 
			if distance_diference < 0:
				distance_diference *= -1
			if distance_diference < closest_vec_pos_x:
				closest_vec = i
				closest_vec_pos_x = distance_diference
		vecs_velocity[closest_vec] -= force_applied
		
		if body.has_method("_on_water_entered"):
			body._on_water_entered(water, ALTURA, TENSAO, AMORTECIMENTO)
		
		if emit_particles:
			var droplets = water_particles.instance()
			droplets.name = "particles"
			droplets.amount = (randomizator.randi() % 30) + 5
			droplets.lifetime = 3
			droplets.speed_scale = 3
			droplets.explosiveness = 1
			droplets.one_shot = true
			droplets.texture = droplet_texture
			droplets.color = COR
			droplets.add_to_group("water_droplets")
			
			var gradientRamp = Gradient.new()
			var corEnd = COR
			corEnd.a = 0
			gradientRamp.add_point(0, COR)
			gradientRamp.add_point(1, corEnd)
			
			droplets.color_ramp = gradientRamp
			droplets.z_index = body.z_index - 1
			droplets.global_position = Vector2(body.global_position.x, body.global_position.y)
			$"..".add_child(droplets)
			droplets.emitting = true

func body_not_emerged(body):
	if body is RigidBody2D or body is KinematicBody2D or body is StaticBody2D:
		if body.has_method("_on_water_exited"):
			body._on_water_exited()

func _draw():
	var vecs = PoolVector2Array([])
	var color = PoolColorArray([])
	if Engine.is_editor_hint():
		vecs = PoolVector2Array([Vector2(0, -ALTURA), Vector2(LARGURA, -ALTURA), Vector2(LARGURA, 0), Vector2(0, 0)])
		color = PoolColorArray([COR, COR, COR, COR])
	draw_polygon(vecs, color)
