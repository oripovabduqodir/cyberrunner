extends Control
class_name CyberBackground

## Kiberpank menyu sahnalari uchun ko'p qatlamli parallax fon, tuman, neon miltillash va yomg'ir effekti.
## Compatibility renderer va mobil qurilmalar uchun optimallashtirilgan.

@onready var far_skyline: TextureRect = $FarSkyline
@onready var mid_skyline: TextureRect = $MidSkyline
@onready var fog_layer: Control = $FogLayer
@onready var fog_band_1: ColorRect = $FogLayer/FogBand1
@onready var fog_band_2: ColorRect = $FogLayer/FogBand2
@onready var neon_lights: Control = $NeonLights
@onready var rain_particles: CPUParticles2D = $RainParticles
@onready var flicker_timer: Timer = $FlickerTimer

var _time: float = 0.0
var _parallax_enabled: bool = true
var _flicker_enabled: bool = true
var _fog_enabled: bool = true
var _far_base_pos: Vector2 = Vector2(-80.0, 0.0)
var _mid_base_pos: Vector2 = Vector2(-80.0, 0.0)


func _ready() -> void:
	_far_base_pos = far_skyline.position
	_mid_base_pos = mid_skyline.position

	SettingsManager.visual_effects_changed.connect(apply_visual_quality)
	apply_visual_quality(SettingsManager.visual_effects)
	flicker_timer.timeout.connect(_on_flicker_timer_timeout)


func _process(delta: float) -> void:
	_time += delta

	if _parallax_enabled:
		var target_offset: Vector2 = Vector2(sin(_time * 0.35) * 18.0, cos(_time * 0.25) * 4.0)
		var vp_size: Vector2 = get_viewport_rect().size
		if vp_size.x > 0.0 and vp_size.y > 0.0 and not OS.has_feature("mobile"):
			var mouse_norm: Vector2 = (get_viewport().get_mouse_position() / vp_size) - Vector2(0.5, 0.5)
			target_offset += Vector2(-mouse_norm.x * 36.0, -mouse_norm.y * 12.0)

		far_skyline.position = far_skyline.position.lerp(_far_base_pos + target_offset * 0.45, delta * 3.0)
		mid_skyline.position = mid_skyline.position.lerp(_mid_base_pos + target_offset, delta * 4.0)

	if _fog_enabled:
		fog_band_1.position.x += 18.0 * delta
		if fog_band_1.position.x > 1280.0:
			fog_band_1.position.x = -fog_band_1.size.x

		if fog_band_2.visible:
			fog_band_2.position.x -= 12.0 * delta
			if fog_band_2.position.x < -fog_band_2.size.x:
				fog_band_2.position.x = 1280.0


func apply_visual_quality(quality: int) -> void:
	match quality:
		SettingsManager.VisualQuality.LOW:
			_parallax_enabled = false
			_flicker_enabled = false
			_fog_enabled = false
			fog_layer.visible = false
			rain_particles.emitting = false
			rain_particles.visible = false
			neon_lights.modulate.a = 0.65
		SettingsManager.VisualQuality.MEDIUM:
			_parallax_enabled = true
			_flicker_enabled = true
			_fog_enabled = true
			fog_layer.visible = true
			fog_band_2.visible = false
			rain_particles.visible = true
			rain_particles.amount = 65
			rain_particles.emitting = true
		_:
			_parallax_enabled = true
			_flicker_enabled = true
			_fog_enabled = true
			fog_layer.visible = true
			fog_band_2.visible = true
			rain_particles.visible = true
			rain_particles.amount = 140
			rain_particles.emitting = true


func _on_flicker_timer_timeout() -> void:
	if not _flicker_enabled:
		return
	var children: Array[Node] = neon_lights.get_children()
	if children.is_empty():
		return
	var light := children[randi() % children.size()] as CanvasItem
	if light == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(light, "modulate:a", 0.25, 0.06)
	tween.tween_property(light, "modulate:a", 1.0, 0.08)
	tween.tween_property(light, "modulate:a", 0.45, 0.05)
	tween.tween_property(light, "modulate:a", 0.95, 0.1)
