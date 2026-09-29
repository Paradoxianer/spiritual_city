# Progression, Freischaltungen & Gemeinde

Erweitert Lastenheft §10.1 ("Keine klassischen Level", mit den dort offenen Notizen zu geistlichen Missionen). Umsetzung: #179 (Fähigkeiten, Investitions-Aktionen), #181 (Gemeinde), #171 (Varianz/Bedürfnisse), #173 (Mission-Tiers), #172 (Predigen). Werte sind **Startwerte** (zentral in `GameBalance`, #83).

---

## 1. Ist-Stand (Code)

- **Ressourcen-Stufen** (#61): Schwellen 250/750/1750/3500/6500; `maxFaith = 100 + 20·(Stufe−1)`, `maxHealth`/`maxHunger` `+10` je Stufe (`PlayerProgress`).
- **Kampf-Upgrades** (#4): je Modus Radius/Stärke/Dauer/Tempo, `+0.1` je Level, Kosten `floor(1.5^Level)` Insight; Schild/Helm bis 0.8 Reduktion.
- **Modifier** (§5.4/#29): passive Boni nach Zählern (z. B. Kraft nach 3 Bekehrungen).
- **Missionen:** 1–3 Insight je Mission (`MissionService`).

**Problem:** Die nächste Stufe fühlt sich nach nichts an; Missionen sind ab mittlerer Stufe wirtschaftlich bedeutungslos, weil die Upgrade-Kosten exponentiell wachsen (#173).

---

## 2. Fähigkeiten pro Stufe (#179)

Je Kampfmodus gibt es **Meilenstein-Level** (Startwerte: 3, 5, 8), die eine **neue Fähigkeit** freischalten. Dazwischen bleiben kleine Zahlen-Upgrades. Beispiele (im Prototyp zu prüfen):

| Modus | Level 3 | Level 5 | Level 8 |
| :--- | :--- | :--- | :--- |
| Liberation | Lichtbrücke: verbindet nahe grüne Zellen | Zone bleibt kurz bestehen | Segensfläche: Zellen fallen langsamer zurück |
| Rebuke | Schockkette: Rückstoß trifft Nachbarn | Rückstoß schleudert gegen Wände (Betäubung) | — |
| Slow | Zeitfalle: verweilende Zone | Zone schwächt zusätzlich | — |
| Drain | Gefäß: Rückfluss wird zu Material/Insight statt nur Glauben | Kettenwirkung auf Sauger | — |

- Freischaltungen sind im UI als **Neu** markiert (Toast/Badge) und erklärt.
- Liberation erhält bewusst weniger Zahlen-Upgrades (#129).
- Alte Saves: fehlende Felder → Defaults, freigeschaltet wird nach Level.

## 3. Investitions-Aktionen (#179)

Aktionen, die **jetzt** etwas kosten und **später** mehr zurückgeben, damit der Loop "beten → Glauben sammeln → kämpfen" echte Entscheidungen hat:

| Aktion (Arbeitsname) | Kosten jetzt | Ertrag später |
| :--- | :--- | :--- |
| **Fasten** | Hunger (Startwert −30) | Nächste Gebetssession: Wellenkosten −20 % oder Glaubens-Puffer |
| **Fürbitte** | Glauben (Startwert 30) | Erhöht für einen NPC/ein Haus die Gewinne der nächsten Aktionen (Bedürfnis-Treffer, #171) |
| **Anbetung** (bestehend in Kirchen) | Zeit | Glaubens-Regeneration; wird durch Gemeinde-Fürbeter verstärkt |

Ziel: mindestens eine Aktion mit spürbarem Rückfluss, aber nie als Pflicht-Grind (§5 in `core_loop_and_retention.md`).

## 4. Gemeinde (#181)

Bekehrte NPCs (`isConverted`) werden **Gemeindemitglieder** mit optionaler Rolle:

| Rolle | Ertrag (flach, Startwerte) | Bedingung |
| :--- | :--- | :--- |
| **Fürbeter** 🙏 | Kleiner Glaubens-Regen beim Pastor je Spieltag | Faith ≥ 70 |
| **Hauskreisleiter** 📖 | Erhöht den Haus-Glauben der eigenen Wohnung; Insight-Chance | Wohnt in einem Haus mit ≥ 2 Bewohnern |
| **Helfer** 🤝 | Materialspenden je Spieltag | Faith ≥ 50 |

- Erträge kommen **gesammelt** (Toast/Zähler beim Pastorenhaus), kein Mikromanagement, kein Dauer-Spam.
- Zuweisung beim Bekehren (automatisch nach Bedürfnis) oder im Gespräch.
- Flach skalierend: mehr Mitglieder → mehr Ertrag, aber mit abnehmender Steigerung; Stadtteil-Bindung (#173/#172).
- Persistierung: Rolle im NPC-Zustand (`applySavedNPCState`), fehlend → keine Rolle.

## 5. Mission-Tiers, Predigen (Verweis)

Tier 1 (Kleinaufgaben), Tier 2 (Ketten), Tier 3 (Stadtteil-Projekte, **qualitative** Belohnung, z. B. Predigen); Belohnung Zahlen `base × (1 + Stufe × 0.5)` — siehe #173 und #172. Die Etappen aus `core_loop_and_retention.md` §3 sind die Tier-3-Ziele.

## 6. Interaktions-Varianz & Bedürfnisse — umgesetzt (#171)

Abnehmende Erträge je Session-Wiederholung (1.0×/0.6×/0.35×), Varianz-Bonus 1.2× beim Aktionswechsel, Bedürfnis-Multiplikator 2.0×/0.75× — implementiert in `InteractionVarianceService` (`lib/src/features/game/domain/services/`) und in `NPCComponent.handleInteraction` für talk/counsel/bible/pray/help verdrahtet.

- **Bedürfnis (`NpcNeed`):** lonely→talk, doubting→counsel, seeking→bible, needy→pray/help. Deterministisch aus einem stabilen Hash der NPC-`id` (nicht `String.hashCode`, das ist über SDK-Versionen nicht garantiert stabil) — wird **nicht** persistiert, sondern bei jeder Regeneration neu abgeleitet. Alte Saves sind damit automatisch kompatibel (kein Migrations-Feld nötig).
- **Session-Tracking** (`sessionCountFor`, `lastActionType`) liegt direkt auf `NPCModel` und wird über `resetSession()` bei jedem neuen Gespräch zurückgesetzt.
- **Noch offen (UI):** die progressive Sichtbarkeit des Bedürfnisses und ein UI-Hinweis auf den wirkenden Multiplikator sind noch nicht in `game_screen.dart`/`DialogOverlay` verdrahtet. Wird voraussichtlich zusammen mit der NPC-Vergangenheit (siehe [`npc_backstory.md`](npc_backstory.md), Entwurf) gelöst — dort bekommt jede NPC eine kleine generierte Lebensgeschichte (Kindheit/Jugend/Jetzt) als Emoji-Sätze, mit derselben Aufdeckung, die hier schon vorgeschlagen war: Wiederverwendung von `isFaithVague`/`isFaithRevealed` auf `interactionCount`, keine getrennten Kanäle.
- Getestet in `test/features/game/domain/models/npc_model_needs_test.dart` und `test/features/game/domain/services/interaction_variance_service_test.dart`, inkl. des Abnahmekriteriums "5× Bibellesen ist messbar schlechter als eine gemischte Rotation".
