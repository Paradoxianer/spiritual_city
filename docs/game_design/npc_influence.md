# NPC-Einfluss auf die unsichtbare Welt

Erweitert Lastenheft §6.3 ("NPC-Einfluss auf Territorium", dort als "muss noch überarbeitet werden" markiert). Umsetzung: #180 (Aura, Besessenheit) und #181 (Gemeinde). Werte sind Startwerte.

---

## 1. Ist-Stand (Code, `NPCComponent._updateSpiritualInfluence`)

| NPC-Zustand | Wirkung auf die Zelle des NPC |
| :--- | :--- |
| Christ (`isChristian`) | Zelle und 4 Nachbarzellen werden grüner (`faith × k`, k je Schwierigkeit); dazu ein permanenter AoE-Puls über den `InfluenceService` (#59). Der Glaube kühlt langsam ab (−0.15 je Tick, Untergrenze 50). |
| Faith > 50 | Schwacher positiver Schub (+0.05) |
| Faith < −50 | Verdunkelt die Zelle (`|faith| × 0.002`) |

Zusätzlich: Nicht-Christen bewegen sich in dunklen Zellen langsamer (`_updateAI`). LOD: Nur im Detailgrad *high* wird der Einfluss gerechnet.

**Lücken:** Der Einfluss ist für den Spieler kaum sichtbar; feindliche NPCs ziehen keine Dämonen an; es gibt keine Besessenheit; Bekehrte stabilisieren befreite Zellen nicht gezielt.

---

## 2. Aura sichtbar machen (#180)

Im unsichtbaren Modus zeigen NPCs eine **Aura**:

- dunkel (Faith < −50), neutral, hell (Christ oder Faith > 50)
- Stärke = Radius/Intensität, proportional zum Einfluss auf die Zelle
- Schleimspur/Glanz an der Zelle bleibt bestehen; die Aura ergänzt sie am NPC selbst

So erkennt der Spieler beim Kämpfen, **wer** für Dunkelheit oder Licht verantwortlich ist.

## 3. Besessenheit (#180)

- Sehr feindliche NPCs (Startwert: Faith < −60) können **besetzt** sein (Chance seed-basiert, deterministisch).
- Ein besetzter NPC ist als solcher erkennbar (Aura mit Dämonen-Symbol) und **spawnt Dämonen vom Typ Besetzer** an seiner Position (`daemons_and_combat.md`).
- **Befreiung braucht beide Welten:** In der realen Welt Seelsorge/Gebet (hebt Faith über die Schwelle, öffnet die Besessenheit), in der unsichtbaren Welt den Besetzer-Dämon besiegen. Nur eines von beidem reicht nicht.
- Belohnung: NPC-Faith springt hoch, Cell-Puls, Insight-Bonus, Missionsfortschritt.

## 4. Bekehrte stützen befreite Zellen (#180)

- Zellen mit ≥ 1 Christen im Radius (Startwert 2 Zellen) haben einen **reduzierten Rückfall** (Bonus auf `decayReduction` in `SpiritualDynamicsSystem`; Größenordnung wie Modifier "Bewahrung", nicht additiv unbegrenzt).
- Mehrere Christen stapeln mit abnehmendem Ertrag, damit keine Explosion entsteht (offene Frage in Lastenheft §6.2).

## 5. Gemeinde (#181)

Details zu Rollen und passivem Ertrag siehe `progression_and_unlocks.md`, Abschnitt "Gemeinde". Voraussetzung ist ein zentraler NPC-Zustandsspeicher (#170).
