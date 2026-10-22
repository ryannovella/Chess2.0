extends SceneTree

func _init() -> void:
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(200, 200)
	
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "This is a very long explanation about how this move blundered a piece and lost control of the center and created serious tactical weaknesses on the kingside."
	vbox.add_child(label)
	
	root.add_child(vbox)
	
	print("VBox with label autowrap min size:", vbox.get_combined_minimum_size())
	
	label.max_lines_visible = 2
	print("VBox with max_lines_visible 2 min size:", vbox.get_combined_minimum_size())
	
	vbox.free()
	quit(0)
