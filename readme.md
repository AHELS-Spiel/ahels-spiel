# AHELS-Spiel

Wir entwickeln als Klasse einen eigenen **2D-Plattform-Fighter im Pixelstil**. Super Smash Bros. ist unsere Inspiration fürs Genre. Unsere Figuren, Arenen und Fähigkeiten entstehen aus Ideen der Klasse. Geplant sind 24 Mitwirkende, vier Schulstunden pro Woche plus Zeit zu Hause und eine spielbare Version bis zum Ende des Schuljahres.

## Spielidee

Auf Plattformen treten die Figuren in kurzen Runden gegeneinander an. Als erste Spielmechanik könnten wir Laufen, Springen und einen Angriff mit Rückstoß ausprobieren. In diesem Vorschlag verliert die Runde, wer aus der Arena fällt. Die genauen Regeln und Siegbedingungen entscheiden wir nach dem ersten Spieltest.

| Figuren | Geplante Rolle |
| --- | --- |
| Schülerinnen und Schüler | Die ganze Klasse kommt als Pixel-Figuren vor. Die Figuren sollen ihren echten Vorbildern ähneln. Die Gruppe schlägt Stärken vor, die zu echten Talenten oder Eigenschaften passen. Welche Figuren spielbar sind und welche als Nebenfiguren vorkommen, entscheiden wir gemeinsam. |
| Erste Lehrerfigur | Führt durchs Tutorial, macht die Spielaktionen vor und gibt Tipps in Sprechblasen. Die Spielenden steuern dabei eine selbst ausgewählte Schülerfigur. |
| Zweite Lehrerfigur | Tritt als Endboss auf. Wie die Begegnung abläuft und wie man sie gewinnt, ist offen. |

Das Spiel soll als Desktop-Spiel auf **Windows, macOS und Linux** laufen. Zum Start bauen wir das Tutorial als Einzelspielermodus. Später wollen wir auch an mehreren PCs im selben Netzwerk und übers Internet zusammenspielen können.

## Erster Meilenstein – ein spielbares Tutorial

Der Prototyp ist bereit für den ersten Klassentest, wenn Folgendes funktioniert.

- [ ] Zu Beginn kann man zwischen mindestens zwei Platzhalterfiguren wählen.
- [ ] Die Lehrerfigur zeigt in einer kleinen Übungsarena vor, wie man sich bewegt, springt und einen Angriff ausführt. Sprechblasen erklären jeweils den nächsten Schritt.
- [ ] Man kann die Schritte mit der gewählten Figur nachmachen. Das Spiel erkennt, wenn ein Schritt geschafft ist.
- [ ] Nach der letzten Übung zeigt das Spiel an, dass das Tutorial abgeschlossen ist. Man kann es erneut starten.

Für diesen Prototyp reichen Platzhaltergrafiken. Bevor wir echte Namen oder erkennbare Darstellungen im öffentlichen Repo veröffentlichen, klären wir das mit den betroffenen Personen.

### Was danach kommt

1. **Erste Arena.** Eine vollständige Runde ausprobieren und anhand der Spieltests die Regeln und die Steuerung anpassen.
2. **Figuren und Endboss.** Die Pixel-Figuren und ihre Stärken nach und nach ergänzen. Eine eigene Boss-Begegnung ausarbeiten.
3. **Mehrspieler.** Zuerst eine Runde zu zweit auf zwei PCs im selben Netzwerk testen. Darauf aufbauend das Spielen über das Internet ausprobieren.
4. **Abgabe.** Spielversionen für die drei Zielsysteme bauen und auf mehreren Rechnern testen.

## Ideen sammeln

Jede Person erstellt einen eigenen Unterordner in [`ideen/`](ideen/) und schreibt dort auf, was ihr fürs Spiel einfällt. Figuren, Stärken, Arenen, der Boss und das Tutorial sind gute Startpunkte. Später setzen wir uns zusammen, besprechen die Vorschläge und entscheiden, welche zum Plattform-Fighter passen und welche wir umsetzen.

<details>
<summary>Klassen-Insider aus dem bisherigen README</summary>

> immer schon an wagner haten

Ob und in welcher Form der Insider ins Spiel passt, besprechen wir gemeinsam.

</details>

## Auf GitHub mitarbeiten

Die Projektleitung verwaltet das Repository. Das Team `Klasse` bekommt die Rolle `Write`, damit alle auf Arbeitsbranches beitragen können. Für `main` braucht jede Änderung einen Pull Request und die Freigabe einer zweiten Person. Der Branch ist gegen Löschen und Force-Pushes geschützt.

Öffne ein Terminal in dem Ordner, in dem du das Projekt ablegen willst. Verwende für `dein-name` deinen eigenen Ordner- und Branchnamen.

```sh
git clone https://github.com/AHELS-Spiel/ahels-spiel.git
cd ahels-spiel
git switch -c idee/dein-name
```

Erstelle deinen Ordner in `ideen/` und schreib deine Vorschläge zum Beispiel in `ideen/dein-name/ideen.md`. Lade danach deinen Branch hoch.

```sh
git add ideen/dein-name/
git commit -m "Spielideen ergänzen"
git push -u origin idee/dein-name
```

Öffne auf GitHub einen Pull Request von `idee/dein-name` nach `main`. Schreib kurz dazu, was du ergänzt hast, und bitte eine zweite Person um einen Review. Für Programmieraufgaben funktioniert es genauso, mit einem eigenen Branch pro Aufgabe.

## Technik und offene Entscheidungen

- **Engine und Sprache.** Die Klasse kennt C, C++ und C#. Ein Vorschlag ist, Godot mit C# für den Tutorial-Prototyp auszuprobieren. Vor der Entscheidung prüfen wir, ob alle damit arbeiten können und ob sich die Desktop-Versionen auf den Zielsystemen starten lassen.
- **Arbeitsplätze.** Wir entwickeln vor allem auf eigenen Geräten. Schul-PCs sollen bei Bedarf ebenfalls nutzbar sein.
- **KI-Unterstützung.** KI kann beim Programmieren, Erklären und Fehlersuchen helfen. Wer eine Änderung einreicht, prüft und testet den Code selbst und kann erklären, wie er funktioniert.
- **Teamaufteilung.** Feste Teams sind noch offen. Für den ersten Prototyp können kleine Gruppen Figurenwahl, Steuerung, Übungsarena und Sprechblasen übernehmen.
