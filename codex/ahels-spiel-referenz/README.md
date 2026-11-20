# AHELS Arena

Eine spielbare Referenzversion für das Klassenspiel. In diesem 2D-Plattform-Fighter kämpft ihr in mehreren Schul-Arenen und versucht, eure Gegner aus der Arena zu befördern. Treffer erhöhen den Rückstoß. Im Versus haben beide Figuren drei Versuche.

## Starten

Die exportierte Desktop-Version startet über `AHELS-Arena.exe` auf Windows oder `AHELS-Arena.x86_64` auf Linux. Auf macOS entpackt ihr das Archiv und öffnet **AHELS Arena.app**. Der macOS-Build ist ad hoc signiert und nicht notarisiert. macOS kann beim ersten Start verlangen, dass ihr die App unter **Datenschutz & Sicherheit** freigebt.

Für die Entwicklung den Ordner in **Godot 4.6.3** über `project.godot` importieren und **F5** drücken. Das Projekt verwendet GDScript und den Compatibility-Renderer. Bei der Engine-Wahl für das Klassenprojekt bleibt Godot mit C# eine Option. Godot kann GDScript und C# im selben Projekt verwenden.

## Spielmodi

- **Solo-Kampagne.** Wählt eine Figur. Herr Haidenthaler macht die Übungen verdreht vor, die Turnsaal-Tafel zeigt die richtigen Tasten. Danach geht es durch Pausenhof und Computerraum zum Finale gegen Herrn Grimmer. Springt über seine angekündigte Regalwelle und nutzt die Pause danach.
- **Versus.** Zwei Personen am selben PC oder eine Person gegen die CPU. Figuren und Arena wählt ihr vor der Runde. Bei Ablauf der Uhr zählen zuerst die verbleibenden Versuche, dann der niedrigere Rückstoßwert.
- **Netzwerk.** Zwei Personen auf unterschiedlichen PCs. Eine Person startet den Host, die andere nutzt die Host-Adresse und den gleichen UDP-Port. Beide wählen ihre Figur vor dem Verbinden. Der Host wählt die Arena und startet die Runde.

### Steuerung

| Aktion | Spieler 1 / Netzwerkspieler | Spieler 2 lokal | Controller |
| --- | --- | --- | --- |
| Laufen | A / D | ← / → | Linker Stick oder Steuerkreuz |
| Springen / Doppelsprung | W / Leertaste | ↑ | A |
| Angreifen | F | J | X |
| Spezialfähigkeit | G | K | Y |
| Ausweichen | Q / Umschalt | L | B / RB |
| Durch obere Plattform fallen | S | ↓ | Stick nach unten |

**Esc** oder **Start** öffnet das Pausenmenü. **F11** schaltet Vollbild um.

### Netzwerk einrichten

Im selben Netzwerk nutzt ihr die LAN-Adresse, die im Menü angezeigt wird. Der Standardport ist **24738/UDP**. Im Internet muss der Host über eine erreichbare IP oder einen DNS-Namen an diesem UDP-Port erreichbar sein. Je nach Anschluss ist dafür eine Portweiterleitung nötig. Alternativ könnt ihr ein gemeinsames virtuelles Netzwerk nutzen und mit dessen Host-Adresse beitreten. Beide PCs brauchen dieselbe Spielversion. Der Host berechnet die Runde und synchronisiert sie mit dem Gast.

## Figuren bearbeiten

`data/fighters.json` enthält Anzeigenamen, Stärken und Werte für alle 24 auswählbaren Figuren und die beiden Lehrerfiguren. Die Nummern 01–18 folgen den gelieferten Portraits, 19–24 sind Ergänzungen für den Vergleichsbuild. Namen und Stärken können angepasst werden. Die Pixel-Grafiken sind in `assets/pixel/` gespeichert. Die mitgelieferten Werkzeuge erzeugen sie mit Python und Pillow.

```sh
python art/make_assets.py
```

Die Schriften bringen ihre Lizenztexte unter `assets/fonts/` mit.

## Orientierung im Code

| Datei | Zuständig |
| --- | --- |
| `src/main.gd` | Menüs, Steuerung, Kampagne und Audio |
| `src/bout.gd` | Bewegung, Treffer, CPU, Übungen und Spielregeln |
| `src/arena_view.gd` | Arenen, Spielfiguren, Effekte und Sprechblasen |
| `src/duel_link.gd` | Host, Beitritt, Eingaben und Synchronisierung |
| `data/arenas.json` | Plattformen und Startpositionen |

Die drei Exportziele sind in `export_presets.cfg` eingerichtet. Installiert in Godot die Export-Templates für dieselbe Version und wählt unter **Projekt → Exportieren** das gewünschte Ziel.
