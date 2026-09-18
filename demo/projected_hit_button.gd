extends Button
## Botón cuyo área interactiva puede seguir un polígono proyectado en vez del rectángulo completo.

var _projected_hit_polygon := PackedVector2Array()


func set_projected_hit_polygon(polygon: PackedVector2Array) -> void:
	_projected_hit_polygon = polygon.duplicate()


func clear_projected_hit_polygon() -> void:
	_projected_hit_polygon = PackedVector2Array()


func projected_hit_polygon() -> PackedVector2Array:
	return _projected_hit_polygon.duplicate()


func _has_point(point: Vector2) -> bool:
	if _projected_hit_polygon.size() >= 3:
		return Geometry2D.is_point_in_polygon(point, _projected_hit_polygon)
	return Rect2(Vector2.ZERO, size).has_point(point)
