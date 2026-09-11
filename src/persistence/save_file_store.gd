extends RefCounted
## Sandboxed bounded file persistence with temporary commit and rollback backup.

const MAX_BYTES := 4 * 1024 * 1024
const REQUIRED_PREFIX := "user://"


static func validate_path(path: String) -> Dictionary:
	if path.is_empty() or path.strip_edges() != path:
		return _error("SAVE_PATH_INVALID", "Save path must be trimmed and non-empty.")
	if not path.begins_with(REQUIRED_PREFIX):
		return _error("SAVE_PATH_OUTSIDE_USER", "Save files must stay inside user://.")
	var relative: String = path.substr(REQUIRED_PREFIX.length())
	if relative.is_empty() or relative.ends_with("/") or relative.ends_with("\\"):
		return _error("SAVE_PATH_INVALID", "Save path must identify a file.")
	var normalized: String = relative.replace("\\", "/")
	for segment in normalized.split("/", false):
		if segment == ".." or segment == "." or segment.is_empty():
			return _error("SAVE_PATH_TRAVERSAL", "Save path contains an unsafe segment.")
	if path.ends_with(".tmp") or path.ends_with(".bak"):
		return _error("SAVE_PATH_RESERVED_SUFFIX", "Save path cannot use internal temporary/backup suffixes.")
	return {"ok": true, "code": "OK", "message": ""}


static func write_atomic(path: String, text: String) -> Dictionary:
	var path_check: Dictionary = validate_path(path)
	if not path_check["ok"]:
		return path_check
	if text.is_empty():
		return _error("SAVE_TEXT_EMPTY", "Save text cannot be empty.")
	var bytes: PackedByteArray = text.to_utf8_buffer()
	if bytes.size() > MAX_BYTES:
		return _error("SAVE_FILE_TOO_LARGE", "Save exceeds maximum allowed size.")
	var temporary_path: String = path + ".tmp"
	var backup_path: String = path + ".bak"
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var absolute_temporary: String = ProjectSettings.globalize_path(temporary_path)
	var absolute_backup: String = ProjectSettings.globalize_path(backup_path)
	var parent_directory: String = absolute_path.get_base_dir()
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(parent_directory)
	if directory_error != OK and not DirAccess.dir_exists_absolute(parent_directory):
		return _error("SAVE_DIRECTORY_FAILED", "Could not create the save directory.")

	if FileAccess.file_exists(temporary_path):
		var stale_temporary_error: Error = DirAccess.remove_absolute(absolute_temporary)
		if stale_temporary_error != OK:
			return _error("SAVE_STALE_TEMPORARY_FAILED", "Could not remove stale temporary save.")
	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _error("SAVE_OPEN_FAILED", "Could not open temporary save file.")
	file.store_buffer(bytes)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(absolute_temporary)
		return _error("SAVE_WRITE_FAILED", "Temporary save file could not be written completely.")

	if FileAccess.file_exists(backup_path):
		var stale_backup_error: Error = DirAccess.remove_absolute(absolute_backup)
		if stale_backup_error != OK:
			DirAccess.remove_absolute(absolute_temporary)
			return _error("SAVE_STALE_BACKUP_FAILED", "Could not remove stale rollback backup.")
	var had_previous: bool = FileAccess.file_exists(path)
	if had_previous:
		var backup_error: Error = DirAccess.rename_absolute(absolute_path, absolute_backup)
		if backup_error != OK:
			DirAccess.remove_absolute(absolute_temporary)
			return _error("SAVE_BACKUP_FAILED", "Could not move previous save to rollback backup.")

	var commit_error: Error = DirAccess.rename_absolute(absolute_temporary, absolute_path)
	if commit_error != OK:
		DirAccess.remove_absolute(absolute_temporary)
		if had_previous and FileAccess.file_exists(backup_path):
			var rollback_error: Error = DirAccess.rename_absolute(absolute_backup, absolute_path)
			if rollback_error != OK:
				return _error("SAVE_COMMIT_AND_ROLLBACK_FAILED", "Commit failed and previous save could not be restored.")
		return _error("SAVE_COMMIT_FAILED", "Could not commit temporary save file.")
	if FileAccess.file_exists(backup_path):
		var cleanup_error: Error = DirAccess.remove_absolute(absolute_backup)
		if cleanup_error != OK:
			return {
				"ok": true,
				"code": "SAVE_COMMITTED_WITH_BACKUP_WARNING",
				"message": "Save committed, but rollback backup could not be removed.",
				"bytes": bytes.size(),
			}
	return {"ok": true, "code": "OK", "message": "", "bytes": bytes.size()}


static func read(path: String) -> Dictionary:
	var path_check: Dictionary = validate_path(path)
	if not path_check["ok"]:
		return path_check
	return _read_exact(path)


static func read_recoverable(path: String) -> Dictionary:
	var path_check: Dictionary = validate_path(path)
	if not path_check["ok"]:
		return path_check
	var primary: Dictionary = _read_exact(path)
	if primary["ok"]:
		primary["source"] = "PRIMARY"
		return primary
	var backup_path: String = path + ".bak"
	var backup: Dictionary = _read_exact(backup_path, false)
	if backup["ok"]:
		backup["source"] = "BACKUP"
		backup["primary_error"] = {"code": primary["code"], "message": primary["message"]}
		return backup
	return _error(
		"SAVE_PRIMARY_AND_BACKUP_UNAVAILABLE",
		"Primary failed (%s) and rollback backup failed (%s)." % [primary["code"], backup["code"]]
	)


static func restore_backup(path: String) -> Dictionary:
	var path_check: Dictionary = validate_path(path)
	if not path_check["ok"]:
		return path_check
	var backup_path: String = path + ".bak"
	if not FileAccess.file_exists(backup_path):
		return _error("SAVE_BACKUP_MISSING", "Rollback backup does not exist.")
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var absolute_backup: String = ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(path):
		var remove_error: Error = DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			return _error("SAVE_PRIMARY_REMOVE_FAILED", "Could not remove damaged primary save.")
	var restore_error: Error = DirAccess.rename_absolute(absolute_backup, absolute_path)
	if restore_error != OK:
		return _error("SAVE_BACKUP_RESTORE_FAILED", "Could not restore rollback backup.")
	return {"ok": true, "code": "OK", "message": ""}


static func _read_exact(path: String, enforce_public_path: bool = true) -> Dictionary:
	if enforce_public_path:
		var path_check: Dictionary = validate_path(path)
		if not path_check["ok"]:
			return path_check
	if not FileAccess.file_exists(path):
		return _error("SAVE_FILE_MISSING", "Save file does not exist.")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _error("SAVE_OPEN_FAILED", "Could not open save file.")
	var length: int = file.get_length()
	if length > MAX_BYTES:
		file.close()
		return _error("SAVE_FILE_TOO_LARGE", "Save exceeds maximum allowed size.")
	var text: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK:
		return _error("SAVE_READ_FAILED", "Save file could not be read completely.")
	if text.is_empty():
		return _error("SAVE_TEXT_EMPTY", "Save file is empty.")
	return {"ok": true, "code": "OK", "message": "", "value": text, "bytes": length}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
