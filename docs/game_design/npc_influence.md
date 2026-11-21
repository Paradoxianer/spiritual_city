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
- **Befreiung durch Gebet, Fürsorge danach** (Playtest 2026-11-16, ersetzt „Befreiung braucht beide Welten“): Der 👁️ Besetzer ist immer angreifbar – zäh, aber Befreiung ist seine Schwäche. Besiegt ist der Mensch frei (+40 Glauben, Einsicht) und es kommt kein neuer Besetzer. Danach zählt 👂 Seelsorge an ihm doppelt (Mk 1,25; Lk 10,17; Mk 5,15–19). Die frühere Sperre (erst Seelsorge, dann angreifbar) war unsichtbar und frustrierend – und biblisch falsch herum. Mögliche Erweiterung, bewusst nicht umgesetzt: das „leere Haus“ (Lk 11,24–26).
- Belohnung: NPC-Faith springt hoch, Cell-Puls, Insight-Bonus, Missionsfortschritt.

## 4. Bekehrte stützen befreite Zellen (#180)

- Zellen mit ≥ 1 Christen im Radius (Startwert 2 Zellen) bekommen **weniger roten Druck** (Bonus auf `decayReduction` in `SpiritualDynamicsSystem`; Größenordnung wie Modifier "Bewahrung", nicht additiv unbegrenzt).
- Mehrere Christen stapeln mit abnehmendem Ertrag, damit keine Explosion entsteht (offene Frage in Lastenheft §6.2).

### Boden wie im Game of Life (Playtest 2026-11-20)

Vorher sank jede nicht-rote Zelle täglich um 0,002 („gefallene Welt“) und glich sich an ihre 4 Nachbarn an – große befreite Gebiete wurden überall gleichzeitig rot. Jetzt (`WorldSimulation.groundDelta`, 8 Nachbarn):

- **Rot drückt nach seiner Tiefe:** Druck je Nachbar `((−0,2 − s) / 0,8)²` – ab −0,2, quadratisch. Tiefe rote Fronten fressen sich hinein, ein flacher roter Fleck kaum. Verlust/Tag = 0,008 × Druck (erst 0,02 – auf Wunsch halbiert: 6 h grün auch am Stadtrand ohne Christen).
- **Grün stützt sich:** Jeder grüne Nachbar (> 0,3) hält 7,5 % des Drucks ab. Ab 5 grünen Nachbarn heilt Grün flaches Rot (0,0004/Tag je grünem Nachbarn) (voll bis −0,3, nichts mehr ab −0,7 – tiefes Rot befreit nur Gebet). Grün breitet sich nicht von selbst aus.
- **Kein eigener Rückfall:** Grau bleibt grau, Grün bleibt grün, bis Rot es erreicht. Grün neben Grün hält für immer.
- **Christen schützen stark:** Druck × 1/(1 + 2·Christen) (1 → 33 %, 2 → 20 %, mind. 5 %). Reichweite 2 + Stabilität × 8 Zellen (bis 9) – Seelsorge, Lebensthemen, Gemeinde und 🌱-Lehre (📖) vergrößern sie.
- **Menschen:** Feindselige (< −50) verdunkeln ihre Zelle (× 0,002/Glaubenspunkt), Unentschiedene (< 0) leicht (× 0,0002) – je grüner die Umgebung, desto weniger; dort öffnet sich zugleich ihr Glaube.
- **Eichung** (`ground_game_of_life_test.dart`): ein befreites Viertel (48×48) ohne einen Christen in tiefem Rot ist nach 6 h zu ~75 % grün, nach 12 h zu ~50 %, die Mitte unberührt. Flaches Rot im Grün heilt in ~4 h; neben einem tiefroten Fleck ist das Grün nach 12 h noch nicht gekippt.

### Bekehrung bei der 📢🎺 Freiversammlung (Playtest 2026-11-21)

Bei einer Freiversammlung können sich mehrere Zuhörer auf einmal bekehren (Apg 2,41). Das soll am Ende die vielen Einzelgespräche ersparen. Es bekehren sich aber nur Menschen, die schon bereit sind: Glaube plus Boden × 50 muss über 60 liegen, im Gespräch reichen 50. Die Freiversammlung erntet also, was über Beziehungen gewachsen ist (Mt 9,37).
- **Chance je bereitem Zuhörer:** (Glaube des Pastors vor den Kosten / 400, höchstens 1) × (20 % + 3 % je Christ in Reichweite, höchstens 90 %). Beispiele: 340 🙏 mit 20 Christen ergibt etwa 68 %, 100 🙏 etwa 20 %.
- **Belohnung:** 📖 halb so viel wie bei einer Bekehrung im Gespräch.
- **Code:** `OpenAirHarvest`.

## 5. Gemeinde (#181)

Details zu Rollen und passivem Ertrag siehe `progression_and_unlocks.md`, Abschnitt "Gemeinde". Voraussetzung ist ein zentraler NPC-Zustandsspeicher (#170).
