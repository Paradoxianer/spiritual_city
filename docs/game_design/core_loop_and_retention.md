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
- **Geschlossene Stadt (Playtest 2026-11-20):** Die Stadt besteht genau aus ihren Vierteln (`CityLayout.quarters`). Dahinter liegt dichter Wald mit einem Fluss drei bis sechs Felder vor dem Rand (Ps 125,2), beides nicht begehbar. Dort gibt es keine Häuser, keine Menschen und keine Bollwerke. Boden, Fortschritt und Speicherstand zählen nur in der Stadt. Alte Spielstände verlieren beim Laden das Land, die Bewohner und die Viertel jenseits des Randes. Vorher sank der Fortschritt mit jedem entdeckten Randfeld, und Randviertel ohne Menschen ließen sich nie gewinnen. Später denkbar: Brücken als Ausgang, die zur Stadtwahl führen.
- **🌉 Brücke in die nächste Stadt (Playtest 2026-11-21):** Nach dem Sieg führt der Knopf 🌉 ➡️ in die nächstgrößere Stadt (🏡 → 🏘️ → 🏙️ → 🌆, danach wieder 🌆), als neuer Spielstand. Mit kommt alles, was den Pastor ausmacht: Level, Skills, Gebets-Upgrades, 📖, Statistik und die Dämonenstärke (`daemonPower`), daher wird die neue Stadt nicht leichter. Zurück bleiben Viertel, Gemeinde, Tageszählung und Gnadenzeit (`CityCrossing.stays`). Man startet zu Hause, ohne Tutorial. Die Brücke gibt es nur nach dem Sieg, als begehbare Brücke im Fluss ist sie für später denkbar.
- **Viertel ganz christlich (Playtest 2026-11-21):** Sind alle Bewohner eines Viertels Christen, kommt derselbe große 🎉-Bildschirm wie beim Freibeten, mit 🏘️✝️ statt 🏘️🟩 und 📖 10 statt 3. Das ist das schwerere, größere Ziel; vorher gab es nur einen kleinen Toast.
- **Ganze Stadt freigebetet (Playtest 2026-11-21):** Sind alle Viertel freigebetet, folgt einmal ein eigener 🎉-Bildschirm mit 🏙️🟩 und 📖 20 (`PlayerProgress.cityPrayedFree`). Er kommt in der sichtbaren Welt nach jeder anderen Feier, auch für ältere Spielstände, in denen das schon erreicht war. Der Sieg bleibt: jeder Mensch Christ.
- **Die Letzten finden (Playtest 2026-11-21):** Der Stadtplan zeigt in jedem offenen Viertel 🧍 N, also wie viele dort noch nicht Christen sind. Sind es höchstens fünf (`Awakening.lastSeekers`), erscheinen sie auf der Minimap als weiße Punkte. Im Testspielstand fehlten am Ende 19 Menschen in fünf Vierteln, alle mit 🙏 100, aber nie angesprochen.

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
