tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("Polygon2Dwater", "Node2D", preload("res://addons/polygon2dwater/polygon2dwater.gd"), preload("res://addons/polygon2dwater/icon.png"))

func _exit_tree():
	remove_custom_type("Polygon2dWater")
