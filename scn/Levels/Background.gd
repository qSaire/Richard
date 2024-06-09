extends ParallaxBackground

func revert_offset(parLayer: ParallaxLayer) -> void:
	# Cancel out layer's offset. The layer's position already has 
	# its motion_scale applied.
	var ofs := scroll_offset - parLayer.position
	if !scroll_ignore_camera_zoom:
		# When attention is given to the camera's zoom, we need to account for it.
		# We can use viewport's canvas transform scale to which the camera has
		# already applied its zoom.
		var canvas_scale = get_viewport().canvas_transform.get_scale()
		ofs /= canvas_scale.dot(Vector2(0.5, 0.5))
	parLayer.motion_offset = ofs

func _ready() -> void:
	scroll_offset = Vector2(0, 0)
	for parLayer in get_children():
		if parLayer is ParallaxLayer:
			revert_offset(parLayer)
