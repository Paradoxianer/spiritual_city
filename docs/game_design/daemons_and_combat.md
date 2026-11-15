# Dämonen & Gebetskampf

Erweitert Lastenheft §2.3 (Gebetskampf) und §5.5 (Dämonen). Umsetzung: #178. Balancing-Rahmen: #129.

Werte sind **Startwerte**, per Playtest zu justieren (zentral in `GameBalance`, #83).

---

## 1. Ist-Stand (Code)

- **Gebetskampf:** Halten erzeugt alle 1,8 s eine Schockwelle (`PlayerComponent`), Kosten 5 Glauben je Welle. Stärke = `base.strength × Kraft × faithFactor(faith/100, 0.1–2.0) × (1 + 0.2·Haltezeit) × 25`; Radius `base.radius × 140`; Geschwindigkeit `base.speed × 90` (`ModifierManager.getEffectiveCombatStats`).
- **Vier Modi:** Liberation, Rebuke (Rückstoß), Slow, Drain. Auf **Zellen** wirkt Liberation mit Faktor 1.0, die anderen mit 0.15 (`ShockwaveComponent`); auf **Dämonen** wirkt jede Welle mit `strength × 5 × falloff`. Liberation stoppt zusätzlich das Verdunkeln der Zelle durch den Dämon (`DaemonComponent`), Slow halbiert die Spiral-Geschwindigkeit.
- **Dämonen:** ein einziger Typ; `DaemonModel` hat nur `energy`. Maximalzahl 10/15/20 (easy/normal/hard), Start-Energie −180/−300/−420, Dauer-Spawn alle 3–12 s (seit §4b ersetzt durch Wellen), Gebets-Attraktion 30 s (`SpiritualDynamicsSystem`). Die Stärke skaliert **nur mit der Schwierigkeit**, nicht mit dem Spielerstand.
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

> **Zurückgenommen (Playtest 2026-11-15)** – §4a–§4c waren umgesetzt, wurden aber wieder aus dem Code entfernt (Commits 87e041d, ccd65f0, ba5f97f, cdf0736 in der Git-Historie). Gründe: Dämonen waren plötzlich sehr schwer zu besiegen, ein schwarzer Ring (Besetzer) tauchte früh auf und ließ sich nicht besiegen, und die Idee „Tower Defense“ war im Spiel nicht erkennbar (keine Vorschau, welche Art als Nächstes kommt). Wenn wir es wieder angehen: zuerst die Vorschau der nächsten Dämonen, dann erst Resistenzen/Wellen – und alles in kleinen, einzeln spielbaren Schritten.

### Notizen für einen zweiten Anlauf (Playtest 2026-11-15)

Das Dauer-Nachspawnen war das eigentliche Problem: Es gab keine klaren Wellen, und nirgends war zu sehen, wie viele Dämonen noch kommen oder was als Nächstes folgt. Wellen müssen deshalb **lesbar** sein, ähnlich wie die Missionen:

- **Anzeige wie bei den Missionen:** Ein fester Zähler zeigt, wie viele Dämonen der Welle noch kommen/übrig sind (nur Emoji, z. B. `🌊2  👹 5/8`).
- **Vorschau auf die nächste Welle:** welche Arten kommen (`🐍🐍🪨 …`), damit man sich auf Gebetsarten und Jünger vorbereiten kann – das ist der eigentliche Tower-Defense-Teil.
- **Nichts läuft nach, während eine Welle läuft:** Die Zahl der Dämonen ist fest. Kein Hintergrund-Spawn, keine Dämonen von außen, bis die Welle vorbei ist.
- **Echte Pause nach der besiegten Welle:** Erst wenn die Welle komplett besiegt ist, kommt der Durchbruch – die dicke grüne Welle soll man sichtbar vom Pastor aus loslaufen sehen (nicht nur als Zahl oder Toast). Während der Pause kommt nichts; dann beginnt die nächste Welle, wieder mit Anzeige und Vorschau.
- **Die ersten Wellen sind super einfach** (wenige, schwache Dämonen, eine Art, keine Resistenzen). Erst mit wachsender Wellenzahl wird es schwieriger – dafür wird der Durchbruchs-Ring (die grüne Welle) **stärker und größer** – ohne Obergrenze. Das hilft im späteren Spiel, ganze Viertel schneller zu befreien: Wer weit kommt, wird fürs Durchhalten spürbar belohnt.
- **Kein Deckel beim Durchbruch.** Radius, Stärke und Offenheit wachsen mit jeder Welle ohne Obergrenze. Begründung: Kampfkraft kaufen wird immer teurer, und die Wellen werden immer schwerer – wer ewig durchhält und das zu seiner Strategie macht, soll dafür nicht bestraft werden. (Technisch wirkt die Welle ohnehin nur dort, wo die Welt schon erzeugt ist; Kosten pro Welle müssen beim Bau gemessen werden, ggf. über mehrere Bilder verteilen, aber nicht per Deckel begrenzen.)
- Resistenzen erst danach und nur, wenn der Spieler sie vorher sehen kann (Vorschau/Ring) und die Schwäche sie aufhebt – ohne dass Dämonen „unbesiegbar“ wirken.
- Ein 👁️ Besetzer (schwarzer Ring) darf nicht früh und unerklärt auftauchen; sein Ring sollte zeigen, was fehlt (🙏👂 Seelsorge am Menschen).

## 4a. Resistenzen (Playtest 2026-11-14)

Jeder normale Typ widersteht einem Gebet: **halbe Wirkung** (Schaden, Effektdauer, Rückstoß) – außer seine Schwäche liegt gerade auf ihm. Also: erst die Schwäche treffen, dann zuschlagen.

| Typ | Schwäche | Resistenz | Bild |
| :--- | :--- | :--- | :--- |
| 🐍 | Binden | Zurückweisen | glitschig, entwischt |
| 🪨 | Zurückweisen | Befreiung | steinernes Herz (Hes 36,26) |
| 🦇 | Entwaffnen | Binden | fliegt davon |
| 👁️ | Befreiung | – | – |

Darstellung (mit 👁️ Unterscheidung der Geister): ein Ring in der Farbe des widerstandenen Gebets; liegt die Schwäche auf dem Dämon, wird er blass und unsere Effektringe liegen darüber. Code: `DaemonKind.resistance`, `DaemonCombatRules.resists`.

## 4b. Wellen & Durchbruch (Playtest 2026-11-14)

Frage: *Was bringt es, länger durchzuhalten?* Vorher nichts – Dämonen kamen gleichmäßig zufällig, zehnmal kurz war so gut wie einmal lang.

- Die Dämonen kommen in **Wellen 🌊**: 4 / 6 / 8 (leicht/normal/schwer), jede Welle 2 mehr und +15 % Energie. Welle 1 ist eine Art, Welle 2 zwei, ab Welle 3 alle drei.
- Ist eine Welle besiegt (alle ihre Dämonen weg), rollt der **Durchbruch**: eine dicke grüne Welle vom Pastor aus, Radius 6 Felder × Welle, Stärke 50 + 10 × Welle. Sie macht das Land grün, und Menschen darin werden offener (+2 Glauben × Welle). **Kein Deckel** (Playtest 2026-11-15, siehe unten). Bollwerke trifft sie nicht.
- Danach 5 s Atempause, dann die nächste Welle.
- Rausgehen ist jederzeit möglich, das Erreichte bleibt; der nächste Besuch beginnt wieder bei 🌊1. Das Risiko sind 🙏 und 🍞.
- Biblisch: Mose hält die Arme hoch, gestützt von Aaron und Hur (2. Mose 17); „Könnt ihr nicht eine Stunde mit mir wachen?“ (Mt 26,40).
- Code: `SpiritWaves`, `SpiritualDynamicsSystem.startWaves`, `GameSpiritWaves.onWaveCleared`. Die Langzeit-Simulation modelliert keine Dämonen; die Werte sind Startwerte für Playtests.

## 4c. Jünger im Kampf

Jünger beten nahe beim Pastor mit (`discipleship_control.dart`); aufstellen lassen sie sich über die 📢 Freiversammlung. Läuft ein Dämon über einen Jünger, verliert dieser einmal je Dämon Glauben: 4 × (1 − Festigkeit), also 4 ohne Seelsorge und 0,4 bei voller Festigkeit (`Discipleship.daemonTouchLoss`; Festigkeit vor allem aus Seelsorge 👂📜) – nach einigen ist er ✝️💔 erschüttert und betet nicht mehr mit, bis der Pastor ihn besucht. Dämonen greifen weiter nur den Pastor an; Häuser bleiben außen vor (bewusst nicht umgesetzt).

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

> **Umgesetzt (Teil 1):** Rebuke, Slow und Drain befreien Zellen nur noch minimal (`ShockwaveComponent.controlModeCellFactor = 0.02`, vorher 0.15 – reines Rückstoß-Spammen hat die Stadt spürbar mitbefreit und Liberation damit optional gemacht). Der **Tod** eines Dämons befreit dagegen unabhängig vom Modus: Jeder vom Spieler verursachte Kill reinigt einen 3-Zellen-Radius (`DaemonComponent._cleanseAroundDeathPoint`) – auch ein Drain-Kill, der zusätzlich Glauben zurückgibt (vorher reinigte Drain gar nicht). Erkenntnis gibt es für jeden Kill. Kontroll-Modi lohnen sich also, um Dämonen zu erledigen, aber nicht, um mit ihren Wellen selbst Gebiet zu befreien. Die eigentlichen Kombo-Boni und Dämonentypen (§3/§4) sind noch offen (#178).

## 7. Abbruch des Gebets (Bezug #167)

Erwartung: Das Gebet endet nur, wenn der Spieler loslässt oder Glauben bzw. Leben leer sind. Der Ist-Stand (Abbruch bei `faith < cost`, Aufladen bis `faith <= 1`, Skalierung mit `faith/100`) wird im Rahmen von #167 vereinheitlicht.

## 7a. Umgesetzt (M2, `feat/m2-core`)

Typen, Schwächen, Kombo-Kette, Stufen und Gnadenfrist wie oben beschrieben (`DaemonKind`, `DaemonCombatRules`, `PlayerProgress.onSpiritWorldEntered`). Abweichungen: Kettenblitz = 50 % der Start-Energie als Sofortschaden; Gegenüberstellung im Test ist "Kette gegen dieselben drei Modi ohne Kombo", denn wiederholtes Entziehen ist durch ×1.8 schon allein stark. Ohne 👁️ Unterscheidung der Geister sehen alle Dämonen gleich aus (nur die Größe zeigt die Stufe). Rebuke/Slow/Drain gibt es in neuen Spielständen erst nach der Lern-Mission ⚔️.

## 8. Akzeptanz

Siehe #178. Kernpunkt: ≥ 3 Typen unterscheidbar, Schwäche je Typ, Kombo messbar stärker (Unit-Test), Tier sichtbar, Skalierung mit Gnadenfrist.
