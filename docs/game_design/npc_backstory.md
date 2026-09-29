# NPC-Vergangenheit: Lebensphasen-Simulation

**Status: v3 umgesetzt.** Katalog, sequenzielle Generierung mit Kaskade, Glaube-Offset, Wohlstands-Modifier, Resilienz-Dämpfung und die Dialog-Anzeige (💭-Hinweis / aufgedeckte Ereignisse) sind implementiert und getestet. Baut auf #171 (Interaktions-Varianz & NPC-Bedürfnisse) auf, ersetzt es nicht. Änderungsverlauf siehe §8.

**Code:** `lib/src/features/game/domain/models/npc_backstory.dart` (Katalog, Generator, `NpcBackstory`), `lib/src/core/utils/stable_hash.dart` (gemeinsam mit `NpcNeed` genutzt), Verdrahtung in `npc_registry.dart` (Glaube-Offset), `building_interaction_service.dart` (Wohlstands-Modifier), `npc_component.dart` (Resilienz-Dämpfung), Anzeige in `game_screen.dart` (`_NpcBackstoryRow`). Tests: `test/features/game/domain/models/npc_backstory_test.dart` (Katalog, Determinismus, Kaskaden-Nachweis), plus Ergänzungen in `npc_registry_test.dart` und `building_interaction_service_test.dart`.

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
