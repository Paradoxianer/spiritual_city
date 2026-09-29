# Mobile UI (Touch zuerst)

Regeln für HUD, Overlays und Navigation. Umsetzung: #174 (HUD/Layering), #162 (Zurück-Taste/Pause-Menü), #126 (Cleanup), #83 (`game_screen.dart` zerlegen). Priorität laut Entscheidung: **Handy, Touch zuerst**; Tastatur/Desktop ist Bonus.

---

## 1. Problem (Playtest)

- Das Hilfe-`?` (Flutter-Widget bei `bottom: 12, right: 12`) überlappte Aktions-/Welt-Wechsel-Button; ein Tap öffnete die Hilfe statt der Aktion.
- Das "Speichern & Beenden"-X saß oben rechts ohne Rückfrage.
- Die Zurück-Taste beendete das Spiel ohne Speichern (kein `PopScope`; `/game` per `context.go` geöffnet).
- Im Kampf liegen Halten, vier Modi und Welt-Wechsel in einer Reihe.

> **Status (#162):** Behoben. `PopScope` in `GameScreen` leitet Zurück/Escape in `SpiritWorldGame.handleEscape()` um (schließt zuerst offene Overlays, öffnet sonst das Pause-Menü, pausiert dabei die Engine). Die beiden Ecken-Buttons sind einem einzigen Pause-Button (`⏸️`, oben rechts) gewichen; Hilfe, Speichern und Speichern & Beenden (mit Rückfrage) liegen im `PauseMenuOverlay`. Offen bleibt das Kampf-HUD-Layout (§4, Teil von #174).

## 2. Layout-Regeln

1. **Daumenzonen:** Links unten Bewegung (Joystick), rechts unten Hauptaktion. Nichts anderes in diesen Zonen.
2. **Touch-Ziele:** ≥ 48 dp, Abstand ≥ 8 dp zwischen Zielen; kein Ziel überlappt ein anderes (Hoch-/Querformat, ab ~360×640 dp).
3. **Keine Widgets in den Ecken über dem Spielfeld, mit einer Ausnahme:** ein einzelner Pause-Button (oben rechts) als Einstieg ins Pause-Menü. Hilfe, Speichern, Einstellungen, Beenden liegen **im Pause-Menü**, nicht als eigene Ecken-Buttons.
4. **Destruktive Aktionen** (Beenden) nie mit einem Tap, sondern im Pause-Menü mit Rückfrage.
5. **Ein Layout-/Layering-Mechanismus:** Eine zentrale Stelle entscheidet, welches Overlay Eingaben blockiert und wer bei "Zurück" zuerst schließt.
6. Alle Texte über `AppStrings` (de/en).

## 3. Zurück-Taste / Pause-Menü (#162) — umgesetzt

`PopScope(canPop: false)` im `GameScreen` leitet Zurück/Escape an `SpiritWorldGame.handleEscape()` weiter, Reihenfolge:

1. Offenes Overlay/Menü schließen (Pause-Menü, Keymap, Dialog, Gebäude-Innenraum, Look, Missionsliste, Radial-Menü — in dieser Priorität).
2. Ist nichts davon offen, öffnet sich das **Pause-Menü** (`PauseMenuOverlay`): Fortsetzen, Speichern, Hilfe/Tastenbelegung, "Speichern & Beenden" (mit Rückfrage-Dialog).
3. Ein Beenden ohne Speichern gibt es nur bewusst über den Bestätigungs-Dialog im Pause-Menü.
4. Das Öffnen des Pause-Menüs pausiert die Flame-Engine (`pauseEngine()`); nichts bewegt sich mehr im Hintergrund.

Noch offen: Einstellungen-Eintrag im Pause-Menü (aktuell nicht enthalten, da `settings.title`/`settings.placeholder` im Spiel noch nicht existiert).

## 4. Kampf-HUD

- **Ein großer Halten-Button** in der rechten Daumenzone (Gebet).
- **Modus-Auswahl** räumlich getrennt (eigene Leiste/Rad am Rand), mit Mindestabstand zum Halten-Button; ein Tastendruck während des Haltens schaltet den Modus nicht um, ohne dass die Auswahl aktiv bedient wird.
- Der Welt-Wechsel liegt nicht neben dem Halten-Button.
- **Dämonentyp und -stärke** (`daemons_and_combat.md`) sind ohne Lesen erkennbar.

> **Teil-Status (#174):** Der Überlapp-Bug ist behoben. `SpiritWorldGame._modeRowMargin` wird jetzt aus der tatsächlichen Button-Geometrie hergeleitet (Halten-/Welt-Wechsel-Button-Radius + 8 dp Mindestabstand + Radius eines *ausgewählten* Modus-Buttons), statt eines festen `90`, der nur für die unselektierte Größe reichte. Da Liberation der Start-Modus ist, saß Modus-Button 0 im Normalfall (Abstand nicht an min/max geklemmt) mit seiner ausgewählten Kante direkt im Halten-Button – exakt das gemeldete "falscher Knopf beim Kämpfen". Geprüft für Breiten ≥ 360 dp (mobile_ui.md-Minimum): bei genau 360 dp bleibt noch ein 8 dp Abstand zum Halten-Button.
>
> **Noch offen:** Bei Breiten < 360 dp (außerhalb der offiziellen Mindestgröße) und bei eng gedrängten Modus-Buttons untereinander bleibt es beim reinen Reihen-Layout; das eigentliche "Leiste/Rad am Rand"-Redesign aus Punkt 2 oben ist nicht Teil dieser Änderung.

## 5. Overlays

Dialog, Gebäude-Menü, Look, Missionsliste, Keymap: einheitliche Basis (gleiche Ränder, Schließen-Geste, Sicherheitsabstände/SafeArea, Scroll bei kleinen Höhen). Jedes Overlay ist ein eigenes Widget in eigener Datei (Modularisierung #83).

## 6. Tests

Widget-Tests für Überlappung/Erreichbarkeit bei mindestens drei Bildschirmgrößen (klein, normal, Tablet) in Hoch- und Querformat.
