extends Node
## Minimal boot shell that dynamically loads the diagnostic runner.
## If the runner itself cannot parse/load, this shell still writes an emergency
## marker and exits with a distinct code while the launcher captures stderr.

const RUNNER_PATH = "res://src/diagnostics/engine_diagnostic_runner.gd"


func _ready() -> void:
	_write_emergency_marker("BOOTSTRAP_STARTED", "Diagnostic bootstrap entered _ready().")
	var runner_script: Variant = load(RUNNER_PATH)
	if runner_script == null or not runner_script is Script:
		_write_emergency_marker("RUNNER_LOAD_FAILED", "Could not load %s" % RUNNER_PATH)
		printerr("[UCE-DIAG][FATAL] Diagnostic runner could not be loaded.")
		get_tree().quit(2)
		return
	var runner: Object = runner_script.new()
	if runner == null or not runner.has_method("run"):
		_write_emergency_marker("RUNNER_INVALID", "Diagnostic runner did not instantiate or lacks run().")
		printerr("[UCE-DIAG][FATAL] Diagnostic runner is invalid.")
		get_tree().quit(3)
		return
	var report: Variant = runner.call("run")
	if not report is Dictionary:
		_write_emergency_marker("REPORT_INVALID", "Diagnostic runner returned a non-Dictionary result.")
		printerr("[UCE-DIAG][FATAL] Diagnostic report is invalid.")
		get_tree().quit(4)
		return
	var status: String = str(report.get("summary", {}).get("status", "FAIL"))
	get_tree().quit(0 if status == "PASS" else 1)


func _write_emergency_marker(code: String, message: String) -> void:
	var directory: String = ProjectSettings.globalize_path("res://diagnostic_logs")
	DirAccess.make_dir_recursive_absolute(directory)
	var path: String = directory.path_join("uce_bootstrap_latest.txt")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string("code=%s\nmessage=%s\nunix=%d\n" % [code, message, int(Time.get_unix_time_from_system())])
		file.close()
