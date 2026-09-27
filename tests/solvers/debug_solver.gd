extends SceneTree
## Dev helper: run one reference solver and print what it recovered (diffs for substitution).
## $GODOT --headless --path . -s res://tests/solvers/debug_solver.gd -- a1_p04 0 [frenzied]

func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var id: String = a[0] if a.size() > 0 else "a1_p12"
	var v: int = int(a[1]) if a.size() > 1 else 0
	var db: ContentDB = ContentDB.new()
	db.load_all()
	var inst: PuzzleInstance = PuzzleFactory.build(db.puzzle(id), v, a.has("frenzied"))
	var t0: int = Time.get_ticks_msec()
	if id == "a1_p12":
		var r: Dictionary = ReferenceSolvers.solve_p12(inst)
		var known: Array = r["known"]
		for i: int in range(2):
			var s: PackedByteArray = (known[i] as PackedByteArray).duplicate()
			for k: int in range(s.size()):
				if s[k] == 0:
					s[k] = 95
			print("KNOWN %d: %s" % [i, s.get_string_from_ascii().replace("\n", "|")])
		print("pins ", r["pins"])
	else:
		var r2: Dictionary = ReferenceSolvers.new().call("solve_" + id.substr(3), inst)
		var got: String = Substitution.decrypt(inst.ciphertexts[0], str(r2["key"]))
		var want: String = inst.plaintexts[0]
		var diffs: Dictionary = {}
		for i: int in range(want.length()):
			if got[i] != want[i]:
				diffs[want[i] + "->" + got[i]] = int(diffs.get(want[i] + "->" + got[i], 0)) + 1
		print("diffs (true->solved): ", diffs)
		var counts: PackedInt32Array = Frequency.counts(want)
		for k2: String in diffs.keys():
			print("  plain letter %s occurs %d times" % [k2[0], counts[k2.unicode_at(0) - 65]])
	print("ms ", Time.get_ticks_msec() - t0)
	quit(0)
