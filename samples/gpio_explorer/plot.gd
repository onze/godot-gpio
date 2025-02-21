extends Control


@export var x_min :float = 0.
@export var x_max :float = 1.
@export var y_min :float = 0.
@export var y_max :float = 1.

@export var background_color: = Color.TRANSPARENT
@export var curve_color_low := Color.BLACK
@export var curve_color_high := Color.RED
@export var width :float = -.1
@export var margin := Vector2(.2, 5)

var _points := PackedVector2Array()
var _curve_colors := PackedColorArray()

func _ready()->void:
	queue_redraw()

func add_point(p :Vector2)->void:
	_points.append(p)
	_curve_colors.append(curve_color_low.lerp(
		curve_color_high,
		1.-(p.y-y_min)/(y_max-y_min)
	))
	queue_redraw()

func _draw()->void:
	# clean outlier values
	var min_index := 0
	var max_index := _points.size()-1
	if not _points.is_empty():
		while _points[min_index].x < x_min:
			min_index += 1
		while _points[max_index].x > x_max:
			max_index -= 1
	_points = _points.slice(min_index, max_index+1)
	_curve_colors = _curve_colors.slice(min_index, max_index+1)

	# map points
	var mapped_points := _points.duplicate()
	var rect := Rect2(Vector2.ZERO+margin, size-2.*margin)
	for i :int in mapped_points.size():
		var p := mapped_points[i]
		p.x = remap(p.x, x_min, x_max, rect.position.x, rect.end.x)
		p.y = remap(p.y, y_min, y_max, rect.position.y, rect.end.y)
		mapped_points[i] = p

	## draw
	# background
	draw_rect(
		rect,
		background_color,
		true,
	)
	#draw_rect(
		#Rect2(Vector2.ZERO, size),
		#Color.BLACK,
		#false,
	#)
	# X axis
	draw_line(
		Vector2(rect.position.x+5, rect.get_center().y),
		Vector2(rect.end.x-5, rect.get_center().y),
		Color.BLACK,
		-.1
	)
	# curve
	if mapped_points.size() == 1:
		mapped_points.append(mapped_points[0])
	if not mapped_points.is_empty():
		draw_polyline_colors(
			mapped_points,
			_curve_colors,
			width,
			true,
		)
