# Kern-Loop & Spielspaß (Retention)

Dieses Dokument beschreibt, **warum** der Spielspaß bisher nach einiger Zeit verloren ging und **wie** wir ihn dauerhaft hoch halten. Es ist die Klammer für die übrigen Dokumente in diesem Ordner. Umsetzung und Reihenfolge: Epic #183.

**Prinzip:** "Keep it simple but elegant". Werte in diesem Dokument sind **Startwerte** und werden per Playtest justiert (zentral in `GameBalance`, #83).

---

## 1. Befund aus dem Playtest

| Beobachtung | Ursache (Ist-Stand) | Gegenmaßnahme |
| :--- | :--- | :--- |
| Aktionen wiederholen sich ewig | Optimale Folge ist immer gleich (2× Seelsorge, 5× Bibellesen, Bekehrung), #171; Loop "beten → Glauben sammeln → kämpfen → zurück" ohne Entscheidungen | Interaktions-Varianz (#171), Investitions-Aktionen (#179) |
| Fortschritt nicht sichtbar | Bekehrte NPCs und befreite Zellen sind Zähler; `isConverted` liefert nur kleinen Zellen-Puls | Gemeinde mit Rollen (#181), Aura sichtbar (#180), Stadtteil-Etappen (§3) |
| Dämonen nicht unterscheidbar | `DaemonModel` hat nur ein Energie-Feld; Modi sind Zahlenmodifikatoren | Dämonen-Typen & Kombos (#178) |
| Stufen bringen nichts Neues | Upgrade = `+0.1` Multiplikator je Level, Kosten `1.5^Level` | Fähigkeiten pro Stufe (#179) |
| Erkunden langweilig | Alle Häuser gleich, keine Innenräume, wenig Grafik | Distrikt-Identität & Innenräume (#182) |
| UI unspielbar (Handy) | Überlappende Buttons, Zurück-Taste beendet das Spiel | Touch-first HUD (#174, #162), `mobile_ui.md` |
| Ziel unerreichbar weit weg | Sieg = alle NPCs im Radius 690 Zellen Christen + alle Zellen positiv; der Check hat zudem Fehler (#176) | Stadtteil-Etappen (§3), #169 |

---

## 2. Design-Säulen

1. **Jede Handlung zeigt ein Ergebnis.** Sichtbar, hörbar, zählbar (Toast, Partikel, Sound). Keine "stillen" Zähler.
2. **Zwei Welten, ein Kreislauf.** Was in der realen Welt geschieht, ändert den Kampf in der unsichtbaren Welt – und umgekehrt (`npc_influence.md`).
3. **Entscheidungen statt Routine.** Es gibt nie *die eine* richtige Aktion (abnehmende Erträge, Bedürfnisse, Schwächen, Kombos).
4. **Stufen schalten Neues frei.** Qualitativ (neue Fähigkeit) vor quantitativ (+10 %) – siehe `progression_and_unlocks.md`.
5. **Erkunden lohnt sich.** Orte sind unterscheidbar und haben etwas zu entdecken (`exploration.md`).
6. **Kurze Runden, klare Etappen.** Eine Session (ca. 10–15 Min.) hat ein erreichbares Ziel und einen natürlichen Haltepunkt.

---

## 3. Stadtteile als Etappenziele

Statt nur "die ganze Stadt gewinnen" gibt es **Stadtteile** (Distrikte, vgl. `DistrictSelector`) als Zwischenziele.

- **Erweckungs-Schwelle** je Stadtteil: Anteil bekehrter NPCs **und** Anteil positiver Zellen müssen jeweils einen Wert erreichen (Startwert: 50 % NPCs, 60 % Zellen).
- Erreichen löst aus: Fanfare, Toast "Erweckung in <Stadtteil>", sichtbarer Wechsel (Aura/Farbe des Stadtteils), **Freischaltung** (z. B. erste Erweckung schaltet Predigen frei, #172; weitere: permanenter Gebietseffekt, Rolle in der Gemeinde).
- Der Gesamtstadt-Sieg (#143) bleibt Endziel; er ergibt sich aus allen Stadtteilen und ersetzt den bisherigen Radius-Check (#176).
- Voraussetzung: ein zentraler NPC-/Zellzustand, der unabhängig vom Chunk-Laden zählt (#170).

---

## 4. Rhythmus einer Session (Ziel-Ablauf)

```
Reale Welt:   Anliegen sammeln (Gespräch/Seelsorge)  →  Glauben & Insight aufbauen
              ↓ Bedürfnis-Treffer erhöhen den Ertrag (#171)
Unsichtbar:   Dämonentyp erkennen  →  passenden Modus/Kombo wählen  →  Zellen befreien
              ↓ befreite Zellen machen NPCs empfänglicher
Zurück:       Gemeinde-Erträge einsammeln, Mission/Stadtteil-Fortschritt, Stufe freischalten
```

Jeder Durchlauf soll dem Spieler mindestens **einen sichtbaren Erfolg** liefern (bekehrter NPC, befreiter Block, Freischaltung, Missionsabschluss).

---

## 5. Was ausdrücklich nicht geplant ist

- Keine Zahleninflation als Belohnung (Prinzip aus #173): Belohnungen sind vorrangig Freischaltungen.
- Keine Pflicht-Grinds vor dem ersten Etappenerfolg.
- Kein Vollzeit-Echtzeitdruck: Der Spieler kann jederzeit pausieren/speichern (siehe `mobile_ui.md`).
