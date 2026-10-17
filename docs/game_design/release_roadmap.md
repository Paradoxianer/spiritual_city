# Release-Weg: Redesign, Spielspaß, nächste Features

**Status: Vorschlag zur Abstimmung.** Klammer über `core_loop_and_retention.md` (Warum), `mobile_ui.md` (Touch-Regeln) und die Feature-Dokumente. Dieses Dokument legt fest, **in welcher Reihenfolge** wir bis zum Release vorgehen und **was** wir dafür in Code und Design grundsätzlich ändern.

---

## 1. Ausgangslage

**Was gut ist**
- Zwei Welten (real / unsichtbar) sind ein starkes, eigenständiges Konzept.
- Die Lebensgeschichten (📜, `npc_backstory.md` v5) machen NPCs zum ersten Mal zu Individuen.
- Touch-Grundlagen (Pause-Menü, Zurück-Taste) und der Seed stehen.

**Was bremst**

| Bereich | Befund |
| :--- | :--- |
| **Code** | `game_screen.dart` 5800 Zeilen / 69 Klassen, `spirit_world_game.dart` 2500 Zeilen. Aktionen sind Strings (`'talk'`, `'counsel'` … an 27 Stellen). Kosten stehen doppelt: in der Logik (`FaithCalculatorService`, `NPCComponent`) **und** handgeschrieben in der UI (`_isChipActionDisabled`, Hinweis-Strings wie `'−8📦→✝️'`). |
| **UI** | Fünf verschiedene "Aktion antippen"-Widgets (#185), jedes Overlay mit eigenen Rändern, Farben und Disabled-Logik. NPC-Dialog, Gebäude und Radialmenü fühlen sich wie drei verschiedene Spiele an. |
| **Ressourcen** | Fünf Werte (Glaube, Gesundheit, Versorgung, Vorräte, Erkenntnis). Versorgung und Gesundheit sind vor allem Pflege-Arbeit (essen, schlafen) und konkurrieren mit dem eigentlich zentralen Glauben. |
| **Ziel** | Es gibt keine Etappe, die man in einer Session erreicht. Der Sieg "ganze Stadt" ist zu weit weg. Es gibt keinen natürlichen Haltepunkt. |
| **Verbindung** | Die Systeme stehen nebeneinander: Gespräche, Kampf, Gebäude, Missionen. Wenig, was im einen passiert, verändert das andere sichtbar. |

---

## 2. Grundlegendes Redesign der Codebase / UI

Ziel: **Eine Aktion = eine Definition = ein Widget = ein Ausführungsweg.** Die Spielmechanik ändert sich dabei nicht.

### 2.1 Ein Aktions-Modell statt Strings

```dart
enum Resource { faith, health, supplies, materials, insight }

class GameAction {
  final ActionId id;                 // enum statt 'talk'/'counsel'
  final String emoji;
  final Map<Resource, double> cost;  // Quelle für Prüfung UND Anzeige
  final String effectHint;           // z. B. '✝️' oder '🌱'
  final int sessionPoints;           // 1 für fast alles, Seelsorge 2
  ...
}
```

- **Eine Registry** pro Kontext: `npcActions`, `buildingActions(type)`, später `radialActions`.
- **Kostenhinweis wird generiert** (`−5🙏 −2❤️ → 🌱`), damit Anzeige und Logik nicht mehr auseinanderlaufen.
- **Verfügbarkeit** kommt aus einer Funktion `availability(state) → ok | disabled(Grund)`. Der Grund wird angezeigt, statt dass ein Knopf nur grau wird.
- **Ausführung in reinen Domain-Services** (`NpcInteractionService` analog zum bestehenden `BuildingInteractionService`), testbar ohne Flame. `NPCComponent.handleInteraction` schrumpft auf "Service aufrufen, Ergebnis anwenden".
- `PlayerResources` (ein Objekt mit `canAfford(cost)`, `spend(cost)`) ersetzt die verstreuten `spendFaith`/`gainHealth`/`health <= x`-Prüfungen.
- Alle Balancing-Zahlen in `GameBalance` (#83).

### 2.2 Ein Widget-Satz

| Neu | Ersetzt |
| :--- | :--- |
| `ActionButton` (Emoji, generierter Kostenhinweis, Zustände aktiv / gesperrt mit Grund / hervorgehoben, Tasten-Badge) | `_EmojiChip`, `_ActionMenuRow`, `_BuyButton`, Inhalt von `_AttackTile` und `RadialAction` |
| `OverlayShell` (Kopf mit Emoji/Name/Sitzungspunkten, Tabs optional, Inhalt, Aktionsleiste unten, Schließen, SafeArea, Scroll bei wenig Höhe) | eigene Hüllen von NPC-Dialog, Gebäude, Missionsboard, Upgrade, Look, Keymap, Pause |
| `EmojiTimeline` | `_NpcLifeTimeline` (später auch für Gebäude-Chronik und Gemeinde) |

**Gleiches Bedienmuster überall:** Oben steht, *wer oder was* das ist, in der Mitte *was man weiß*, unten *was man tun kann*. NPC-Dialog und Gebäude-Innenraum werden damit dieselbe Art Bildschirm. Die Gebäude-Liste (`_ActionMenuRow`) wird zur gleichen Knopfleiste wie im NPC-Dialog.

### 2.3 Dateistruktur

```
presentation/
  game_screen.dart          (nur noch Overlay-Verdrahtung, Ziel < 400 Zeilen)
  overlays/  npc_dialog/ building/ missions/ upgrades/ pause/ tutorial/ win/ look/
  hud/       resource_hud, combat_hud, toasts
  widgets/   action_button, overlay_shell, emoji_timeline, resource_bar
domain/
  actions/   game_action, npc_actions, building_actions
  services/  npc_interaction_service (neu), building_interaction_service, …
  balance/   game_balance.dart
```

`spirit_world_game.dart` gibt ab: Ressourcen (`PlayerResources`), Speichern/Laden (`SaveService`), Sieg/Etappen (`ProgressTracker`), Overlay-Steuerung (`OverlayController`).

### 2.4 Vorgehen ohne Big Bang

1. `GameAction` + `PlayerResources` + `ActionButton` + Tests. Den NPC-Dialog als Erstes umstellen.
2. Gebäude-Innenraum auf dieselben Bausteine umstellen, `_ActionMenuRow` löschen.
3. `OverlayShell` einführen, dann ein Overlay pro PR in eigene Dateien verschieben.
4. `spirit_world_game.dart` aufteilen.

Jeder Schritt ist ein eigener PR mit grünen Tests und ohne Änderung an der Spielmechanik.

---

## 3. Was das Spiel fesselnder macht

Drei Hebel, alle auf vorhandenen Systemen aufgebaut, nichts völlig Neues.

### 3.1 Menschen statt Zähler: Wunden verbinden die zwei Welten

Die Lebensgeschichte wird zum Scharnier zwischen realer und unsichtbarer Welt:

- **Unverarbeitete schwere Wunden erzeugen Dämonen.** 🍺 ruft einen "Sucht"-Dämon in der Nähe der Person hervor, 💔 einen "Verbitterungs"-Dämon. Der Dämonentyp (#178) kommt also aus der Geschichte der Menschen.
- **Beide Welten wirken aufeinander:** Wer den Dämon in der unsichtbaren Welt besiegt, für den ist die Wunde im Lebensgespräch leichter zu bearbeiten (ein Schritt weniger). Ist die Wunde verarbeitet, spawnt der Dämon nicht mehr.
- **Besessenheit (#180)** ist dann einfach eine Person mit vielen offenen schweren Wunden. Man sieht ihre Aura und weiß, warum sie so ist.

So hat jeder Kampf ein Gesicht und jedes Gespräch eine Auswirkung im Kampf. Das ist Design-Säule 2 ("Zwei Welten, ein Kreislauf") konkret gemacht.

### 3.2 Die Gemeinde wächst: geheilte Menschen heilen andere

- Bekehrte NPCs erhalten Rollen (#181). Neu ist der **"verwundete Heiler"**: Wer eine Wunde verarbeitet hat (z. B. `💔→🌱`), kann zu einer anderen Person mit derselben Wunde geschickt werden und dort selbst einen Bearbeitungsschritt leisten.
- Dadurch wird jede geheilte Lebensgeschichte zu einer **Ressource**, die man einsetzen kann. Der Spieler baut ein Netz aus Menschen, deren Geschichten er kennt, statt nur einen Zähler hochzutreiben.
- Gemeinde-Übersicht (📜 mit allen Christen) als eigener Bildschirm: Wer ist wer, was hat er überwunden, welche Rolle hat er.

### 3.3 Etappen und ein Tagesrhythmus

- **Stadtteil-Erweckung** (`core_loop_and_retention.md` §3) wird das zentrale Ziel. Jeder Stadtteil hat ein **Bollwerk** (#125) als Höhepunkt: ein starker Dämon, der erst angreifbar ist, wenn genug Menschen im Viertel geheilt oder bekehrt sind.
- **Tag als Session-Einheit:** Schlafen im Pastorenhaus beendet den Tag. Danach kommt die **Tagesbilanz** (heute bekehrt, Geschichten geheilt, Zellen befreit, Fortschritt im Stadtteil). Das ist der natürliche Haltepunkt und zeigt Fortschritt sichtbar (#169 Meilensteine). Sonntag = Gottesdienst-Tag (Kirche wird besonders stark).
- **Freischaltungen statt Prozente** (#179): Die erste Erweckung schaltet Predigen frei (#172), die zweite den verwundeten Heiler usw.

### 3.4 Vereinfachung, damit das Wesentliche zählt

- **Vorschlag: Versorgung und Gesundheit zu einer Ressource "Kraft ❤️" zusammenlegen.** Essen und Schlafen füllen beide Kraft auf. Dann bleibt **Glaube 🙏** die klare Hauptressource, **Kraft ❤️** die Ausdauer, **Vorräte 📦** das Material und **Erkenntnis 📖** der Fortschritt. Das sind vier statt fünf Werte und weniger Pflege-Arbeit. Dämonen bleiben gefährlich: Ihr Treffer kostet Kraft und Glauben.
- Spür-Feedback bei jeder Aktion (Säule 1): Sound (#10), Partikel, Haptik auf dem Handy.

---

## 4. Release-Weg (Meilensteine)

| Meilenstein | Inhalt | Issues |
| :--- | :--- | :--- |
| **M0 – Spielbar auf dem Handy** | PR #184 nach Test mergen (Touch-HUD, Zurück-Taste, Seed, Save-Bugs, Varianz, Lebensgeschichten) | #162 #170 #171 #174–#177 |
| **M1 – Einfach & konsistent** | Redesign §2 (Aktions-Modell, `ActionButton`, `OverlayShell`, Dateien aufteilen), Ressourcen-Vereinfachung §3.4, Tutorial anpassen | #185 #83 #126 #92 |
| **M2 – Der fesselnde Kern** | Dämonentypen + Kombos, Wunden-Dämonen §3.1, Stadtteil-Erweckung + Bollwerk, Tagesbilanz §3.3 | #178 #180 #125 #169 #143 |
| **M3 – Gemeinde** | Rollen, verwundeter Heiler §3.2, Gemeinde-Übersicht, Predigen, Fähigkeiten pro Stufe | #181 #172 #179 #173 |
| **M4 – Release 1.0** | Grafik (Sprites, Distrikt-Identität, Innenräume), Audio, Legal/Datenschutz, Store-Assets, i18n-Audit, Credits | #13 #18 #182 #10 #93 #94 #95 #150 #151 #152 #153 |
| **Nach 1.0** | Cloud-Speicher, reale Städte (OSM), dezente Werbung, Minimap | #165 #166 #128 #164 #146 |

**Warum diese Reihenfolge:** M1 vor M2, weil jedes neue Feature sonst noch eine sechste UI-Variante und noch mehr String-Aktionen erzeugt. M2 vor M3, weil die Gemeinde erst Sinn ergibt, wenn es Etappen gibt, in denen sie hilft. Grafik und Audio kommen bewusst spät: Sie verstärken den Spaß, ersetzen aber keinen fehlenden Kern.

---

## 5. Offene Entscheidungen

1. Versorgung + Gesundheit zu **Kraft** zusammenlegen? (Empfehlung: ja)
2. **Tag als Session-Einheit** mit Tagesbilanz? (Empfehlung: ja, schlafen beendet den Tag, kein Echtzeit-Druck)
3. **Wunden erzeugen Dämonen** als Leitidee für #178/#180? (Empfehlung: ja)
4. Mit M1 direkt starten, bevor #184 gemergt ist? (Empfehlung: erst mergen, dann M1 auf frischem `main`, damit der Umbau nicht auf einem 30-Commit-Branch stapelt)
