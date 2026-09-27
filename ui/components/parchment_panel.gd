class_name ParchmentPanel
extends PanelContainer
## A PanelContainer drawn as aged vellum (ui/shaders/parchment.gdshader).
## Children are laid out inside `padding`; the shader only affects this node's own draw.

const SHADER: Shader = preload("res://ui/shaders/parchment.gdshader")

@export var padding: int = 44
@export var page_seed: float = 0.0
@export var burn_width: float = 30.0

var _mat: ShaderMaterial = null


func _ready() -> void:
	var sb: StyleBoxEmpty = StyleBoxEmpty.new()
	sb.set_content_margin_all(padding)
	add_theme_stylebox_override("panel", sb)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("seed", page_seed)
	_mat.set_shader_parameter("burn_width", burn_width)
	material = _mat
	resized.connect(_sync)
	_sync()


func _sync() -> void:
	if _mat != null:
		_mat.set_shader_parameter("rect_size", size)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
