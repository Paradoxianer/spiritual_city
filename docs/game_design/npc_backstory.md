# NPC-Vergangenheit: "Lebenskarten"

**Status: Entwurf, wartet auf Rückmeldung.** Noch kein Code, keine Issue-Nummer. Baut direkt auf #171 (Interaktions-Varianz & NPC-Bedürfnisse) auf und ersetzt es nicht.

## 1. Idee

Jede NPC bekommt eine kleine, echte Vergangenheit statt nur eines versteckten Zahlenwerts: ein bis zwei "Vorkommnisse", die erklären, *warum* sie reagiert wie sie reagiert – und die der Spieler erst nach und nach freilegt, getrennt über **Gespräch** (💬, Sprechblase) und **Seelsorge** (👂, Ohr). Das macht jede NPC über die Zeit unterscheidbar, statt dass sich (wie im ursprünglichen Playtest-Feedback) alles gleich anfühlt.

Ausdrücklich **nicht** angestrebt: eine volle Dwarf-Fortress-Historiensimulation mit Ereignissen zwischen NPCs, die sich über Spielzeit weiterentwickeln. Das wäre ein eigenes, monatelanges Projekt. Diese Version ist bewusst kleiner: ein fester Kartenpool, deterministisch zugewiesen, rein narrativ.

## 2. Verhältnis zu #171

| | #171 (Bedürfnis) | Diese Version (Lebenskarten) |
| :--- | :--- | :--- |
| Datenmenge pro NPC | 1 `NpcNeed`-Wert | 1–2 Karten aus einem Pool |
| Wirkung | mechanisch (Ertrags-Multiplikator) | narrativ (Text), **kein** zusätzlicher Multiplikator in v1 |
| Sichtbarkeit | noch nicht verdrahtet | progressiv, pro Kanal getrennt |
| Zweck | löst "immer dieselbe Aktion" | löst "fühlt sich immer gleich an" |

Die Karten geben dem Bedürfnis eine Begründung ("zweifelnd, *weil* …"), ersetzen es aber nicht. Zwei getrennte, additive Systeme statt eines großen Umbaus – geringeres Risiko für das gerade erst gebaute und getestete #171.

## 3. Warum keine Emoji für den Inhalt

Ursprünglich stand in #171 "vage Andeutung (Emoji-Hint)". Das funktioniert für ein Bedürfnis wie "einsam" (🥺), aber nicht für Themen wie Sucht, Scheidung oder einen gewaltsamen Verlust – dafür gibt es kein würdevolles Emoji, ohne entweder zu explizit oder zu albern zu wirken.

**Lösung:** Die vage Stufe nutzt ein **einziges, immer gleiches** Symbol (💭) plus einen kartenunabhängigen Satz ("…da ist etwas, das sie noch nicht erzählen will."). Das Symbol verrät nichts über den Inhalt. Die volle Stufe zeigt den eigentlichen Satz als **reinen Text** in der Dialogblase – genau wie die bereits vorhandenen Tutorial-Texte, keine Emoji-Pflicht. Emoji bleiben dort, wo sie schon funktionieren: als sofortiges Reaktions-Feedback auf eine Aktion (❤️🕊️ bei Gebet usw.), nicht zur Kodierung eines Lebensschicksals.

## 4. Datenmodell (Vorschlag)

```dart
enum LebenskartenKanal { talk, counsel, either }

class BackstoryCard {
  final String id;
  final String category;        // z.B. 'grief', 'doubt', 'addiction'
  final bool isPositive;        // Polung – beeinflusst nur den Ton, nicht die Mechanik (v1)
  final LebenskartenKanal channel;
  final String fullText;        // einmalig gezeigt, sobald voll aufgedeckt
}
```

- **Zuweisung:** 1–2 Karten pro NPC, deterministisch aus einem Hash der NPC-`id` (gleiches Prinzip wie `NpcNeed._stableStringHash`, aber mit anderem Salt, damit Bedürfnis und Karten nicht miteinander korrelieren). Nicht persistiert, wie das Bedürfnis auch – immer neu ableitbar, alte Saves brauchen keine Migration für die Zuweisung selbst.
- **Fortschritt (muss persistiert werden, anders als das Bedürfnis):** Zwei neue, **kumulative** (nicht Session-, sondern Lebenszeit-) Zähler auf `NPCModel`: `talkCount`, `counselCount`. Erhöht bei jeder `talk`- bzw. `counsel`-Interaktion, unabhängig von Session-Grenzen – "jemanden kennenlernen" ist ein Verlauf über viele Besuche, nicht pro Sitzung zurückgesetzt (anders als die Abnutzungs-Zähler aus #171, die bewusst pro Sitzung zurückgesetzt werden). Muss in `captureGameState`/`applySavedNPCState` mitgespeichert werden → Schema-Version-Bump wie bei früheren Änderungen.
- **Schwellen:** vage ab 3, voll ab 6 – dieselben Zahlen wie das bestehende `isFaithVague`/`isFaithRevealed`, aber ein **eigener** Zähler pro Kanal, nicht wiederverwendet (der Glaubens-Reveal bleibt an `interactionCount` gekoppelt, das ist ein anderes Konzept).

## 5. Beispiel-Kartenpool (Entwurf, ~15 Karten)

Ton: angedeutet, nicht ausgeschmückt – passend zu "Erwachsener, aber nicht graphisch". Platzhalter, zur Abstimmung, noch nicht im Code.

| Kategorie | Kanal | Polung | Beispieltext (Entwurf) |
| :--- | :--- | :--- | :--- |
| Trauer | Seelsorge | negativ | "Ihre Mutter ist letzten Winter gestorben. Sie hat noch nicht wirklich darüber gesprochen." |
| Einsamkeit | Gespräch | negativ | "Seit die Kinder ausgezogen sind, ruft kaum noch jemand an." |
| Zweifel | Seelsorge | negativ | "Er hat einmal inbrünstig gebetet, und nichts geschah. Seitdem betet er nicht mehr." |
| Geldsorgen | Gespräch | negativ | "Seit der Kündigung reicht es kaum bis zum Monatsende." |
| Entfremdung | Seelsorge | negativ | "Mit ihrem Bruder hat sie seit Jahren kein Wort gewechselt." |
| Sucht (angedeutet) | Seelsorge | negativ | "Er hat jahrelang gegen die Flasche gekämpft. Manche Tage sind noch schwer." |
| Scheidung | Gespräch | negativ | "Ihre Ehe zerbrach, als die Kinder noch klein waren." |
| Verlust durch Gewalt (angedeutet) | Seelsorge | negativ | "Ihr Bruder kam bei einem Überfall ums Leben. Sie spricht selten darüber." |
| Schuld | Seelsorge | negativ | "Er hat einem alten Freund nie verziehen bekommen, was zwischen ihnen geschah." |
| Verrat | Gespräch | negativ | "In ihrer letzten Gemeinde wurde ihr Vertrauen missbraucht. Seitdem ist sie vorsichtig." |
| Krankheit | Seelsorge | negativ | "Die Diagnose vor zwei Jahren hat vieles verändert, wie er über sein Leben denkt." |
| Erhörtes Gebet | Gespräch | positiv | "Als ihr Sohn schwer krank war, betete die ganze Straße mit ihr. Er wurde gesund." |
| Neuanfang | Gespräch | positiv | "Nach Jahren in der Großstadt ist er hierher gezogen, um noch einmal von vorn zu beginnen." |
| Wunder erlebt | Seelsorge | positiv | "Sie erzählt selten davon, aber sie glaubt, einmal Gottes Eingreifen ganz direkt erlebt zu haben." |
| Handwerk & Stolz | Gespräch | positiv | "Er hat den Laden von seinem Vater übernommen und ist sichtlich stolz darauf." |

**Vage Hinweis-Texte** (immer dieselben zwei, unabhängig von der konkreten Karte):
- negativ: "💭 …da ist etwas, das sie/er noch nicht erzählen will."
- positiv: "💭 …da steckt eine Geschichte dahinter, die sie/er noch nicht ganz erzählt hat."

## 6. Offene Fragen für später (nicht Teil von v1)

- Content-Filter/Einstellung, um die "erwachseneren" Karten (Sucht, Gewalt-Verlust) optional auszublenden, sobald die Altersfreigabe (#95) und der Eltern-Hinweis (#153) geklärt sind.
- Ob eine voll aufgedeckte Karte später einen kleinen mechanischen Bonus geben soll (z. B. einmalig Insight für "jemanden wirklich kennengelernt zu haben") – v1 bleibt bewusst rein narrativ, um nicht zwei Mechaniken (#171 + Karten) gleichzeitig zu balancieren.
- Verknüpfung mit Missionen: eine Tier-2-Kette (#173) könnte an eine voll aufgedeckte Karte anknüpfen ("hilf ihr, sich mit ihrem Bruder zu versöhnen").

## 7. Umsetzungsschritte (nach Freigabe)

1. `BackstoryCard`-Modell + fester Kartenpool (Dart-Konstanten, wie `_MissionTemplate` in `mission_service.dart`).
2. Deterministische Zuweisung auf `NPCModel` (1–2 Karten, eigener Hash-Salt).
3. `talkCount`/`counselCount` auf `NPCModel`, Persistenz in Save/Load (Schema-Bump).
4. Reveal-Logik (vage/voll) + Verdrahtung in den Dialog (Anzeige des Hinweises bzw. Volltexts).
5. Tests: Zuweisung deterministisch, Reveal-Schwellen, Save/Load-Round-Trip der Zähler.

## 8. Akzeptanzkriterien (Entwurf)

- [ ] Jede NPC hat 1–2 Karten, deterministisch aus der ID
- [ ] Gespräch und Seelsorge zählen getrennt, kumulativ über Sitzungen hinweg
- [ ] Vage Stufe ab 3, voll ab 6 – Anzeige ohne kartenspezifisches Emoji
- [ ] Voller Text erscheint genau einmal prominent, danach weiter abrufbar
- [ ] Alte Saves laden ohne Fehler (fehlende Zähler → 0)
- [ ] Unit-Tests für Zuweisung, Schwellen, Persistenz
