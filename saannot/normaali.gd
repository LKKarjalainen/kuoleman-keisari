extends RefCounted

const MAAT := ["hertta", "ruutu", "risti", "pata"]

func alusta_maat():
	return MAAT

func luo_pakka() -> Array[Dictionary]:
	var pakka: Array[Dictionary] = []
	for maa in MAAT:
		for arvo in range(2, 15):
			pakka.append({"maa": maa, "arvo": arvo, "kuva": "res://kortit/%s_%d.svg" % [maa, arvo]})
	for i in [1, 2]:
		pakka.append({"maa": "jokeri", "arvo": 0, "kuva": "res://kortit/jokeri_%d.svg" % i})
	pakka.shuffle()
	return pakka

# Palauttaa jokaiselle pelaajalle straffin paikan mukaan samassa järjestyksessä kuin pelaajien_kortit. 
func laske_straffit(vuoro: int, pelaajien_kortit: Array) -> Array[String]:
	var straffit: Array[String] = []
	var määrä := pelaajien_kortit.size()
	straffit.resize(määrä)
	straffit.fill("")

	var kortti = pelaajien_kortit[vuoro]
	var vasen := posmod(vuoro + 1, määrä)
	var oikea := posmod(vuoro - 1, määrä)
	var vasen_kortti = pelaajien_kortit[vasen] if vasen != vuoro else null
	var oikea_kortti = pelaajien_kortit[oikea] if oikea != vuoro else null

	# Jokeri: nostaja saa pöydän suurimman kortin arvon, muut saa omansa
	if kortti.arvo == 0:
		straffit[vuoro] = str(_suurin_arvo(pelaajien_kortit))
		return straffit

	# Ässä: jos naapurilla on ässä nostaja saa shotin.
	if kortti.arvo == 14:
		var vasen_ässä: bool = vasen_kortti != null and vasen_kortti.arvo == 14
		var oikea_ässä: bool = oikea_kortti != null and oikea_kortti.arvo == 14
		if vasen_ässä or oikea_ässä:
			straffit[vuoro] = "shotti"
			return straffit

	# Linkkaa: kuljetaan nostajasta kumpaankin suuntaan niin kauan kuin vierekkäiset kortit linkkaa
	var ketju: Array[int] = [vuoro]
	for suunta in [1, -1]:  # 1 = vasemmalle, -1 = oikealle
		var edellinen := vuoro
		var seuraava := posmod(vuoro + suunta, määrä)
		while seuraava not in ketju and _linkkaa(pelaajien_kortit[edellinen], pelaajien_kortit[seuraava]):
			ketju.append(seuraava)
			edellinen = seuraava
			seuraava = posmod(seuraava + suunta, määrä)

	if ketju.size() > 1:
		for i in ketju:
			straffit[i] = str(pelaajien_kortit[i].arvo)

	return straffit

func _linkkaa(a, b) -> bool:
	return a != null and b != null and (a.arvo == b.arvo or a.maa == b.maa)

# Suurimman kortin arvo pöydällä.
func _suurin_arvo(pelaajien_kortit: Array) -> int:
	var suurin := 0
	for k in pelaajien_kortit:
		if k != null and k.arvo > suurin:
			suurin = k.arvo
	return suurin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
