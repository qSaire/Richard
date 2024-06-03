extends Timer

func _on_timeout():
	$"../AttackDirection/DamageBox/HurtBox/CollisionShape2D".disabled = true
	await get_tree().create_timer(1.2).timeout
	$"../AttackDirection/DamageBox/HurtBox/CollisionShape2D".disabled = false
