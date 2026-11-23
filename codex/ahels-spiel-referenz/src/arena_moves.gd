class_name ArenaMoves
extends RefCounted

const KEYS: Array[String] = ["normal", "rush", "sweep", "air", "signature", "finisher"]
const OPENERS: Array[String] = ["normal", "rush", "sweep", "air"]
const TITLES := {
	"normal": "Schneller Treffer",
	"rush": "Laufangriff",
	"sweep": "Beinfeger",
	"air": "Luftschlag",
	"signature": "Spezialfähigkeit",
	"finisher": "Ketten-Finisher",
}
const PURPOSE := {
	"normal": "Schnell auf kurze Distanz. Öffnet bei einem Treffer den Finisher.",
	"rush": "Überbrückt Distanz. Beim Verfehlen bleibt kurz Zeit für einen Konter.",
	"sweep": "Hebt Gegner aus. Funktioniert gegen Ziele auf Bodenhöhe.",
	"air": "Trifft aus der Luft auch leicht unterhalb der eigenen Figur.",
	"finisher": "Nach einem Treffer kurz verfügbar. Starker Rückstoß, lädt wie Spezial neu.",
}
const CHAIN_TIME := 0.54
const STALE_TIME := 4.5

# Zeit in Sekunden, Reichweiten in Arenapixeln. Rückstoß und Höhe sind Faktoren.
const ATTACKS := {
	"normal": {"lock": 0.26, "windup": 0.08, "reach": 82.0, "height": 50.0,
		"power": 8.0, "push": 0.70, "lift": 0.80, "fx": "slash"},
	"rush": {"lock": 0.44, "windup": 0.13, "reach": 102.0, "height": 52.0,
		"power": 12.0, "push": 1.02, "lift": 0.85, "fx": "rush"},
	"sweep": {"lock": 0.32, "windup": 0.10, "reach": 95.0, "height": 30.0,
		"power": 10.0, "push": 0.56, "lift": 1.48, "fx": "sweep"},
	"air": {"lock": 0.31, "windup": 0.10, "reach": 93.0, "height": 76.0,
		"power": 10.0, "push": 0.90, "lift": 1.04, "fx": "air"},
	"finisher": {"lock": 0.52, "windup": 0.10, "reach": 146.0, "height": 95.0,
		"power": 18.0, "push": 1.24, "lift": 1.12, "fx": "combo"},
}


static func move_name(profile: Dictionary, move: String) -> String:
	if move == "signature":
		return profile["ability"]
	return profile["moves"].get(move, TITLES[move])


static func repetition_scale(hits: int) -> float:
	return maxf(0.52, 1.0 - float(hits) * 0.16)
