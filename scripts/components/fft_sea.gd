extends Node3D
## The realistic sea (Olivier, 2026-10-24: the painted sea looked "Nintendo 64"). Runs the
## tessarakkt/godot4-oceanfft add-on (MIT, addons/tessarakkt.oceanfft): FFT waves on the GPU
## with distance-based detail (CDLOD). Kept light for a MacBook: 128x128 FFT, a small LOD tree,
## and the wave heights read back so the ship rides the real swell.
## Needs compute shaders (Forward+ / Metal); sea.gd falls back to the painted sea without them.

const OCEAN_MATERIAL := preload("res://addons/tessarakkt.oceanfft/Ocean.tres")

@export var wind_speed := 14.0 ## metres per second: a lively sea
@export var choppiness := 1.4
@export var time_scale := 1.0

var ocean: Resource ## Ocean3D
var _tree: Node3D ## QuadTree3D


static func supported() -> bool:
	return DisplayServer.get_name() != "headless" and RenderingServer.get_rendering_device() != null


func _ready() -> void:
	name = "FFTSea"
	var Ocean3D: Script = load("res://addons/tessarakkt.oceanfft/components/Ocean3D.gd")
	ocean = Ocean3D.new()
	ocean.material = OCEAN_MATERIAL.duplicate()
	ocean.fft_resolution = 128
	ocean.horizontal_dimension = 512
	ocean.simulation_frameskip = 0
	ocean.heightmap_sync_frameskip = 0
	ocean.time_scale = time_scale * 1.1
	ocean.cascade_scales = [3.23607, 1.61803, 0.5] as Array[float]
	ocean.choppiness = choppiness
	ocean.wind_speed = wind_speed
	ocean.wave_scroll_speed = -0.003
	_paint(ocean.material)
	ocean.initialize_simulation()
	_tree = (load("res://addons/tessarakkt.oceanfft/components/QuadTree3D.gd") as Script).new()
	_tree.name = "Surface"
	_tree.lod_level = 5
	_tree.quad_size = 4096.0
	_tree.mesh_vertex_resolution = 128
	_tree.ranges = [120.0, 240.0, 480.0, 960.0, 1920.0, 3840.0] as Array[float]
	_tree.material = ocean.material
	add_child(_tree)


func _process(delta: float) -> void:
	ocean.simulate(delta)


## Height of the sea surface at a world point (metres; 0 = calm sea level).
func height_at(world: Vector3) -> float:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return 0.0
	return ocean.get_wave_height(camera, world, 1, 2)


## Storm: stronger wind, choppier water.
func set_storm(on: bool) -> void:
	if on:
		ocean.wind_speed = wind_speed * 2.0
		ocean.choppiness = choppiness * 1.6



## Our palette: the add-on's ocean is tuned for a horizon view; from the couch camera high above
## the deck it looked near-black. Brighter deep water, light coming up through it, whitecaps.
func _paint(material: ShaderMaterial) -> void:
	material.set_shader_parameter("deep_color", Color(0.03, 0.22, 0.42))
	material.set_shader_parameter("shallow_color", Color(0.1, 0.62, 0.78))
	material.set_shader_parameter("sss_color", Color(0.12, 0.7, 0.8))
	material.set_shader_parameter("sss_upwelling", 0.35)
	material.set_shader_parameter("sss_backlight_strength", 0.05)
	material.set_shader_parameter("fresnel_strength", 0.35)
	material.set_shader_parameter("foam_coverage", 0.25)
	material.set_shader_parameter("foam_jacobian_limit", 0.85)
	material.set_shader_parameter("specular_strength", 2.5)
	material.set_shader_parameter("specular_power", 250.0)
