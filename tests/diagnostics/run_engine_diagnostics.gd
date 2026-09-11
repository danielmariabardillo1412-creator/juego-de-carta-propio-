extends SceneTree
## Headless entry point for the staged engine diagnostic.

const RUNNER_PATH = "res://src/diagnostics/engine_diagnostic_runner.gd"


func _initialize() -> void:
	var runner_script: Variant = load(RUNNER_PATH)
	if runner_script == null or not runner_script is Script:
		printerr("[UCE-DIAG][FATAL] Could not load diagnostic runner: %s" % RUNNER_PATH)
		quit(2)
		return
	var runner: Object = runner_script.new()
	if runner == null or not runner.has_method("run"):
		printerr("[UCE-DIAG][FATAL] Diagnostic runner is invalid.")
		quit(3)
		return
	var report: Variant = runner.call("run")
	if not report is Dictionary:
		printerr("[UCE-DIAG][FATAL] Diagnostic runner returned invalid report.")
		quit(4)
		return
	var status: String = str(report.get("summary", {}).get("status", "FAIL"))
	quit(0 if status == "PASS" else 1)
