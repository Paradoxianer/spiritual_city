# NPC-Vergangenheit: Lebensphasen

**Status: Entwurf v2, wartet auf Rückmeldung.** Noch kein Code, keine Issue-Nummer. Überarbeitet nach Rückmeldung zu v1 (siehe §7 „Was sich gegenüber v1 geändert hat"). Baut auf #171 (Interaktions-Varianz & NPC-Bedürfnisse) auf, ersetzt es nicht.

## 1. Idee

Statt eines flachen Pools einzelner "Karten" bekommt jede NPC eine kleine, generierte **Lebensgeschichte** entlang fester Phasen (Kindheit, Jugend, Jetzt). Für jede Phase wird gewürfelt, was passiert ist – und bei negativen Ereignissen zusätzlich, ob die NPC das **durchgearbeitet** hat oder nicht. Durchgearbeitete negative Ereignisse machen die NPC mental stärker (gedämpfte negative Reaktionen), unverarbeitete bleiben eine offene Wunde. Dargestellt wird jedes Ereignis als **Emoji-Satz** (Sequenz, nicht ausgeschriebener Text) – genau der visuelle Stil, den das Spiel überall sonst schon nutzt (z. B. die Reaktions-Emoji-Ketten in `npc_component.dart`, die Aktions-Emoji in `building_actions.md`).

## 2. Lebensphasen & Kategorien

**Phasen (fest, für jede NPC gleich – siehe §7 zur Vereinfachung):** Kindheit → Jugend → Jetzt.

**Kategorien pro Phase** (fünf, klein gehalten):

| Kategorie | Glyphe | Mechanisch wirksam? |
| :--- | :--- | :--- |
| Glaube | ✝️ | Ja – direkter `faith`-Offset |
| Geld / Beruf | 💼 | Ja – beeinflusst Spenden-/Großzügigkeits-Chance (`houseVisit`, `requestDonation`) |
| Beziehung | 💞 | Nein (v1) – nur Varianz/Textur |
| Verlust | ⚰️ | Nein (v1) – nur Varianz/Textur |
| Gesundheit | 🩹 | Nein (v1) – nur Varianz/Textur |

Nur zwei Kategorien bekommen in v1 eine echte Spielauswirkung, weil das genau die zwei sind, die der Pastor selbst als Ressource hat (Glaube, Material) – wie gewünscht "dieselben Werte, die der Pastor hat". Die anderen drei sorgen trotzdem für Abwechslung (das eigentliche Ziel), ohne dass jede Kategorie sofort einen neuen Spielmechanismus braucht. Können später mechanisch angebunden werden (z. B. Verlust → Trauer-Dialogvariante).

## 3. Generierung (deterministisch, wie `NpcNeed`)

Pro Phase × Kategorie wird gewürfelt (Hash aus NPC-`id` + Phase + Kategorie, wie beim bestehenden `need`-Mechanismus – **kein Verbrauch der Chunk-RNG**, also keine Nebenwirkung auf die Weltgenerierung):

1. **Passiert etwas?** (Basis-Wahrscheinlichkeit je Kategorie, grob 30–45 %.)
2. **Positiv oder negativ?** (grob 50/50, je Kategorie leicht verschoben – z. B. "Glaube" häufiger positiv, "Verlust" fast immer negativ.)
3. **Nur bei negativ: durchgearbeitet?** Wahrscheinlichkeit steigt mit Abstand der Phase: Kindheit ~65 % (viel Zeit gehabt), Jugend ~45 %, Jetzt ~25 % (frisch, noch offen).

Alles rein deterministisch aus der ID abgeleitet, **nicht persistiert** – wie das Bedürfnis aus #171 bei jeder Regeneration neu berechnet. Keine Schema-Änderung am Save nötig.

## 4. Mechanische Wirkung

- **Glaube-Ereignis:** verschiebt den `faith`-Basiswert der NPC bei Generierung (Größenordnung ±5 bis ±15, je nach Phase).
- **Geld-Ereignis:** verschiebt eine bei Bedarf berechnete "Großzügigkeit" (nicht gespeichert, aus den Ereignissen abgeleitet), die in die bestehende Spendenchance bei `houseVisit`/`requestDonation` einfließt.
- **Durchgearbeitet (jede Kategorie mit negativem Ereignis):** der eigene negative Effekt wird gedämpft (≈30 % der vollen Wirkung statt 100 %) **und** erhöht eine kleine, gemeinsame `resilience`-Größe der NPC. Diese dämpft allgemein negative Interaktions-Ausschläge etwas ab (z. B. die −8 Faith bei abgelehntem Gebet) – eine NPC, die ihre Vergangenheit verarbeitet hat, ist spürbar stabiler, unabhängig davon, worum es dabei ging.
- **Nicht durchgearbeitet:** volle negative Wirkung, keine Dämpfung – eine offene Wunde bleibt eine offene Wunde.
- Positive Ereignisse brauchen keinen Verarbeitungs-Wurf, sie wirken direkt.

## 5. Aufdeckung: **ein** gemeinsamer Fortschritt, keine getrennten Kanäle

Kein neuer Zähler. Wiederverwendung des bereits vorhandenen `interactionCount` + `isFaithVague`/`isFaithRevealed` (Schwellen 3 / 6, `base_interactable_entity.dart`). Das passt schon heute genau zu "Seelsorge bringt mehr, kostet aber mehr": Seelsorge erhöht `interactionCount` bereits um **6** pro Nutzung (`npc_component.dart`), ein Gespräch nur um **1** – Seelsorge kostet zusätzlich Gesundheit, Gespräch nichts. Diese Gewichtung ist bereits genau richtig, ich muss nichts Neues einführen.

- **Vage (`isFaithVague`, ab 3):** ein einziges, immer gleiches Symbol (💭) – verrät nichts Kategorie-Spezifisches.
- **Voll (`isFaithRevealed`, ab 6):** alle generierten Lebensphasen-Ereignisse als Emoji-Sätze, mit kurzer Beschriftung im Stil der bestehenden Tooltips (`tooltip: 'Anbetung'` usw.) – **kein** ausgeschriebener Satz, nur 2–3 Wörter Bildunterschrift, z. B. "Jugend · Verlust".

## 6. Emoji-Komposition (kein Pool aus 15 Einzelfällen – zusammengesetzt)

Statt jede mögliche Kombination von Hand zu texten, wird die Sequenz aus drei Bausteinen zusammengesetzt: **Kategorie-Glyphe** + **Valenz-Glyphe** + (bei negativ) **Bewältigungs-Glyphe**.

| Baustein | Glyphen |
| :--- | :--- |
| Valenz positiv | ✨ |
| Valenz negativ | 💔 |
| Durchgearbeitet | 🌱 |
| Nicht durchgearbeitet | 🌫️ |

**Beispiele:**
- Jugend, Beziehung, positiv → `💞✨` · Bildunterschrift "Jugend · Beziehung"
- Kindheit, Verlust, negativ, nicht durchgearbeitet → `⚰️💔🌫️` · "Kindheit · Verlust"
- Jetzt, Glaube, negativ, durchgearbeitet → `✝️💔🌱` · "Jetzt · Glaube"
- Jugend, Geld, negativ, nicht durchgearbeitet → `💼💔🌫️` · "Jugend · Geld"

Das deckt automatisch auch "erwachsenere" Themen ab (Sucht, Scheidung, Verlust durch Gewalt fallen alle unter Verlust/Beziehung/Gesundheit negativ), ohne dass ich dafür explizite, möglicherweise geschmacklose Einzel-Emoji suchen muss – die Abstraktion (Kategorie + Valenz + Bewältigung) bleibt bewusst unspezifisch genug, um würdevoll zu bleiben, und ist beliebig erweiterbar, ohne dass die Sequenz-Bausteine wachsen müssen.

## 7. Was sich gegenüber v1 geändert hat

- ~~Ausgeschriebener Volltext bei voller Aufdeckung~~ → Emoji-Satz + Kurz-Label, passend zum Rest des Spiels.
- ~~Getrennte `talkCount`/`counselCount`-Zähler, neuer Save-Schema-Bump~~ → Wiederverwendung von `interactionCount`/`isFaithVague`/`isFaithRevealed`, **keine** Save-Änderung nötig.
- ~~Flacher Pool aus 15 von Hand getexteten Karten~~ → Lebensphasen × Kategorien, Ereignisse und ihre Emoji-Sätze werden zusammengesetzt statt einzeln autorisiert.
- **Neu:** die "durchgearbeitet"-Mechanik (Resilienz) – war in v1 nicht enthalten.

**Bewusste Vereinfachung, zur Rückmeldung:** Alle NPCs bekommen dieselben drei Phasen (Kindheit/Jugend/Jetzt), nicht abhängig vom tatsächlichen Alter – das Spiel führt aktuell kein Alter pro NPC. Eine altersabhängige Phasenzahl wäre möglich (z. B. junge NPCs ohne "Jetzt"-Volljährigkeits-Ereignisse), würde aber ein neues Alters-Konzept nur für dieses Feature einführen. Ich würde das als spätere Verfeinerung offenlassen, wenn das für dich in Ordnung ist.

## 8. Umsetzungsschritte (nach Freigabe)

1. `LifePhase`-Enum (childhood/youth/now), `LifeCategory`-Enum (5 Werte) im Domain-Modell.
2. Deterministische Ereignis-Generierung pro NPC (Hash wie `NpcNeed`), `late final` Getter auf `NPCModel` – kein neuer Save-Zustand.
3. Emoji-Komposition + Kurz-Label als reine, testbare Funktion.
4. Verdrahtung: `faith`-Offset bei Generierung, Spendenchance-Modifier, Resilienz-Dämpfung in den bestehenden negativen Interaktionspfaden.
5. UI: 💭-Hinweis ab `isFaithVague`, Emoji-Sätze ab `isFaithRevealed` im Dialog.
6. Tests: Generierung deterministisch, Komposition korrekt, Resilienz-Dämpfung, Spendenchance-Modifier.

## 9. Akzeptanzkriterien (Entwurf)

- [ ] Jede NPC hat für jede Phase×Kategorie ein deterministisches Ergebnis (passiert/nicht, Valenz, Bewältigung bei negativ)
- [ ] Emoji-Satz wird aus Bausteinen zusammengesetzt, kein ausgeschriebener Text
- [ ] Aufdeckung nutzt ausschließlich `interactionCount`/`isFaithVague`/`isFaithRevealed`, keine neuen Zähler
- [ ] Durchgearbeitete negative Ereignisse dämpfen sowohl ihren eigenen Effekt als auch allgemein negative Interaktions-Ausschläge
- [ ] Glaube- und Geld-Kategorie sind mechanisch wirksam, die übrigen drei sind reine Varianz
- [ ] Keine Änderung am Save-Schema nötig
- [ ] Unit-Tests für Generierung, Komposition, Resilienz-Dämpfung

## 10. Offene Fragen für später (nicht Teil von v1)

- Altersabhängige Phasenzahl (siehe §7).
- Content-Filter für Store-Freigabe, sobald #95/#153 entschieden sind.
- Verknüpfung mit Missionen (#173): eine Tier-2-Kette könnte an ein unverarbeitetes Ereignis anknüpfen.
