@tool
class_name ActionQueue extends HBoxContainer

func _init() -> void:
	self.child_entered_tree.connect(self._on_child_entered)

func _on_child_entered(child: Node) -> void:
	if child is Control:
		var c: Control = child as Control
		c.custom_minimum_size = Vector2(64, 64)
	if child is TextureRect:
		var c: TextureRect = child as TextureRect
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

