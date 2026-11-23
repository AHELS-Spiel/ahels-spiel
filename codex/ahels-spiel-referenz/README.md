# AHELS Arena V5.2

Ein Pixel-Plattform-Fighter mit 24 Klassenfiguren und zwei Lehrern. Treffer erhöhen den Rückstoß. Wer über den Rand fällt, verliert einen Versuch.

## Starten

Entpackt das ZIP vollständig und startet die Datei für euer System.

- **Windows (x86-64)** · `AHELS-Arena.exe`
- **Linux (x86-64)** · `AHELS-Arena.x86_64`
- **macOS (Intel und Apple Silicon)** · `AHELS Arena.app`

Die macOS-App ist ad hoc signiert. Je nach Sicherheitseinstellung braucht sie beim ersten Start eine Freigabe unter **Datenschutz & Sicherheit**.

## Modi

- **Klassenduelle.** Spielt gegen Stefan in der Aula, Lukas in der Werkstatt oder Valentin im Computerraum. Auf den Duellkarten könnt ihr ihre Stimme anhören, wenn die Ausgabe die Aufnahme enthält. Im Kampf reagieren die Einwürfe auf den Ring-out von Stefan, den Block von Lukas und den Projektiltreffer von Valentin.
- **Solo-Kampagne.** Herr Haidenthaler erklärt im Turnsaal alles auf seine Weise. Die Tafel zeigt die richtigen Tasten. Danach folgen Pausenhof, Computerraum, Aula und das Finale gegen Herrn Grimmer. Springt über die Regalwelle, weicht den sichtbaren Kreidelinien aus und nutzt die Pause zum Kontern.
- **Tutorial.** Die fünf Übungen aus dem Turnsaal sind auch direkt vom Hauptmenü aus erreichbar.
- **Versus.** Spielt zu zweit am PC oder gegen die CPU. Wählt Figuren, Arena und auf Wunsch unter **Regeln** ein bis fünf Versuche, das Zeitlimit und die CPU-Stufe. Bei Zeitablauf zählen die verbleibenden Versuche, dann der niedrigere Rückstoßwert. Eine Revanche übernimmt dieselbe Arena und dieselben Regeln.
- **Training.** Übt mit einer beliebigen Klassenfigur im Turnsaal gegen ein stehendes, springendes oder CPU-gesteuertes Gegenüber. Im Pausenmenü könnt ihr unter anderem den Rückstoßwert beim nächsten Reset festlegen. **R** setzt die Übung zurück, **F2** ändert das Gegnerverhalten.
- **Turnier.** Spielt vier Duelle auf einer festen oder ausgelosten Route. Vor jeder Runde seht ihr das Duell und den Fortschritt. Eine Wiederholung behält Arena, Gegner und Schwierigkeit. Es gibt drei Turnierstufen.
- **Überleben.** Ihr habt drei Versuche für fünf Wellen. Restversuche und Rückstoßwert gehen in die nächste Welle mit. Jede CPU-Figur hat einen Versuch. Euer Bestwert wird auf dem Gerät gespeichert.
- **Bossprobe.** Nach dem Kampagnensieg könnt ihr das Bibliotheksfinale direkt üben.
- **Netzwerk.** Wählt eure Figuren vor dem Verbinden. Der Host wählt die Arena und startet. Nach dem Ergebnis kann der Gast Bereitschaft für eine Revanche melden.
- **Ziele.** Zeigt die auf diesem Gerät erreichten Spielziele.

Pausenhof, Computerraum, Bibliothek, Werkstatt, Dachterrasse, Aula und Physiksaal sind Kampfarenen. Versus und Überleben bieten zusätzlich Zufallsauswahl. Freies Training und Tutorial finden im Turnsaal statt.

### Sechs Moves pro Figur

Öffnet **Moves ansehen** in der Figurenwahl oder **Moves** in der Trainingspause. Angriff am Boden, beim Laufen und in der Luft ergibt jeweils eine andere Aktion. Drückt **Unten und Angriff** gleichzeitig für den Beinfeger. Für einen Ketten-Finisher drückt ihr **Spezial**, solange nach einem Treffer das Finisher-Fenster im HUD steht. Der Finisher und die reguläre Spezialfähigkeit teilen sich die Abklingzeit.

Wechselt zwischen den Angriffen. Wiederholte Treffer mit demselben Grundangriff verlieren an Kraft. Jede Figur hat einen Grundangriff mit zusätzlicher Reichweite und zusätzlichem Schaden.

Die Musik wechselt bei einem knappen Duell mit letzten Versuchen oder ablaufender Uhr. Mit **F3** spielt ihr im Kampf die Stimme der eigenen Figur ab. Hat diese keine Aufnahme, spielt die Stimme des Gegenübers. Bei zwei verschiedenen verfügbaren Stimmen spielt **F4** die zweite Stimme. Die Tasten stehen im Kampf unten links. Belegte Tasten werden für vorhandene Steuerungseinstellungen übersprungen. In den Einstellungen könnt ihr die Klassenstimmen aus- und einschalten.

### Standardsteuerung

| Aktion | Spieler 1 / Netzwerkspieler | Spieler 2 lokal | Controller |
| --- | --- | --- | --- |
| Laufen | A / D | ← / → | Linker Stick oder Steuerkreuz |
| Springen / Doppelsprung | W / Leertaste | ↑ | A |
| Angreifen | F | J | X |
| Spezialfähigkeit | G | K | Y |
| Ausweichen | Q / Umschalt | L | B / RB |
| Durch obere Plattform fallen | S | ↓ | Stick oder Steuerkreuz ↓ |

**Esc** oder **Start** öffnet Pause. In Menüs bestätigt ihr mit Enter oder A und geht mit Esc oder B zurück. **F11** schaltet Vollbild um. In **Einstellungen** findet ihr getrennte Lautstärkeregler, Stummschaltung, reduzierte Effekte und die Steuerungsübersicht. Dort könnt ihr beide Tastaturlayouts ändern oder zurücksetzen. Die Tutorial-Tafel verwendet die aktiven Tasten. Einstellungen und Spielfortschritt werden beim Spielen gespeichert.

### Netzwerk einrichten

Im LAN verwendet ihr die im Menü angezeigte Host-Adresse und denselben UDP-Port. Der Standardport ist **24738/UDP**. Über das Internet benötigt der Host eine erreichbare IP-Adresse oder einen DNS-Namen und gegebenenfalls eine UDP-Portweiterleitung. Alternativ geht ein gemeinsames virtuelles Netzwerk. Für Netzwerkduelle sind V5, V5.1 und V5.2 kompatibel. Die Stimmtasten spielen den Clip auf dem eigenen PC ab. In der Netzwerkpause läuft die Runde für das Gegenüber weiter.

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

Startet für einen lokalen Netzwerktest `tests/network_flows.gd` in zwei Prozessen mit den Argumenten `-- host` und `-- guest`. Die Lizenztexte liegen in den Desktop-ZIPs unter `Lizenzen/` und die Schriftlizenzen im Repository unter `assets/fonts/`.
