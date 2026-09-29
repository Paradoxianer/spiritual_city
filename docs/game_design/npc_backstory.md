# NPC-Vergangenheit: Lebensphasen-Simulation

**Status: v4 umgesetzt.** Siehe §12 für die Änderungen gegenüber v3 (basierend auf dem ersten Live-Test): viel mehr gewöhnliche Füll-Ereignisse, "Verarbeiten" ist jetzt eine echte, spielergesteuerte Aktion statt eines Würfelwurfs bei der Erzeugung, Tab-UI pro Lebensphase, neue "Als Christ"-Phase. §3–§7 unten beschreiben teils noch den v3-Stand (Katalog-Tabelle, Reveal-Mechanik) – §12 fasst zusammen, was sich geändert hat; der Code in `npc_backstory.dart` ist die verbindliche Quelle.

**Code:** `lib/src/features/game/domain/models/npc_backstory.dart` (Katalog, Generator, `NpcBackstory`, `OccurredEvent.advanceWork`), `lib/src/core/utils/stable_hash.dart` (gemeinsam mit `NpcNeed` genutzt), Verdrahtung in `npc_registry.dart`/`npc_component.dart`/`spirit_world_game.dart` (Glaube-Offset, Christ-Phase-Trigger, Persistenz des Bearbeitungs-Fortschritts), `building_interaction_service.dart` (Wohlstands-Modifier), Tab-UI in `game_screen.dart` (`_NpcBackstoryPanel`). Tests: `test/features/game/domain/models/npc_backstory_test.dart`, plus Ergänzungen in `npc_registry_test.dart` und `building_interaction_service_test.dart`.

## 1. Idee

Ein echtes, kleines NPC-Lebens-/Emotionssimulationssystem: Jede NPC durchläuft bei der Generierung ihre drei Lebensphasen (Kindheit → Jugend → Jetzt) **der Reihe nach**. Was in einer frühen Phase passiert, verschiebt die Wahrscheinlichkeiten der folgenden Phasen – eine unverarbeitete schwere Kindheit macht spätere Abwärtsspiralen (Sucht, Straffälligkeit) wahrscheinlicher und stabile Beziehungen/beruflichen Erfolg unwahrscheinlicher, genau wie im Beispiel beschrieben. Trotzdem bleibt alles eine einmalige, deterministische Berechnung ohne neuen Spielzustand – wie das Bedürfnis aus #171.

## 2. Phasen & Kategorien

Phasen: Kindheit → Jugend → Jetzt (fest für alle NPCs, siehe v2 §7 zur Begründung).

Kategorien: Glaube, Geld/Beruf, Beziehung, Verlust, Gesundheit (inkl. Sucht/Straffälligkeit – siehe Katalog).

## 3. Ereignis-Katalog (gewichtet, nicht mehr nur Valenz)

Jedes Ereignis ist jetzt ein **benannter Eintrag mit eigener Stärke** (−10 bis +10) statt nur "positiv/negativ". Kleine, überschaubare Liste – Daten, kein Fließtext:

| Kategorie | Ereignis | Glyphe | Stärke | Phasen | Anfälligkeits-sensitiv? |
| :--- | :--- | :--- | ---: | :--- | :--- |
| Beziehung | Vernachlässigung / wenig Liebe | 😠 | −4 | Kindheit | nein |
| Beziehung | Trennung der Eltern | 💔 | −5 | Kindheit, Jugend | nein |
| Beziehung | Gescheiterte Beziehung | 💔 | −5 | Jugend, Jetzt | leicht |
| Beziehung | Geborgene Kindheit | 🤱 | +4 | Kindheit | invers |
| Beziehung | Erste große Liebe | 💞 | +4 | Jugend | invers |
| Beziehung | Glückliche Beziehung | 💑 | +6 | Jetzt | invers |
| Verlust | Verlust eines Elternteils | ⚰️ | −7 | alle | nein |
| Verlust | Verlust durch Gewalt (angedeutet) | 🕯️ | −8 | Jugend, Jetzt | nein |
| Verlust | Schwere Krankheit in der Familie | 🏥 | −5 | alle | nein |
| Gesundheit | Leichte gesundheitliche Sorgen | 🤒 | −2 | alle | nein |
| Gesundheit | Alkoholmissbrauch | 🍺 | −6 | Jugend, Jetzt | **ja** |
| Gesundheit | Drogen | 💉 | −8 | Jugend, Jetzt | **ja** |
| Gesundheit | Straffälligkeit / Gefängnis | 👊 | −7 | Jugend, Jetzt | **ja** |
| Gesundheit | Robuste Gesundheit | 💪 | +2 | alle | invers |
| Geld | Arbeitslosigkeit | 📉 | −4 | Jugend, Jetzt | leicht |
| Geld | Insolvenz / Schulden | 💸 | −5 | Jetzt | leicht |
| Geld | Beruflicher Erfolg | 💼✨ | +5 | Jugend, Jetzt | invers |
| Geld | Erbschaft / Wohlstand | 💰 | +4 | Jetzt | nein |
| Glaube | Enttäuschung von der Kirche | ✝️💔 | −5 | alle | nein |
| Glaube | Unbeantwortetes Gebet | 🙏💔 | −4 | alle | nein |
| Glaube | Bekehrungserlebnis | ✝️✨ | +6 | alle | nein |
| Glaube | Erhörtes Gebet / Wunder | 🙏✨ | +5 | alle | nein |

**"Anfälligkeits-sensitiv"** = die Wahrscheinlichkeit dieses konkreten Ereignisses steigt mit der `vulnerability` der NPC (s. §4). **"invers"** = sinkt stattdessen mit steigender `vulnerability` (positive Ereignisse werden unwahrscheinlicher, je belasteter die NPC ist – genau das im Beispiel beschriebene "weniger wahrscheinlich für ganze Beziehungen, Erfolg im Job"). Startwerte, über `GameBalance` (#83) tunbar.

## 4. Generierung: sequenziell mit Anfälligkeit

Zwei laufende Größen, beide bei 0 startend, nur während der einmaligen Generierung existent (nicht Teil des dauerhaften NPC-Zustands):

- **`vulnerability`** – wächst vor allem durch **unverarbeitete** negative Ereignisse, wächst kaum bei durchgearbeiteten.
- **`resilience`** – wächst durch durchgearbeitete negative Ereignisse (posttraumatisches Wachstum).

Ablauf je Phase (Kindheit → Jugend → Jetzt, in dieser Reihenfolge – die Reihenfolge ist entscheidend, jede Phase liest die `vulnerability`, die die vorherigen Phasen hinterlassen haben):

```
für jede Kategorie in dieser Phase:
  passiert etwas? (Basis-Chance je Kategorie)
    → wenn ja: negativ oder positiv, gewichtet nach vulnerability
       (hohe vulnerability begünstigt anfälligkeits-sensitive negative
        Ereignisse wie Drogen/Alkohol/Gefängnis und benachteiligt
        inverse positive Ereignisse wie Erfolg/Beziehung)
    → bei negativem Ereignis: durchgearbeitet? (Chance sinkt mit Phase-
       Nähe zur Gegenwart UND mit bereits hoher vulnerability – wer schon
       stark belastet ist, verarbeitet Neues schwerer)
       → durchgearbeitet:      vulnerability += Stärke × 0.15,  resilience += Stärke × 0.3
       → nicht durchgearbeitet: vulnerability += Stärke × 0.6
    → bei positivem Ereignis:  vulnerability -= Stärke × 0.1
```

Rein deterministisch: ein lokaler, aus der NPC-`id` abgeleiteter Zufallsgenerator (wie beim bestehenden `need`), verbraucht keine geteilte RNG-Sequenz, keine Nebenwirkung auf Weltgenerierung. Einmalig berechnet (`late final`), nicht persistiert.

**Beispiel, genau wie beschrieben:** Kindheit → "Vernachlässigung/wenig Liebe" (−4), nicht durchgearbeitet → `vulnerability` steigt spürbar. In der Jugend sind dadurch "Alkoholmissbrauch"/"Drogen"/"Straffälligkeit" wahrscheinlicher (anfälligkeits-sensitiv) und "Erste große Liebe"/"Beruflicher Erfolg" unwahrscheinlicher (invers) – ohne dass das irgendwo hart verdrahtet wurde, es folgt allein aus der einen laufenden Zahl.

## 5. Sollen NPCs genau dieselben Ressourcen wie der Pastor haben?

**Meine Empfehlung: Nein – nur Glaube bleibt eine echte, persistente Ressource. Geld wird ein abgeleiteter Wert, Gesundheit/Hunger bleiben reine Erzähl-Varianz ohne eigenen Ressourcen-Haushalt.**

Begründung:
- **Glaube** existiert bei NPCs bereits, wird an vielen Stellen gebraucht (Bekehrung, `interactionScore`, Zell-Einfluss) – klarer Fall, bleibt.
- **Materialien/Geld** als echte, tickende Ressource bräuchte einen eigenen Haushalt (Einnahmen/Ausgaben) für potenziell tausende NPCs in der Stadt, plus UI, die diesen Wert überhaupt zeigt – aktuell gibt es keine Spielmechanik, die eine "NPC hat X Materialien"-Zahl konsumiert, nur die *Chance*, dass sie bei einem Hausbesuch etwas spendet. Diese Chance kann direkt aus dem generierten Geld-Kategorie-Ergebnis abgeleitet werden ("Wohlstands-Modifier"), ohne dass dafür ein echter, laufender Ressourcen-Wert existieren muss.
- **Gesundheit/Hunger** haben bei NPCs aktuell keinen einzigen Verbraucher (der Spieler füttert oder heilt keine NPCs). Ein eigener Haushalt dafür wäre Komplexität ohne Gegenstück im Spiel.
- **Performance:** Nur NPCs mit `NPCDetailLevel.high` (nahe am Spieler) bekommen überhaupt laufende Logik; ein tickender 4-Ressourcen-Haushalt für alle generierten NPCs der Stadt wäre unnötiger Rechenaufwand für etwas, das der Spieler nie sieht.

Kurz: die *Wirkung* soll dieselbe Sprache sprechen wie die Pastoren-Ressourcen (das war dein Kernpunkt), aber nur Glaube muss dafür wirklich eine zweite, tickende Ressource sein. Alles andere bleibt ein bei der Generierung einmal berechneter Wert, der bestehende Mechaniken einfärbt.

## 6. Mechanische Wirkung

- **Glaube:** Summe der Glaube-Kategorie-Stärken (skaliert) verschiebt den `faith`-Basiswert bei Generierung.
- **Geld (Wohlstands-Modifier):** Summe der Geld-Kategorie-Stärken verschiebt die bestehende Spendenchance in `houseVisit`/`requestDonation` – kein neuer Ressourcen-Haushalt, nur ein Faktor auf einen bereits vorhandenen Würfel.
- **`resilience`:** dämpft allgemein negative Interaktions-Ausschläge (z. B. −8 bei abgelehntem Gebet) – eine NPC, die ihre Vergangenheit verarbeitet hat, reagiert stabiler, unabhängig vom Thema.
- **`vulnerability`:** optionaler Zusatz-Hebel für später (z. B. höhere `wantsGift`-Chance, leicht höhere Ablehnungs-Chance bei Gebet) – nicht zwingend für v1, aber naheliegend, da der Wert ohnehin existiert.

## 7. Aufdeckung – unverändert aus v2

Ein gemeinsamer Fortschritt, keine getrennten Kanäle: Wiederverwendung von `interactionCount` + `isFaithVague`/`isFaithRevealed` (3/6). Seelsorge (+6) vs. Gespräch (+1) bildet "bringt mehr, kostet mehr" bereits ab. Vage (💭) ab 3, alle generierten Ereignisse als Emoji+Glyphe (Kategorie-Glyphe aus der Tabelle + 🌱/🌫️ bei negativ) ab 6, mit Kurz-Label ("Kindheit · Beziehung").

## 8. Änderungsverlauf

- **v1 → v2:** Ausgeschriebener Text → Emoji-Sätze; getrennte Kanäle → ein gemeinsamer Fortschritt (Wiederverwendung `isFaithVague`/`isFaithRevealed`); flacher Kartenpool → Phasen × Kategorien.
- **v2 → v3 (dieses Update):** Flache Valenz (nur positiv/negativ) → benannter, gewichteter Ereignis-Katalog mit eigener Stärke pro Ereignis; unabhängige Phasen-Würfe → sequenzielle Generierung, bei der `vulnerability` aus früheren Phasen die Wahrscheinlichkeiten späterer Phasen verschiebt (echte Verlaufs-Simulation); neu beantwortet: Ressourcen-Frage (§5, Empfehlung gegen volle 4-Ressourcen-Spiegelung).

## 9. Umsetzungsschritte (nach Freigabe)

1. `LifeEvent`-Katalog als const-Liste (Tabelle aus §3) im Domain-Modell.
2. Sequenzielle, deterministische Generierung (lokaler `Random` aus ID-Hash) mit `vulnerability`/`resilience`-Tracking – `late final` Getter auf `NPCModel`, kein neuer Save-Zustand.
3. Wirkung: `faith`-Offset, Wohlstands-Modifier in `building_interaction_service.dart`, Resilienz-Dämpfung in den negativen Interaktionspfaden.
4. UI: 💭 ab `isFaithVague`, generierte Ereignisse (Glyphe + Kurz-Label) ab `isFaithRevealed`.
5. Tests: Katalog-Konsistenz, deterministische Generierung, Kaskaden-Effekt (belegen: hohe `vulnerability` aus Phase 1 erhöht messbar die Wahrscheinlichkeit anfälligkeits-sensitiver Ereignisse in Phase 2/3), Resilienz-Dämpfung, Wohlstands-Modifier.

## 10. Akzeptanzkriterien (Entwurf)

- [ ] Ereignisse sind gewichtet (eigene Stärke pro Ereignis, nicht nur positiv/negativ)
- [ ] Reihenfolge Kindheit→Jugend→Jetzt ist kausal: frühe unverarbeitete negative Ereignisse erhöhen messbar die Wahrscheinlichkeit späterer anfälligkeits-sensitiver negativer Ereignisse und senken die inverser positiver Ereignisse
- [ ] Durchgearbeitete Ereignisse erhöhen `resilience` spürbar stärker als `vulnerability`
- [ ] Nur Glaube ist eine echte, persistente NPC-Ressource; Geld bleibt ein abgeleiteter Modifier ohne eigenen Haushalt
- [ ] Aufdeckung nutzt weiterhin ausschließlich `interactionCount`/`isFaithVague`/`isFaithRevealed`
- [ ] Keine Änderung am Save-Schema nötig
- [ ] Unit-Tests für Katalog, Kaskade, Resilienz, Wohlstands-Modifier

## 11. Offene Fragen für später

- `vulnerability` als zusätzlicher Live-Hebel (§6, letzter Punkt) – bewusst optional gehalten, um v1 nicht zu überladen.
- Altersabhängige Phasenzahl (siehe v2 §7).
- Content-Filter für Store-Freigabe, sobald #95/#153 entschieden sind.

## 12. v4 — Rückmeldung aus dem ersten Live-Test

Nach dem ersten Deploy (Web-Build, testbar ohne am Rechner zu sein) kam konkretes Feedback, das v3 an mehreren Stellen korrigiert:

1. **Zu wenig "normale" Füll-Ereignisse.** v3s Katalog wirkte gefühlt, als wäre "jeder ein Drogenabhängiger" – es fehlten Alltags-Ereignisse (Spielplatz, Schule, Sportverein, normaler Job, Kindergottesdienst …). Katalog fast verdoppelt (§3 der Tabelle im Dokument ist damit veraltet, siehe Code), neues `LifeEvent.baseWeight` macht dramatische Ereignisse (Sucht, Straffälligkeit, gewaltsamer Verlust) explizit selten (<5 % aller Ereignisse, statistisch getestet), unabhängig von der `vulnerability`-Gewichtung.
2. **Jede Lebensphase sollte etwas erzählen.** `categoryEventChance` erhöht plus eine Mindest-Ereignis-Garantie pro Phase – kein Tab bleibt mehr leer (getestet über 500 NPCs).
3. **"Verarbeiten" ist eine Spieler-Aktion, kein Würfelwurf.** Größte Änderung: `OccurredEvent.processed`/`workProgress` sind jetzt **mutable und persistiert** (nicht mehr nur `NpcBackstory` selbst deterministisch aus der id). Ein negatives Ereignis startet immer unverarbeitet; der Spieler "bearbeitet" es aktiv (🗣️-Tipp im Dialog, kostet Gesundheit wie Seelsorge), braucht mehrere Einheiten (`OccurredEvent.workRequired`), bis es als verarbeitet gilt. `vulnerability`/`resilience` sind dadurch **live berechnete Getter** auf `NpcBackstory`, keine bei der Generierung eingefrorenen Werte mehr – Resilienz wächst tatsächlich mit jedem bearbeiteten Ereignis. Das bricht mit v1–v3s Versprechen "keine Save-Änderung nötig": der Bearbeitungs-Fortschritt wird jetzt sparse persistiert (`{eventId: workProgress}`, nur für Ereignisse mit Fortschritt), alles andere bleibt weiterhin aus der id ableitbar.
4. **Neue "Als Christ"-Phase.** Ein vierter Tab, der erst erscheint, sobald die NPC bekehrt ist (`NpcBackstory.ensureChristPhaseFor`, an allen drei Stellen verdrahtet, an denen `isConverted` wahr werden kann: Spawn, Live-Bekehrung, Save-Restore). Eigener kleiner Katalog (`kChristPhaseCatalog`), überwiegend positiv.
5. **UI: Tabs statt flacher Liste.** `_NpcBackstoryPanel` (`game_screen.dart`) zeigt Kindheit/Jugend/Jetzt/(Als Christ) als Tabs, die schrittweise anhand von `interactionCount`-Schwellen freigeschaltet werden (3/6/9; "Als Christ" ohne Schwelle, sobald bekehrt). Gesperrte Tabs zeigen ein 🔒. Innerhalb eines Tabs: Emoji-Chip je Ereignis, unverarbeitete negative Ereignisse haben ein 🗣️ zum Bearbeiten.

**Bewusst nicht mit umgesetzt:** eine dedizierte "bearbeiten"-Interaktion außerhalb des Dialogs (z. B. eigener Seelsorge-Modus, der gezielt ein Ereignis adressiert) – aktuell ist es ein einfacher Tap auf den Chip, unabhängig vom sonstigen Gesprächsverlauf. Reicht für v4, kann später verfeinert werden.

### v4.1 — Nachbesserung: "Als Christ" füllt sich langsam, durch Verarbeitung

Weitere Rückmeldung nach v4: Der "Als Christ"-Tab füllte sich sofort bei der Bekehrung mit bis zu drei Ereignissen aus `kChristPhaseCatalog` – sollte aber langsam wachsen, "vielleicht gerade durch aufgearbeitete Herausforderung".

- `NpcBackstory.ensureChristPhaseFor` markiert die Phase jetzt nur noch als **freigeschaltet** (`christPhaseUnlocked`), fügt aber **keine** Ereignisse mehr hinzu. Der Tab ist ab der Bekehrung sichtbar, aber leer ("– nichts Besonderes –").
- Neue Methode `NpcBackstory.workOn(occurred, npcId, isConverted:)`: schließt die Bearbeitung eines Ereignisses ab (`advanceWork`) und wächst bei Abschluss — **nur wenn die NPC bereits bekehrt ist** — die "Als Christ"-Phase um genau einen deterministischen Eintrag aus `kChristPhaseCatalog`, gewählt anhand von NPC-id + der gerade bearbeiteten Herausforderung (gleiche Herausforderung → gleicher Wachstums-Eintrag) und gewichtet nach der aktuellen `vulnerability` (eine noch unsichere NPC neigt zu den zweifel-lastigen Einträgen des Katalogs, eine gefestigtere zu den Gemeinschafts-/Wachstums-Einträgen).
- `NPCModel.workOnBackstoryEvent` ist jetzt der einzige Weg, wie die UI ein Ereignis bearbeitet – ruft `backstory.workOn` auf, nicht mehr `occurred.advanceWork()` direkt.
- Persistenz erweitert: `captureProgress()`/`restoreProgress()` sichern jetzt zusätzlich, welche "Als Christ"-Einträge bereits gewachsen sind (`christEvents`-Liste neben der bestehenden `work`-Fortschrittskarte), da diese Einträge – anders als alles sonst an der Backstory – nicht mehr rein aus der id ableitbar sind, sondern vom tatsächlichen Spielverlauf abhängen.

### v4.2 — Nachbesserung: Erkenntnis-Belohnung fürs Bearbeiten

Frage nach v4.1: "Gibt das dann Erkenntnispunkte?" – bis dahin kostete "Bearbeiten" nur Gesundheit und gab außer dem Story-Fortschritt nichts zurück.

- `NpcBackstory.workOn` gibt jetzt einen Record `({bool completed, bool christGrowth})` zurück statt nur `bool`, damit der Aufrufer (die UI) weiß, *wie* die Bearbeitung abgeschlossen wurde.
- `_NpcBackstoryPanelState._workOn` vergibt bei Abschluss (`completed == true`) **+0,2 Erkenntnis** (derselbe Wert, den der Nutzer im #129-Balancing für eine Bekehrung festgelegt hat) – **+0,5 insgesamt**, wenn der Abschluss zusätzlich die Als-Christ-Phase wachsen ließ (`christGrowth == true`, passend zur "mittleren" Belohnungsstufe wie Jüngerschaftsgruppe/Gebetskreis). Kein Teil-Fortschritt gibt etwas – nur der vollständige Abschluss eines Ereignisses.
- Tooltip am 🗣️-Chip zeigt die Erkenntnis-Belohnung jetzt mit an.

### v4.3 — UI-Umbau: Ansprechen in die Aktionsleiste, Glaubens-Kosten, größere Erkenntnis-Wirtschaft

Weitere Rückmeldung: Das 🗣️-Symbol sollte unten bei den anderen Aktions-Symbolen (💬🙏📖👂✝️) auftauchen statt als kleines Icon im Chip versteckt zu sein – "praktisch ein Problem nach dem anderen ansprechen". Dazu: Bearbeiten soll nicht nur Gesundheit, sondern auch etwas Glauben kosten. Und: Bekehrung sowie das vollständige Auflösen aller Herausforderungen einer NPC sollen spürbar mehr Erkenntnis bringen – im Gegenzug die Verstärkung pro Kampf-Upgrade-Stufe etwas moderater.

- **Auswahl statt Direkt-Tap:** Ein Tap auf einen offenen Herausforderungs-Chip in den Tabs *wählt* ihn aus (gelbe Umrandung), löst aber nichts mehr direkt aus. Die eigentliche Aktion ist jetzt ein normaler Chip **🗣️** in der unteren Leiste, neben Sprechen/Seelsorge/Beten/Bibellesen/Bekehren – deaktiviert, solange nichts ausgewählt ist oder Gesundheit/Glauben nicht reichen. Der Chip erscheint nur, wenn die NPC überhaupt mindestens eine offene Herausforderung hat.
- **Kosten:** −6 ❤️ und neu −4 🙏 pro Bearbeitungs-Einheit (`_backstoryWorkHealthCost`/`_backstoryWorkFaithCost` in `_DialogOverlayState`).
- **Neuer Bonus – "alles gelöst":** Wird durch eine Bearbeitung die *letzte* noch offene Herausforderung einer NPC abgeschlossen, gibt es zusätzlich **+0,5 Erkenntnis** on top (`_backstoryInsightOnFullyResolved`). Da neues Als-Christ-Wachstum gelegentlich neue (seltene) Herausforderungen nachliefert, kann dieser Bonus über eine lange Beziehung hinweg mehrfach ausgelöst werden – das ist beabsichtigt.
- **Bekehrung gibt jetzt Erkenntnis:** `_conversionInsightReward = 0.5` in `npc_component.dart` – der im #129-Issue notierte Zielwert (0,2) war nie tatsächlich verdrahtet; jetzt umgesetzt und bewusst höher als eine einzelne Bearbeitung (0,2), da Bekehrung ein selteneres, größeres Ereignis ist.
- **Dämonen-Tötung gibt jetzt Erkenntnis:** `DaemonComponent._killInsightReward` (0,05–0,3, nach Dämon-Stärke skaliert) bei `_explode()` (Liberation) und `_absorb()` (Drain) – nicht bei natürlichem Zerfall oder wenn der Dämon den Spieler trifft.
- **Ausgleich:** `kCombatUpgradeStep` (Verstärkung pro Kampf-Upgrade-Stufe) von 0,1 auf 0,08 gesenkt (`prayer_combat.dart`), damit die zusätzliche Erkenntnis nicht zu einer Kampf-Kraft-Spirale führt. Der Insight-*Preis* pro Stufe (`upgradeInsightCost`, Formel `1.5^Level`) bleibt bewusst unverändert – die Rückmeldung zielte auf die Wirkung der Upgrades, nicht auf ihren Preis.