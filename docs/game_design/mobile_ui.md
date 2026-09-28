# Mobile UI (Touch zuerst)

Regeln für HUD, Overlays und Navigation. Umsetzung: #174 (HUD/Layering), #162 (Zurück-Taste/Pause-Menü), #126 (Cleanup), #83 (`game_screen.dart` zerlegen). Priorität laut Entscheidung: **Handy, Touch zuerst**; Tastatur/Desktop ist Bonus.

---

## 1. Problem (Playtest)

- Das Hilfe-`?` (Flutter-Widget bei `bottom: 12, right: 12`) überlappt Aktions-/Welt-Wechsel-Button; ein Tap öffnet die Hilfe statt der Aktion.
- Das "Speichern & Beenden"-X sitzt oben rechts ohne Rückfrage.
- Die Zurück-Taste beendet das Spiel ohne Speichern (kein `PopScope`; `/game` per `context.go` geöffnet).
- Im Kampf liegen Halten, vier Modi und Welt-Wechsel in einer Reihe.

## 2. Layout-Regeln

1. **Daumenzonen:** Links unten Bewegung (Joystick), rechts unten Hauptaktion. Nichts anderes in diesen Zonen.
2. **Touch-Ziele:** ≥ 48 dp, Abstand ≥ 8 dp zwischen Zielen; kein Ziel überlappt ein anderes (Hoch-/Querformat, ab ~360×640 dp).
3. **Keine Widgets in den Ecken über dem Spielfeld.** Hilfe, Speichern, Einstellungen, Beenden liegen im **Pause-Menü**.
4. **Destruktive Aktionen** (Beenden) nie mit einem Tap, sondern im Pause-Menü mit Rückfrage.
5. **Ein Layout-/Layering-Mechanismus:** Eine zentrale Stelle entscheidet, welches Overlay Eingaben blockiert und wer bei "Zurück" zuerst schließt.
6. Alle Texte über `AppStrings` (de/en).

## 3. Zurück-Taste / Pause-Menü (#162)

`PopScope` im `GameScreen`, Reihenfolge:

1. Offenes Overlay/Menü schließen (Logik von `SpiritWorldGame.handleEscape`).
2. Sonst **Pause-Menü**: Fortsetzen, Speichern, Hilfe/Tastenbelegung, Einstellungen, "Speichern & Beenden" (mit Rückfrage).
3. Ein Beenden ohne Speichern gibt es nur bewusst über das Pause-Menü.

## 4. Kampf-HUD

- **Ein großer Halten-Button** in der rechten Daumenzone (Gebet).
- **Modus-Auswahl** räumlich getrennt (eigene Leiste/Rad am Rand), mit Mindestabstand zum Halten-Button; ein Tastendruck während des Haltens schaltet den Modus nicht um, ohne dass die Auswahl aktiv bedient wird.
- Der Welt-Wechsel liegt nicht neben dem Halten-Button.
- **Dämonentyp und -stärke** (`daemons_and_combat.md`) sind ohne Lesen erkennbar.

## 5. Overlays

Dialog, Gebäude-Menü, Look, Missionsliste, Keymap: einheitliche Basis (gleiche Ränder, Schließen-Geste, Sicherheitsabstände/SafeArea, Scroll bei kleinen Höhen). Jedes Overlay ist ein eigenes Widget in eigener Datei (Modularisierung #83).

## 6. Tests

Widget-Tests für Überlappung/Erreichbarkeit bei mindestens drei Bildschirmgrößen (klein, normal, Tablet) in Hoch- und Querformat.
