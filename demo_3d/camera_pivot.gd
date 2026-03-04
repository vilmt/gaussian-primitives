extends Node3D

func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	t *= 0.3
	rotation.y = -t
