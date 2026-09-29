extends Node2D

var pelaajien_määrä: int = 1

const KORTIN_KOKO := Vector2(95, 142)
const REUNAN_VARA := Vector2(110, 90)
const VUORON_VÄRI := Color(1.0, 0.8, 0.2)

const SÄÄNNÖT := ["normaali", "tupla"]

var maat := ["hertta", "ruutu", "risti", "pata"]
var pakka: Array[Dictionary] = []
var peli_säännöt = preload("res://saannot/normaali.gd")
@onready var peli_säännöt_instanssi = peli_säännöt.new()

var pelaajat: Array[Node2D] = []
@onready var nostonapit: Array[Button] = [$Keskusta/Nostakortti1, $Keskusta/Nostakortti2, $Keskusta/Nostakortti3, $Keskusta/Nostakortti4]
var pelaajien_kortit: Array = []
var vuoro: int = 0

func _aseta_pelaajat() -> void:
	for i in pelaajien_määrä:
		var pelaaja := Node2D.new()
		pelaaja.name = "Pelaaja%d" % (i + 1)
		pelaaja.add_child(_luo_korostus())
		pelaaja.add_child(_luo_korttipaikka())
		pelaaja.add_child(_luo_nimi(i + 1))
		pelaaja.add_child(_luo_straffi())

		add_child(pelaaja)
		pelaajat.append(pelaaja)
		pelaajien_kortit.append(null)

	_asettele()
	_korosta_vuoro()

# Sijoittaa pakan ruudun keskelle ja pelaajat ellipsille sen ympärille.
func _asettele() -> void:
	var keskipiste := get_viewport_rect().size / 2
	var säde := keskipiste - REUNAN_VARA
	$Keskusta.position = keskipiste

	for i in pelaajat.size():
		var kulma := PI / 2 + TAU * i / pelaajat.size()
		var pelaaja := pelaajat[i]
		pelaaja.position = keskipiste + Vector2(cos(kulma) * säde.x, sin(kulma) * säde.y)
		pelaaja.rotation = (keskipiste - pelaaja.position).angle() + PI / 2

func _luo_korttipaikka() -> Panel:
	var tyyli := StyleBoxFlat.new()
	tyyli.bg_color = Color(1, 1, 1, 0.08)
	tyyli.border_color = Color(1, 1, 1, 0.6)
	tyyli.set_border_width_all(2)
	tyyli.set_corner_radius_all(8)

	var paikka := Panel.new()
	paikka.name = "Korttipaikka"
	paikka.size = KORTIN_KOKO
	paikka.position = -KORTIN_KOKO / 2
	paikka.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paikka.add_theme_stylebox_override("panel", tyyli)
	return paikka

# Keltainen kehys kortin ympärillä sille, jonka vuoro on nostaa. Kehys on korttia
# vähän isompi ja sen alla, joten se näkyy myös kun paikalla on jo kortti.
func _luo_korostus() -> Panel:
	const REUNUS := 8.0

	var tyyli := StyleBoxFlat.new()
	tyyli.bg_color = Color(VUORON_VÄRI, 0.25)
	tyyli.border_color = VUORON_VÄRI
	tyyli.set_border_width_all(4)
	tyyli.set_corner_radius_all(12)

	var korostus := Panel.new()
	korostus.name = "Korostus"
	korostus.size = KORTIN_KOKO + Vector2(REUNUS, REUNUS) * 2
	korostus.position = -korostus.size / 2
	korostus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	korostus.add_theme_stylebox_override("panel", tyyli)
	korostus.hide()

	# Hidas sykkivä vilkkuminen, jotta vuoron huomaa pöydän toiseltakin puolelta
	var tween := korostus.create_tween().set_loops()
	tween.tween_property(korostus, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(korostus, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	return korostus

# Näyttää korostuksen ja keltaisen nimen vain vuorossa olevalla pelaajalla.
# Jos vuorossa ei ole ketään (esim. peli loppui), korostus poistetaan kaikilta.
func _korosta_vuoro(korostettava: int = vuoro) -> void:
	for i in pelaajat.size():
		var on_vuorossa := i == korostettava
		pelaajat[i].get_node("Korostus").visible = on_vuorossa
		var nimi: Label = pelaajat[i].get_node("Nimi")
		if on_vuorossa:
			nimi.add_theme_color_override("font_color", VUORON_VÄRI)
		else:
			nimi.remove_theme_color_override("font_color")

func _luo_nimi(numero: int) -> Label:
	const KORKEUS := 24.0

	var nimi := Label.new()
	nimi.name = "Nimi"
	nimi.text = "P%d" % numero
	nimi.size = Vector2(KORTIN_KOKO.x, KORKEUS)
	nimi.position = Vector2(-KORTIN_KOKO.x / 2, -KORTIN_KOKO.y / 2 - KORKEUS)
	nimi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nimi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nimi.add_theme_font_size_override("font_size", 22)
	return nimi

func _nosta_kortti() -> void:
	if pakka.is_empty():
		return

	var kortti: Dictionary = pakka.pop_back()
	var pelaaja := pelaajat[vuoro]

	var kuva: Sprite2D = pelaaja.get_node_or_null("Kortti")
	if kuva == null:
		kuva = Sprite2D.new()
		kuva.name = "Kortti"
		kuva.scale = Vector2(0.2, 0.2)
		pelaaja.add_child(kuva)
	kuva.texture = load(kortti["kuva"])
	pelaajien_kortit[vuoro] = kortti

	var straffit: Array[String] = peli_säännöt_instanssi.laske_straffit(vuoro, pelaajien_kortit)
	_näytä_straffit(straffit)

	vuoro = (vuoro + 1) % pelaajat.size()
	_korosta_vuoro()

	if pakka.is_empty():
		_lopeta_peli()

# Straffi näytetään isona tekstinä pelaajan kortin päällä.
func _luo_straffi() -> Label:
	var teksti := Label.new()
	teksti.name = "Straffi"
	teksti.size = KORTIN_KOKO
	teksti.position = -KORTIN_KOKO / 2
	teksti.z_index = 1  # aina kortin päällä
	teksti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teksti.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	teksti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teksti.add_theme_color_override("font_color", Color.WHITE)
	teksti.add_theme_color_override("font_outline_color", Color.BLACK)
	teksti.add_theme_constant_override("outline_size", 12)
	teksti.hide()
	return teksti

# Näyttää jokaisen pelaajan straffin noston jälkeen.
func _näytä_straffit(straffit: Array[String]) -> void:
	for i in pelaajat.size():
		var teksti: Label = pelaajat[i].get_node("Straffi")
		if straffit[i] == "" or straffit[i] == str(0):
			teksti.hide()
			continue
		teksti.text = straffit[i]
		teksti.add_theme_font_size_override("font_size", 48 if straffit[i].length() <= 3 else 26)
		teksti.show()

func _lopeta_peli() -> void:
	$Keskusta/Korttitaka.hide()
	_korosta_vuoro(-1)
	for nappi in nostonapit:
		nappi.disabled = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#TODO: Rules selections on mainmenu
	_aseta_pelaajat()
	maat = peli_säännöt_instanssi.alusta_maat()
	pakka = peli_säännöt_instanssi.luo_pakka()
	
	get_viewport().size_changed.connect(_asettele)

	for nappi in nostonapit:
		nappi.pressed.connect(_nosta_kortti)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
