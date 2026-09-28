# Dämonen & Gebetskampf

Erweitert Lastenheft §2.3 (Gebetskampf) und §5.5 (Dämonen). Umsetzung: #178. Balancing-Rahmen: #129.

Werte sind **Startwerte**, per Playtest zu justieren (zentral in `GameBalance`, #83).

---

## 1. Ist-Stand (Code)

- **Gebetskampf:** Halten erzeugt alle 1,8 s eine Schockwelle (`PlayerComponent`), Kosten 5 Glauben je Welle. Stärke = `base.strength × Kraft × faithFactor(faith/100, 0.1–2.0) × (1 + 0.2·Haltezeit) × 25`; Radius `base.radius × 140`; Geschwindigkeit `base.speed × 90` (`ModifierManager.getEffectiveCombatStats`).
- **Vier Modi:** Liberation, Rebuke (Rückstoß), Slow, Drain. Auf **Zellen** wirkt Liberation mit Faktor 1.0, die anderen mit 0.15 (`ShockwaveComponent`); auf **Dämonen** wirkt jede Welle mit `strength × 5 × falloff`. Liberation stoppt zusätzlich das Verdunkeln der Zelle durch den Dämon (`DaemonComponent`), Slow halbiert die Spiral-Geschwindigkeit.
- **Dämonen:** ein einziger Typ; `DaemonModel` hat nur `energy`. Maximalzahl 10/15/20 (easy/normal/hard), Start-Energie −180/−300/−420, Dauer-Spawn alle 3–12 s, Gebets-Attraktion 30 s (`SpiritualDynamicsSystem`). Die Stärke skaliert **nur mit der Schwierigkeit**, nicht mit dem Spielerstand.
- **Upgrades:** `+0.1` je Level und Modifier (Radius, Stärke, Dauer, Tempo), Kosten `max(1, floor(1.5^Level))` Insight (`prayer_combat.dart`).

## 2. Problem

Man erkennt nicht, ob Dämonen stärker werden oder ob es verschiedene gibt; Rebuke, Slow und Drain lassen sich nicht sinnvoll kombinieren; Liberation ist als einziger Zell-Modus die Allzweckwaffe (#129).

---

## 3. Dämonentypen (Vorschlag)

Jeder Typ ist auf einen Blick erkennbar (Form, Farbe, Größe, Schleimspur) und hat **genau eine Schwäche**.

| Typ | Verhalten | Schwäche | Besonderheit |
| :--- | :--- | :--- | :--- |
| **Schleicher** 🐍 | Schnell, wenig Energie, weicht Wellen aus | **Slow** (×2 Wirkung) | Viele auf einmal; dünne Schleimspur |
| **Brocken** 🪨 | Langsam, viel Energie | **Rebuke** (×1.5 Rückstoß) | Große, breite Schleimspur |
| **Sauger** 🦇 | Zieht Glauben vom Pastor in Reichweite | **Drain** | Rückfluss von Glauben an den Spieler gedeckelt (Antwort auf #129 Punkt 3) |
| **Besetzer** 👁️ | Sitzt in einem NPC, spawnt von dort Dämonen | Beide Welten nötig (siehe `npc_influence.md`) | Verbindet Kampf und reale Welt |

Der erste Prototyp genügt mit drei Typen (Schleicher, Brocken, Sauger).

## 4. Modus-Kombos

Kette **Slow → Drain → Rebuke** innerhalb eines Zeitfensters auf dasselbe Ziel:

- Ziel unter Slow: Drain wirkt **+25 %** länger.
- Ziel unter Drain: Rebuke-Rückstoß **+50 %**.
- Vollständige Kette: kurzer "Kettenblitz"-Effekt als sichtbares Feedback (Sound, Partikel).

Andere Reihenfolgen funktionieren, sind aber schwächer – so gibt es eine effektivste Reihenfolge, die man entdecken kann (Frage aus #129).

## 5. Tier & sichtbare Stärke

- Jeder Dämon hat ein **Tier (1–3)**. Größe = `Basis × (1 + 0.25·(Tier−1))`, Schleimspur-Breite entsprechend, Energie entsprechend höher. Der Spieler erkennt die Stärke also optisch.
- **Skalierung mit dem Spieler:** Das Tier der Spawns hängt von einem Spielerstand-Wert ab (aus Upgrade-Stufen und Etappen).
- **Gnadenfrist:** Nach jedem Upgrade laufen die nächsten **N Besuche** (Startwert 3) der unsichtbaren Welt mit dem bisherigen Tier, damit sich ein Upgrade zuerst wie ein Erfolg anfühlt; danach wird der Widerstand angehoben (Idee des Besuchs-Zählers aus #129).

## 6. Rolle der Modi (Neuordnung)

| Modus | Rolle |
| :--- | :--- |
| Liberation | Zellen aufräumen/grün färben; Dämonen halten dagegen (Absorption in dunklen Bollwerken). Upgrades bringen hier bewusst **weniger** als bei den anderen Modi (#129). |
| Rebuke | Positionierung/Abwehr: Rückstoß, Kettenende der Kombo |
| Slow | Kontrolle: Grundlage der Kombo, hohe Dauer schon auf Level 0 |
| Drain | Schaden über Zeit, Glaubens-Rückfluss gedeckelt |

## 7. Abbruch des Gebets (Bezug #167)

Erwartung: Das Gebet endet nur, wenn der Spieler loslässt oder Glauben bzw. Leben leer sind. Der Ist-Stand (Abbruch bei `faith < cost`, Aufladen bis `faith <= 1`, Skalierung mit `faith/100`) wird im Rahmen von #167 vereinheitlicht.

## 8. Akzeptanz

Siehe #178. Kernpunkt: ≥ 3 Typen unterscheidbar, Schwäche je Typ, Kombo messbar stärker (Unit-Test), Tier sichtbar, Skalierung mit Gnadenfrist.
