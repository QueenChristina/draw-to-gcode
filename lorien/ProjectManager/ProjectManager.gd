extends Node

# -------------------------------------------------------------------------------------------------
var _open_projects: Array # Array<Project>
var _active_project: Project

signal error_encountered(message)

# -------------------------------------------------------------------------------------------------
func read_project_list() -> void:
	pass

# -------------------------------------------------------------------------------------------------
# Returns if successfully made project active
func make_project_active(project: Project) -> bool:
	if !project.loaded:
		var err = _load_project(project)
		if err != "OK":
			var error_mssg = "Error opening project: \n    %s\nError Message:\n    %s\nCheck you are using the correct version of software. If so, please contact the developers." % [project.filepath, err]
			emit_signal("error_encountered", error_mssg)
			return false
	_active_project = project
	return true

# -------------------------------------------------------------------------------------------------
func get_active_project() -> Project:
	return _active_project

# -------------------------------------------------------------------------------------------------
func remove_project(project: Project) -> void:
	var index := _open_projects.find(project)
	if index >= 0:
		_open_projects.remove(index)
	
	if project == _active_project:
		_active_project = null
	
	project.clear()

# -------------------------------------------------------------------------------------------------
func remove_all_projects() -> void:
	for project in _open_projects:
		remove_project(project)
	_open_projects.clear()
	_active_project = null

# -------------------------------------------------------------------------------------------------
func add_project(filepath: String = "") -> Project:
	# Check if already open
	if !filepath.empty():
		var p := get_open_project_by_filepath(filepath)
		if p != null:
			print_debug("Project already in open project list")
			return p
	
	var canvas_color: Color = Settings.get_value(Settings.GENERAL_DEFAULT_CANVAS_COLOR, Config.DEFAULT_CANVAS_COLOR)
	
	var project := Project.new()
	project.meta_data[ProjectMetadata.CANVAS_COLOR] = canvas_color.to_html(false)
	project.id = _open_projects.size()
	project.filepath = filepath
	project.loaded = project.filepath.empty() # empty/unsaved/new projects are loaded by definition
	_open_projects.append(project)
	return project
	
# -------------------------------------------------------------------------------------------------
func save_project(project: Project) -> void:
	Serializer.save_project(project)
	project.dirty = false

# -------------------------------------------------------------------------------------------------
func save_all_projects() -> void:
	for p in _open_projects:
		if !p.filepath.empty() && p.loaded && p.dirty:
			save_project(p)

# -------------------------------------------------------------------------------------------------
# Returns error message or OK if loaded ok
func _load_project(project: Project) -> String:
	if !project.loaded:
		var err = Serializer.load_project(project)
		if err == "OK":
			project.loaded = true
		else:
			print_debug("Error loading project because " + err)
			return err
	else:
		print_debug("Trying to load already loaded project")
	return "OK"

# -------------------------------------------------------------------------------------------------
func get_open_project_by_filepath(filepath: String) -> Project:
	for p in _open_projects:
		if p.filepath == filepath:
			return p
	return null

# -------------------------------------------------------------------------------------------------
func get_project_by_id(id: int) -> Project:
	for p in _open_projects:
		if p.id == id:
			return p
	return null

# -------------------------------------------------------------------------------------------------
func has_unsaved_changes() -> bool:
	for p in _open_projects:
		if p.dirty:
			return true 
	return false

# -------------------------------------------------------------------------------------------------
func has_unsaved_projects() -> bool:
	for p in _open_projects:
		if p.dirty && p.filepath.empty():
			return true
	return false

# -------------------------------------------------------------------------------------------------
func get_project_count() -> int:
	return _open_projects.size()

# -------------------------------------------------------------------------------------------------
func is_active_project(project: Project) -> bool:
	return _active_project == project

# -------------------------------------------------------------------------------------------------
func get_open_projects() -> Array:
	return _open_projects
