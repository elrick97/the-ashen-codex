extends SceneTree
## Tiles PNGs into one contact sheet for quick review.
## Usage: $GODOT --headless --path . -s res://tools_dev/contact_sheet.gd -- <out.png> <cols> <thumb_width> <in1.png> <in2.png> ...

func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() < 4:
		print("usage: out cols width files...")
		quit(1)
		return
	var out: String = a[0]
	var cols: int = int(a[1])
	var tw: int = int(a[2])
	var imgs: Array[Image] = []
	for i: int in range(3, a.size()):
		var img: Image = Image.load_from_file(a[i])
		if img == null:
			continue
		var th: int = int(float(img.get_height()) * float(tw) / float(img.get_width()))
		img.resize(tw, th, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		imgs.append(img)
	var th_max: int = 0
	for img: Image in imgs:
		th_max = maxi(th_max, img.get_height())
	var rows: int = ceili(float(imgs.size()) / float(cols))
	var sheet: Image = Image.create(cols * (tw + 8), rows * (th_max + 8), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.3, 0.3, 0.3))
	for i: int in range(imgs.size()):
		var x: int = (i % cols) * (tw + 8) + 4
		@warning_ignore("integer_division")
		var y: int = (i / cols) * (th_max + 8) + 4
		sheet.blit_rect(imgs[i], Rect2i(0, 0, imgs[i].get_width(), imgs[i].get_height()), Vector2i(x, y))
	sheet.save_png(out)
	print("sheet ", out, " ", imgs.size())
	quit(0)
