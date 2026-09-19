extends PanelContainer
## Onboarding prehumano: enseña vocabulario y reglas, no secuencias de clics.
## Debe permitir que la prueba humana mida descubrimiento de interacción real.

signal onboarding_closed

const PAGES := [
	{
		"title": "1 · OBJETIVO",
		"body": "Reduce la Vida rival a 0.\n\nCada jugador administra Vida, Energía, mano, campo y Cementerio. La Energía limita muchas jugadas; no todas las cartas hacen lo mismo ni ocupan la misma zona.",
		"hint": "Primero entiende qué quieres conseguir; después observa qué te permite hacer la mesa."
	},
	{
		"title": "2 · CÓMO LEER UNA CARTA",
		"body": "CRIATURA — tiene coste, elemento, ATQ y DEF. Puede estar en Ataque o Guardia.\n\nMAGIA — produce un efecto.\nTRAMPA — puede prepararse para responder más tarde.\nOBJETO/EQUIPO — se vincula a una criatura compatible.\nTERRENO — modifica el Territorio.\nFUSIÓN — nace de materiales compatibles.",
		"hint": "Nombre, tipo, elemento, coste y estadísticas están visibles en la propia carta; el texto completo se consulta en su vista ampliada."
	},
	{
		"title": "3 · LA MESA",
		"body": "La fila de CRIATURAS es donde combaten tus unidades.\nLa fila de APOYOS guarda cartas persistentes o preparadas.\nTERRITORIO contiene el Terreno activo.\nBARAJA y CEMENTERIO están en los laterales.\nLa MANO está junto a tu lado de la mesa.",
		"hint": "Una carta no puede ir a cualquier sitio: su tipo y las reglas determinan sus destinos legales."
	},
	{
		"title": "4 · TURNO Y POSTURAS",
		"body": "La partida avanza por fases. Durante tus fases principales preparas el campo; durante combate atacas cuando sea legal.\n\nATAQUE favorece la ofensiva. GUARDIA cambia la orientación de la criatura y representa una postura defensiva. Algunas cartas pueden entrar ocultas o cambiar de postura bajo condiciones concretas.",
		"hint": "La barra superior siempre indica de quién es el turno y en qué fase estás."
	},
	{
		"title": "5 · RESPUESTAS Y FUSIONES",
		"body": "Algunas jugadas abren una ventana de RESPUESTA. Si tienes prioridad puedes usar una respuesta legal o PASAR; pasar una respuesta no significa terminar tu turno.\n\nLas FUSIONES requieren materiales compatibles. Antes del compromiso final puedes revisar o cancelar la selección mientras la interfaz lo permita.",
		"hint": "Las decisiones de respuesta y Fusión son parte de las reglas, no mensajes de error."
	},
	{
		"title": "6 · YA PUEDES JUGAR",
		"body": "No necesitas memorizar todos los efectos. Lee las cartas, observa las zonas y fíjate en los resaltados que aparecen cuando una jugada es legal.\n\nSi algo no entiendes, prueba primero lo que te parezca natural: esta versión está precisamente para comprobar si la mesa comunica bien sus reglas.",
		"hint": "La guía explica el juego; no te dice la secuencia exacta para ejecutar cada acción."
	},
]

var _page := 0
var _title_label: Label
var _body_label: Label
var _hint_label: Label
var _counter_label: Label
var _previous_button: Button
var _next_button: Button


func _ready() -> void:
	name = "PrehumanOnboarding"
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", _panel_style())
	_build_ui()
	_render_page()


func open() -> void:
	_page = 0
	visible = true
	_render_page()


func close() -> void:
	visible = false
	onboarding_closed.emit()


func page_count() -> int:
	return PAGES.size()


func current_page() -> int:
	return _page


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(680, 430)
	card.add_theme_stylebox_override("panel", _card_style())
	center.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var eyebrow := Label.new()
	eyebrow.text = "GUÍA RÁPIDA · PROTOTIPO"
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", Color("aabbb9"))
	root.add_child(eyebrow)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color("f3d58a"))
	root.add_child(_title_label)

	_body_label = Label.new()
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 17)
	_body_label.add_theme_color_override("font_color", Color("e6eceb"))
	root.add_child(_body_label)

	var hint_panel := PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", _hint_style())
	root.add_child(hint_panel)
	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color("d7c894"))
	hint_panel.add_child(_hint_label)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	root.add_child(nav)

	_counter_label = Label.new()
	_counter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_counter_label.add_theme_color_override("font_color", Color("aabbb9"))
	nav.add_child(_counter_label)

	_previous_button = Button.new()
	_previous_button.text = "← ANTERIOR"
	_previous_button.custom_minimum_size = Vector2(130, 44)
	_previous_button.pressed.connect(_previous_page)
	nav.add_child(_previous_button)

	_next_button = Button.new()
	_next_button.custom_minimum_size = Vector2(150, 44)
	_next_button.pressed.connect(_next_page)
	nav.add_child(_next_button)


func _render_page() -> void:
	if _title_label == null:
		return
	_page = clampi(_page, 0, PAGES.size() - 1)
	var page: Dictionary = PAGES[_page]
	_title_label.text = String(page["title"])
	_body_label.text = String(page["body"])
	_hint_label.text = "💡 " + String(page["hint"])
	_counter_label.text = "%d / %d" % [_page + 1, PAGES.size()]
	_previous_button.disabled = _page == 0
	_next_button.text = "EMPEZAR" if _page == PAGES.size() - 1 else "SIGUIENTE →"


func _previous_page() -> void:
	if _page <= 0:
		return
	_page -= 1
	_render_page()


func _next_page() -> void:
	if _page >= PAGES.size() - 1:
		close()
		return
	_page += 1
	_render_page()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("03080ddd")
	return style


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111b22f8")
	style.border_color = Color("b49a5e")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color("000000aa")
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func _hint_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b252c")
	style.border_color = Color("5a665f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style
