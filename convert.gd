extends SceneTree

func _init():
	var img = Image.new()
	var err = img.load("res://icons_sheet.jpg")
	if err == OK:
		img.save_png("res://icons_sheet.png")
		print("icons_sheet converted to png")
	else:
		print("failed to load icons_sheet.jpg")
		
	var img2 = Image.new()
	var err2 = img2.load("res://dice_sheet.jpg")
	if err2 == OK:
		img2.save_png("res://dice_sheet.png")
		print("dice_sheet converted to png")
	else:
		print("failed to load dice_sheet.jpg")
		
	quit()
