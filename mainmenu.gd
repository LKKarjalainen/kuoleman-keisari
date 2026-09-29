extends Control

const PELAAJIA_VÄHINTÄÄN := 1
const PELAAJIA_ENINTÄÄN := 20

var peli = preload("res://game.tscn")
var pelaajien_määrä := 1

func _aloita_peli() -> void:
	# Puhelimen selaimessa peli koko näytölle ja näyttö päälle koko pelin ajaksi.
	# Koko näytön pyyntö toimii selaimessa vain napin painalluksen seurauksena.
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_pidä_näyttö_päällä()

	var peli_instanssi = peli.instantiate()
	peli_instanssi.pelaajien_määrä = pelaajien_määrä
	get_tree().change_scene_to_node(peli_instanssi)

func _muuta_pelaajien_määrää(muutos: int) -> void:
	pelaajien_määrä = clampi(pelaajien_määrä + muutos, PELAAJIA_VÄHINTÄÄN, PELAAJIA_ENINTÄÄN)
	%Pelaajamäärä.text = str(pelaajien_määrä)
	%Vähemmän.disabled = pelaajien_määrä <= PELAAJIA_VÄHINTÄÄN
	%Enemmän.disabled = pelaajien_määrä >= PELAAJIA_ENINTÄÄN

func _pidä_näyttö_päällä() -> void:
	JavaScriptBridge.eval("""
		if (!window.kkWakeLock) {
			window.kkWakeLock = true;
			const pyyda = () => {
				if ('wakeLock' in navigator && document.visibilityState === 'visible') {
					navigator.wakeLock.request('screen').catch(() => {});
				}
			};
			document.addEventListener('visibilitychange', pyyda);
			pyyda();
		}
	""")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Aloitapeli.pressed.connect(_aloita_peli)
	%Vähemmän.pressed.connect(_muuta_pelaajien_määrää.bind(-1))
	%Enemmän.pressed.connect(_muuta_pelaajien_määrää.bind(1))
	_muuta_pelaajien_määrää(0)
