class_name GameContext
extends RefCounted
## The non-autoload services, created once by Main and injected into every screen.

var db: ContentDB = null
var progression: Progression = null
var hints: HintService = null
var codex: CodexService = null


static func create() -> GameContext:
	var ctx: GameContext = GameContext.new()
	ctx.db = ContentDB.new()
	ctx.db.load_all()
	ctx.progression = Progression.new(ctx.db)
	ctx.hints = HintService.new(ctx.progression)
	ctx.codex = CodexService.new(ctx.db)
	return ctx
