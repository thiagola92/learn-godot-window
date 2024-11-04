extends MarginContainer


enum Margin {
	NONE = 0,
	TOP,
	RIGHT,
	BOTTOM,
	LEFT = 4,
	TOP_RIGHT,
	TOP_LEFT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT = 8,
}

var _margin_dragging: bool = false

var _margin_dragging_edge_start: Vector2i

var _margin_selected: Margin

var _pendent_resize: Vector2i

var _title_bar_dragging: bool = false

var _title_bar_dragging_start: Vector2i

var _title_bar_dragging_adjustment: float = 0

@onready var _resize_timer: Timer = $ResizeTimer


func _get_current_margin() -> Margin:
	var margin: Margin = Margin.NONE
	
	if get_global_mouse_position().x < get_theme_constant("margin_left"):
		margin = Margin.LEFT
	elif get_global_mouse_position().x > size.x - get_theme_constant("margin_right"):
		margin = Margin.RIGHT
	
	if get_global_mouse_position().y < get_theme_constant("margin_top"):
		match margin:
			Margin.LEFT:
				return Margin.TOP_LEFT
			Margin.NONE:
				return Margin.TOP
			Margin.RIGHT:
				return Margin.TOP_RIGHT
	elif get_global_mouse_position().y > size.y - get_theme_constant("margin_bottom"):
		match margin:
			Margin.LEFT:
				return Margin.BOTTOM_LEFT
			Margin.NONE:
				return Margin.BOTTOM
			Margin.RIGHT:
				return Margin.BOTTOM_RIGHT
	
	return margin


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_margin_dragging = true
		_margin_selected = _get_current_margin()
		_margin_dragging_edge_start = get_window().position + get_window().size
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_margin_dragging = false


func _on_mouse_motion(_event: InputEventMouseMotion) -> void:
	if _margin_dragging:
		_on_dragged()
	else:
		_on_hover()


func _on_dragged() -> void:
	if get_window().mode != Window.MODE_WINDOWED:
		return
	
	var mouse_position: Vector2i = get_global_mouse_position()
	
	match _margin_selected:
		Margin.TOP:
			get_window().position.y += mouse_position.y # TODO: Fixing moving window down when small
			_pendent_resize = Vector2i(
				get_window().size.x,
				_margin_dragging_edge_start.y - get_window().position.y,
			)
		Margin.RIGHT:
			_pendent_resize = Vector2i(
				mouse_position.x,
				get_window().size.y,
			)
		Margin.BOTTOM:
			_pendent_resize = Vector2i(
				get_window().size.x,
				mouse_position.y,
			)
		Margin.LEFT:
			get_window().position.x += mouse_position.x # TODO: Fixing moving window right when small
			_pendent_resize = Vector2i(
				_margin_dragging_edge_start.x - get_window().position.x,
				get_window().size.y,
			)
		Margin.TOP_RIGHT:
			get_window().position.y += mouse_position.y # Top
			_pendent_resize = Vector2i(
				mouse_position.x, # Right
				_margin_dragging_edge_start.y - get_window().position.y, # Top
			)
		Margin.TOP_LEFT:
			get_window().position = Vector2i(
				get_window().position.x + mouse_position.x, # Left,
				get_window().position.y + mouse_position.y, # Top
			)
			
			_pendent_resize =  Vector2i(
				_margin_dragging_edge_start.x - get_window().position.x, # Left
				_margin_dragging_edge_start.y - get_window().position.y, # Top
			)
		Margin.BOTTOM_RIGHT:
			_pendent_resize = Vector2i(
				mouse_position.x, # Right
				mouse_position.y, # Bottom
			)
		Margin.BOTTOM_LEFT:
			get_window().position.x += mouse_position.x # Left
			_pendent_resize = Vector2i(
				_margin_dragging_edge_start.x - get_window().position.x, # Left
				mouse_position.y, # Bottom
			)
	
	if _resize_timer.is_stopped():
		_resize_timer.start()


func _on_hover() -> void:
	match _get_current_margin():
		Margin.TOP:
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
		Margin.RIGHT:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Margin.BOTTOM:
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
		Margin.LEFT:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Margin.TOP_RIGHT:
			mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		Margin.TOP_LEFT:
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		Margin.BOTTOM_RIGHT:
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		Margin.BOTTOM_LEFT:
			mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE


func _on_minimize_pressed() -> void:
	get_window().mode = Window.MODE_MINIMIZED


func _on_maximize_pressed() -> void:
	if get_window().mode == Window.MODE_MAXIMIZED:
		get_window().mode = Window.MODE_WINDOWED
	else:
		get_window().mode = Window.MODE_MAXIMIZED


func _on_close_pressed() -> void:
	get_tree().quit()


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_title_bar_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_title_bar_mouse_motion(event)


func _on_title_bar_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_on_title_bar_double_click()
	elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_title_bar_dragging = true
		_title_bar_dragging_start = get_global_mouse_position()
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_title_bar_dragging = false


func _on_title_bar_double_click() -> void:
	match get_window().mode:
		Window.MODE_MAXIMIZED:
			get_window().mode = Window.MODE_WINDOWED
		_:
			get_window().mode = Window.MODE_MAXIMIZED


func _on_title_bar_mouse_motion(_event: InputEventMouseMotion) -> void:
	if _title_bar_dragging:
		_on_title_bar_dragged()


func _on_title_bar_dragged() -> void:
	match get_window().mode:
		Window.MODE_WINDOWED:
			get_window().position += get_global_mouse_position() as Vector2i - _title_bar_dragging_start
		Window.MODE_MAXIMIZED:
			_title_bar_dragging_adjustment = get_global_mouse_position().x / get_window().size.x
			get_window().mode = Window.MODE_WINDOWED


func _on_resized() -> void:
	if _title_bar_dragging_adjustment != 0:
		get_window().position += (get_global_mouse_position() as Vector2i)
		get_window().position.x -= int(get_window().size.x * _title_bar_dragging_adjustment)
		_title_bar_dragging_start = get_global_mouse_position()
		_title_bar_dragging_adjustment = 0


func _on_resize_timer_timeout() -> void:
	get_window().size = _pendent_resize
	_pendent_resize = Vector2i()
