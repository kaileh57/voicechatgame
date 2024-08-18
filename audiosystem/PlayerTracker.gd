extends MeshInstance3D

#Support for 8 people total
@export var p1: RayCast3D
@export var p2: RayCast3D
@export var p3: RayCast3D
@export var p4: RayCast3D
@export var p5: RayCast3D
@export var p6: RayCast3D
@export var p7: RayCast3D


var p1targ: Node3D = null
var p2targ: Node3D = null
var p3targ: Node3D = null
var p4targ: Node3D = null
var p5targ: Node3D = null
var p6targ: Node3D = null
var p7targ: Node3D = null


var p1dist: float = 0.0
var p2dist: float = 0.0
var p3dist: float = 0.0
var p4dist: float = 0.0
var p5dist: float = 0.0
var p6dist: float = 0.0
var p7dist: float = 0.0

#sets up relevant info for one player
func add_player(node, id):
	if p1targ == null:
		p1targ = node
		p1.name = str(id)
	elif p2targ == null:
		p2targ = node
		p2.name = str(id)
	elif p3targ == null:
		p3targ = node
		p3.name = str(id)
	elif p4targ == null:
		p4targ = node
		p4.name = str(id)
	elif p5targ == null:
		p5targ = node
		p5.name = str(id)
	elif p6targ == null:
		p6targ = node
		p6.name = str(id)
	elif p7targ == null:
		p7targ = node
		p7.name = str(id)
	


#Compute the distance to each player, and draw a raycast to them
func track_players():
	if p1targ != null:
		p1dist = global_position.distance_to(p1targ.global_position)
		if p1dist <= 100:
			p1.target_position = p1targ.global_position
	if p2targ != null:
		p2dist = global_position.distance_to(p2targ.global_position)
		if p2dist <= 100:
			p2.target_position = p2targ.global_position
	if p3targ != null:
		p3dist = global_position.distance_to(p3targ.global_position)
		if p3dist <= 100:
			p3.target_position = p3targ.global_position
	if p4targ != null:
		p4dist = global_position.distance_to(p4targ.global_position)
		if p4dist <= 100:
			p4.target_position = p4targ.global_position
	if p5targ != null:
		p5dist = global_position.distance_to(p5targ.global_position)
		if p5dist <= 100:
			p5.target_position = p5targ.global_position
	if p6targ != null:
		p6dist = global_position.distance_to(p6targ.global_position)
		if p6dist <= 100:
			p6.target_position = p6targ.global_position
	if p7targ != null:
		p7dist = global_position.distance_to(p7targ.global_position)
		if p3dist <= 100:
			p7.target_position = p7targ.global_position	

#occurs at 60fps
func _physics_process(delta):
	track_players()
	fake()

#this function should never be called in prod
func fake():
	if p1.is_colliding(): print("p1 colliding")
