# AHELS Arena V5.5

Ein Pixel-Plattform-Fighter mit 24 Klassenfiguren und zwei Lehrern. Treffer erhöhen den Rückstoß. Wer über den Rand fällt, verliert einen Versuch.

## Starten

Entpackt das ZIP vollständig und startet die Datei für euer System.

- **Windows (x86-64)** · `AHELS-Arena.exe`
- **Linux (x86-64)** · `AHELS-Arena.x86_64`
- **macOS (Intel und Apple Silicon)** · `AHELS Arena.app`

Die macOS-App ist ad hoc signiert. Je nach Sicherheitseinstellung braucht sie beim ersten Start eine Freigabe unter **Datenschutz & Sicherheit**.

## Modi

- **Klassenduelle.** Spielt gegen Stefan in der Aula, Lukas in der Werkstatt oder Valentin im Computerraum. Auf den Duellkarten könnt ihr die Aufnahmen anhören. Jeder weitere Klick spielt den nächsten Clip der Figur.
- **Solo-Kampagne.** Herr Haidenthaler erklärt im Turnsaal alles auf seine Weise. Die Tafel zeigt die richtigen Tasten. Danach folgen Pausenhof, Computerraum, Aula und das Finale gegen Herrn Grimmer. Springt über die Regalwelle, weicht den sichtbaren Kreidelinien aus und nutzt die Pause zum Kontern.
- **Tutorial.** Die fünf Übungen aus dem Turnsaal sind auch direkt vom Hauptmenü aus erreichbar.
- **Versus.** Wechselt über **Modus** zwischen CPU, **2 am PC** und **4 am PC**. Wählt für jeden Platz eine Figur. Unter **Regeln** könnt ihr die Versuche, das Zeitlimit und im CPU-Duell die Schwierigkeit einstellen. In Gruppenkämpfen spielen alle gegeneinander. Die letzte Figur gewinnt. Bei Zeitablauf zählen die verbleibenden Versuche und dann der niedrigere Rückstoßwert.
- **Training.** Übt mit einer beliebigen Klassenfigur im Turnsaal gegen ein stehendes, springendes oder CPU-gesteuertes Gegenüber. Im Pausenmenü könnt ihr unter anderem den Rückstoßwert beim nächsten Reset festlegen. **R** setzt die Übung zurück, **F2** ändert das Gegnerverhalten.
- **Turnier.** Spielt vier Duelle auf einer festen oder ausgelosten Route. Vor jeder Runde seht ihr das Duell und den Fortschritt. Eine Wiederholung behält Arena, Gegner und Schwierigkeit. Es gibt drei Turnierstufen.
- **Überleben.** Ihr habt drei Versuche für fünf Wellen. Restversuche und Rückstoßwert gehen in die nächste Welle mit. Jede CPU-Figur hat einen Versuch. Euer Bestwert wird auf dem Gerät gespeichert.
- **Bossprobe.** Nach dem Kampagnensieg könnt ihr das Bibliotheksfinale direkt üben.
- **Netzwerk.** Wählt eure Figuren vor dem Verbinden. Der Host wählt die Arena und öffnet die Lobby für zwei, drei oder vier Personen. Sobald alle Plätze besetzt sind, kann der Host die Runde starten. Nach dem Ergebnis können die Gäste eine Revanche anfordern.
- **Ziele.** Zeigt die auf diesem Gerät erreichten Spielziele.

Pausenhof, Computerraum, Bibliothek, Werkstatt, Dachterrasse, Aula und Physiksaal sind Kampfarenen. Versus und Überleben bieten zusätzlich Zufallsauswahl. Freies Training und Tutorial finden im Turnsaal statt.

### Sechs Moves pro Figur

Öffnet **Moves ansehen** in der Figurenwahl oder **Moves** in der Trainingspause. Angriff am Boden, beim Laufen und in der Luft ergibt jeweils eine andere Aktion. Drückt **Unten und Angriff** gleichzeitig für den Beinfeger. Für einen Ketten-Finisher drückt ihr **Spezial**, solange nach einem Treffer das Finisher-Fenster im HUD steht. Der Finisher und die reguläre Spezialfähigkeit teilen sich die Abklingzeit.

Wechselt zwischen den Angriffen. Wiederholte Treffer mit demselben Grundangriff verlieren an Kraft. Jede Figur hat einen Grundangriff mit zusätzlicher Reichweite und zusätzlichem Schaden.

Die Musik wechselt bei einem knappen Duell mit letzten Versuchen oder ablaufender Uhr.

### Klassenstimmen

Mit Sprachdateien startet jede Runde mit „Servas!“, auch Tutorial, Training und Netzwerk. Wenn jemand einen Versuch verliert, kommt Stefans Knockout-Satz. Bei Lukas (Figur 11) kommt sein undeutlicher Einwurf, ersatzweise Stefan. Auch Trainingsstürze lösen eine Reaktion aus. Weitere Einwürfe wechseln bei Treffern, Spezialaktionen und zwischen Aktionen. Lukas reagiert auch auf Blocks und Valentin auf Projektiltreffer.

Mit **F3** spielt ihr im Kampf die Stimme der eigenen Figur ab, sofern sie eine Aufnahme hat. Sonst spielt die Stimme des Gegenübers, wenn eine verfügbar ist. Bei zwei verschiedenen Stimmen spielt **F4** die zweite. Mehrmaliges Drücken spielt die Ausschnitte der zugehörigen Figur der Reihe nach ab. Die Tasten stehen im Kampf unten links. Belegte Tasten werden für vorhandene Steuerungseinstellungen übersprungen. Die Einstellung **Klassenstimmen** gilt für automatische Einwürfe, Stimmtasten und Hörproben.

### Standardsteuerung

| Aktion | Spieler 1 / Netzwerk | Spieler 2 | Spieler 3 | Spieler 4 (Ziffernblock) | Controller |
| --- | --- | --- | --- | --- | --- |
| Laufen | A / D | ← / → | T / U | 4 / 6 | Linker Stick oder Steuerkreuz |
| Springen / Doppelsprung | W / Leertaste | ↑ | Y | 8 | A |
| Angreifen | F | J | V | 7 | X |
| Spezialfähigkeit | G | K | N | 9 | Y |
| Ausweichen | Q / Umschalt | L | B | 0 | B / RB |
| Durch obere Plattform fallen | S | ↓ | M | 5 | Stick oder Steuerkreuz ↓ |

**Esc** oder **Start** öffnet Pause. In Menüs bestätigt ihr mit Enter oder A und geht mit Esc oder B zurück. **F11** schaltet Vollbild um. Unter **Einstellungen → Steuerungsübersicht** könnt ihr die Tastaturlayouts aller vier Plätze ändern. Verbundene Controller belegen die Plätze der Reihe nach. Alle Einstellungen und der Spielfortschritt werden gespeichert.

### Netzwerk einrichten

Installiert für Netzwerkduelle auf jedem Rechner **V5.5**. Der Host wählt die Gruppengröße vor dem Hosten. Die Gäste geben die angezeigte Host-Adresse und denselben UDP-Port ein. Der Standardport ist **24738/UDP**. Über das Internet benötigt der Host eine erreichbare IP-Adresse oder einen DNS-Namen und gegebenenfalls eine UDP-Portweiterleitung. Alternativ geht ein gemeinsames virtuelles Netzwerk. Verlässt jemand eine laufende Partie, kehren die Übrigen in die Lobby zurück und können einen Platz nachbesetzen.

## Entwickeln und exportieren

Öffnet `project.godot` in **Godot 4.6.3** und drückt **F5**. Das Projekt verwendet GDScript und den Compatibility-Renderer. Die Godot-Exportvorlagen für dieselbe Version und die drei Presets in `export_presets.cfg` erzeugen die Desktop-Ausgaben.

| Datei | Zuständig |
| --- | --- |
| `src/main.gd` | Spielmodi, Menüs, Eingaben, Einstellungen und Audio |
| `src/bout.gd` | Kampfregeln, Bewegung, Treffer, CPU und Übungen |
| `src/arena_view.gd` | Pixel-Darstellung, HUD, Effekte und Tutorial-Tafel |
| `src/duel_link.gd` | LAN-Lobby, Rollen, Start und Synchronisierung |
| `data/arenas.json` | Arenen, Plattformen, Startpositionen und Vorschautexte |
| `data/fighters.json` | Figuren, Fähigkeiten und Spielwerte |
| `src/arena_moves.gd` und `data/move_sets.json` | Angriffsdaten, Finisher und Move-Liste pro Figur |

`python art/make_assets.py` erzeugt die Pixelbilder und Soundeffekte mit Python und Pillow. `python art/soundtrack.py` rendert die vier Instrumentaltracks mit NumPy und FFmpeg. Die beiden Felix- und Jonas-Figuren sind an der Figurennummer erkennbar.

Die optionalen Klassensprachclips lädt das Spiel aus `assets/class_voice/`. Die Dateinamen stehen in `src/catalog.gd`. Das Verzeichnis ist in Git ignoriert. Das Projekt startet auch ohne diese Dateien.

Nach `godot --headless --editor --import` lassen sich die Tests aus dem Projektordner ausführen. Verwendet pro Test ein frisches Profil.

```sh
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://tests/core_flows.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://tests/combat_moves.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://tests/class_duels.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://tests/playthroughs.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://tests/arena_flows.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://tests/controller_flows.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://tests/playthroughs.gd -- tournament
```

Startet für einen lokalen Netzwerktest `tests/network_flows.gd` in zwei Prozessen mit den Argumenten `-- host` und `-- guest`. Für vier Prozesse verwendet ihr `-- host4` und je einmal `-- guest4-1`, `-- guest4-2` und `-- guest4-3`. Die Lizenztexte liegen in den Desktop-ZIPs unter `Lizenzen/` und die Schriftlizenzen im Repository unter `assets/fonts/`.
