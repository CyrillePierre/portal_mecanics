extends Spatial

const THICKNESS = .05
const LENGTH_MAX = 200
const NB_RAYS_MAX = 10

var ray_material = load("res://shaders/ray_traj.material")
var enab = true

onready var camera = get_node("Camera")
onready var rays = get_node("Rays")

func _process(delta):
	if Input.is_action_just_pressed("dbg"):
		enab = !enab
	
	# clear all rays
	for i in range(0, rays.get_child_count()):
		rays.get_child(i).queue_free()
	
	var collisions = []
	var shot_active = Input.is_action_just_pressed("shot")
	if shot_active || Input.is_action_pressed("visualize"):
		collisions = visualize()
	if shot_active:
		shot(collisions)


func shot(collisions):
	ray_path.generate(collisions)
	get_node("/root").add_child(ray_path)
	$AnimationPlayer.play("shot")


func visualize(): 
	var space_state = get_world().direct_space_state
	var toLocal = global_transform.inverse()
	var rem_length = LENGTH_MAX
	var startPt = $RailGun.transform * $RailGun/RayPoint.transform.origin
	var e = getFirstEndPt(toLocal) 
	var dir = (e - startPt).normalized()
	var i = 0
	var collisions = [global_transform * startPt]
	var final_node = null
	
	while rem_length > 0 && i < NB_RAYS_MAX:
		var result = space_state.intersect_ray(
			global_transform * startPt,
			global_transform * (rem_length * dir));
		
		if !result.empty():
			var endPt = toLocal * result['position']
			collisions.append(global_transform * endPt)
			createRay(startPt, endPt)
			if enab && !result['collider'].has_meta('bounceable'):
				final_node = result['collider']
				break
			
			# Set direction for the next ray
			var wall_normal = toLocal.basis * result['normal']
			var diff = startPt - endPt
			var length = diff.length()
			dir = (diff / length).reflect(wall_normal)
			startPt = endPt
			rem_length -= diff.length()
		else:
			var endPt = startPt + rem_length * dir
			collisions.append(global_transform * endPt)
			createRay(startPt, endPt)
			break
		
		i += 1
	
	return [collisions, final_node]


func getFirstEndPt(toLocal):
	var endPt = Vector3(0, 0, -LENGTH_MAX)
	var result = get_world().direct_space_state.intersect_ray(
		global_transform * Vector3(0, 0, -.5),
		global_transform * endPt);
	if !result.empty():
		return toLocal * result['position']
	else:
		return endPt


func createRay(start, end):
	var tmpMesh = Mesh.new()
	var vertices = PoolVector3Array()
	var UVs = PoolVector2Array()
	var color = Color(0.9, 0.1, 0.1)
	
	var diff = end - start
	var offset = THICKNESS * start.cross(end - start).normalized()
	vertices.push_back(start - offset)
	vertices.push_back(end - offset)
	vertices.push_back(end + offset)
	vertices.push_back(start + offset)
	
	UVs.push_back(Vector2(0,0))
	UVs.push_back(Vector2(0,1))
	UVs.push_back(Vector2(1,1))
	UVs.push_back(Vector2(1,0))
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	st.set_material(ray_material)
	
	for v in vertices.size():
		st.add_color(color)
		st.add_uv(UVs[v])
		st.add_vertex(vertices[v])
	
	st.commit(tmpMesh)
	
	var ray = MeshInstance.new()
	ray.mesh = tmpMesh
	rays.add_child(ray)
	
