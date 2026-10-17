extends Control

@export var cell_count: int = 150
@export var columns: int = 25
@export var layout_count: int = 300
@export var gap: float = 3.0
@export var pad_v: float = 14.0


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var cols := maxi(columns, 1)
	var layout_rows := ceili(float(maxi(layout_count, cell_count)) / float(cols))
	if size.x < 8.0 or size.y < 8.0:
		return
	var inner_h := maxf(size.y - pad_v * 2.0, 8.0)
	var cell := minf(
		(size.x - gap * float(cols - 1)) / float(cols),
		(inner_h - gap * float(layout_rows - 1)) / float(layout_rows)
	)
	cell = maxf(cell, 3.0)
	var radius := cell * 0.46
	var step := cell + gap
	var grid_w := float(cols) * cell + gap * float(cols - 1)
	var grid_h := float(layout_rows) * cell + gap * float(layout_rows - 1)
	var origin := Vector2((size.x - grid_w) * 0.5, pad_v + (inner_h - grid_h) * 0.5)
	var fill := Color(1, 1, 1, 1)
	var stroke := Color(0.55, 0.42, 0.28, 0.78)
	for index in cell_count:
		var col := index % cols
		var row := int(index / cols)
		var center := origin + Vector2(float(col) * step + cell * 0.5, float(row) * step + cell * 0.5)
		draw_circle(center, radius, fill)
		draw_arc(center, radius, 0.0, TAU, 28, stroke, 1.2, true)
