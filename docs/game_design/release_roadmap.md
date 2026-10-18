# Release-Weg: Redesign, Spielspaß, nächste Features

**Status: abgestimmt (2026-10-17), Entscheidungen in §5. M1 umgesetzt auf `feat/m1-redesign` (Stand §4.1).** Klammer über `core_loop_and_retention.md` (Warum), `mobile_ui.md` (Touch-Regeln) und die Feature-Dokumente. Dieses Dokument legt fest, **in welcher Reihenfolge** wir bis zum Release vorgehen und **was** wir dafür in Code und Design grundsätzlich ändern.

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

### 3.1 ~~Wunden verbinden die zwei Welten~~ (abgelehnt, siehe §5)

> Entscheidung: Dämonen bleiben unabhängig von den Lebensgeschichten. Die Dämonentypen (#178) und Besessenheit (#180) folgen `daemons_and_combat.md` bzw. `npc_influence.md`. Der ursprüngliche Vorschlag bleibt hier zur Nachvollziehbarkeit stehen.

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

### 3.4 Übung und Beziehung: Gespräche werden mit der Zeit wirksamer

Heute steigert die Anzahl der Interaktionen nur wenig: mehr Sitzungspunkte (`sessionBonus`), eine höhere Annahme-Chance beim Gebet und einen Gebets-Multiplikator. Vorschlag mit zwei getrennten Achsen:

- **Übung (Pastor, je geistlicher Disziplin):** Jede ausgeführte Aktion zählt bei ihrer Disziplin mit: 🙏 Gebet, 📖 Bibel, 💬 Gespräch, 👂 Seelsorge, 🤝 Dienst, 🤲 Anbetung. So zählt z. B. Beten im Pastorenhaus, in Wohnhäusern und beim NPC zur selben Übung. Stufen nach 10 / 30 / 80 / 200 / 400 Anwendungen, jede Stufe **+10 % Wirkung** bis maximal +50 % (bei NPCs auf den Glaubensgewinn der Person, in Gebäuden auf den eigenen Glaubensgewinn). Im Aktions-Knopf als ⭐ angezeigt, eine neue Stufe kommt als Toast `⭐ 🙏 2`. *Umgesetzt (`Practice`).*
- **Beziehung (je NPC):** `interactionCount` wird zur sichtbaren **Beziehungsstufe** (♥ im Dialog-Kopf, gleiche Schwellen wie `sessionBonus`, max. 5). Jede Stufe gibt **+10 %** auf alle Gewinne bei dieser Person. Ab Stufe 3 („tiefes Vertrauen“) zählt ein Lebensgespräch doppelt. *Umgesetzt (`Relationship`).*
- **Was bleibt:** Die abnehmenden Erträge *innerhalb einer Sitzung* (#171) bleiben. Übung macht eine Aktion insgesamt stärker, Abwechslung im einzelnen Gespräch lohnt sich trotzdem.
- Persistenz: ein kleines Zählerfeld je Aktionsart im Spielstand. Die Übung baut auf dem Aktions-Modell aus §2.1 auf (eine `ActionId` statt Strings) und kommt deshalb in M1/M2.

### 3.5 Gebäude betreten und erkunden

Heute öffnet ein Gebäude ein Menü. Vorschlag (Erweiterung von #182, `exploration.md`): Beim Betreten wechselt man in einen **kleinen begehbaren Innenraum** mit derselben Steuerung (Joystick, Interaktion) wie in der Stadt.

- Prozedural aus Gebäudetyp + Gebäude-id (deterministisch wie die Stadt): Wohnung = Flur, Küche, Wohnzimmer; Kirche = Schiff, Altar, Sakristei; Krankenhaus = Flure, Zimmer.
- **Die bestehenden Gebäude-Aktionen werden zu Objekten im Raum:** Bibel auf dem Tisch = Bibel lesen, Bett = Schlafen, Altar = Anbetung, Küche = Essen. Bewohner stehen im Raum und sind normal ansprechbar.
- Kleine eigene Karte (z. B. 12×10 Zellen) in einer eigenen Flame-`World`. Die Stadt wird währenddessen pausiert, die Prozessorlast ist dadurch gering.
- Zu entdecken: zufällige Fundstücke (Loot), Erinnerungsstücke, die ein Ereignis aus der Lebensgeschichte der Bewohner aufdecken, und später verschiedene Einrichtung je Stadtteil.
- Aufwand: groß. Gehört nach M3, weil es Sprites (M4) nicht zwingend braucht, aber vom Aktions-Modell (M1) abhängt.

### 3.6 Lebendige unsichtbare Welt ("wabern")

Heute: Pro Chunk ein Farbraster plus langsam driftende dunkle Kugeln mit Blur (`SpiritualRenderer`). Dieser "Lavalampen"-Effekt ist kaum wahrnehmbar, und der Blur je Chunk ist relativ teuer.

Vorschlag: **ein einziger Fragment-Shader über den ganzen Bildschirm** (Flutter `FragmentProgram`, läuft auf Android/iOS (Impeller) und im Web (CanvasKit)):

- Die Zellzustände der sichtbaren Chunks werden als **kleine Textur** übergeben (1 Pixel je Zelle, nur bei Änderung neu, ≤ 1 Hz wie heute).
- Der Shader verwirbelt diese Textur mit animiertem Rauschen (Domain Warping). Dunkle Bereiche **wabern, ziehen Schlieren und pulsieren langsam**, helle Bereiche schimmern ruhig. Übergänge fließen weich statt Kachel für Kachel.
- Dämonen und Schockwellen werden als wenige Uniforms (Position, Radius, Zeit) übergeben: **Dunkelheit zieht sich zu Dämonen hin**, Schockwellen lassen **sichtbare Licht-Ringe durch das Wabern laufen**.
- **Prozessorlast:** ein einziger Durchgang pro Frame auf der GPU, ohne Blur-Layer je Chunk. Das ist voraussichtlich günstiger als heute. Schutz für schwache Geräte: Shader in halber Auflösung rendern, Qualitätsstufe "Effekte: niedrig" fällt auf den heutigen Renderer zurück, Messung mit dem Flutter-Performance-Overlay auf einem Mittelklasse-Handy vor dem Merge.
- Gehört nach M2, weil die unsichtbare Welt zum Kern gehört.

### 3.7 Grafik und Sound

- **Grafik:** Kenney-Pakete unter CC0 (gemeinfrei, keine Namensnennung nötig, kommerziell erlaubt): *Roguelike Modern City* (über 1000 Tiles: Straßen, Gebäude, Details) und *RPG Urban Pack* (480 Tiles, Fahrzeuge, 6 Figuren mit Laufanimation). Beide sind Draufsicht und passen zum Raster (#13, #18).
- **Sound:** Die Pixabay-API liefert mit einem normalen Schlüssel nur Bilder und Videos. Der Audio-Endpunkt antwortet mit 403 und braucht eine Freigabe für den vollen API-Zugang. Alternative: Kenney-Audiopakete unter CC0 (*Interface Sounds*, *UI Audio*, *Impact Sounds*, *RPG Audio*) für Klicks, Treffer und Effekte. Für Musik und Glocken einzelne Pixabay-Sounds von Hand auswählen; die Pixabay-Lizenz erlaubt die Nutzung im Spiel.
- Lizenzen jedes Pakets in `assets/LICENSES.md` festhalten (Credits-Screen #151).

### 3.8 Vereinfachung, damit das Wesentliche zählt

- ~~**Vorschlag: Versorgung und Gesundheit zu einer Ressource "Kraft ❤️" zusammenlegen.**~~ *Abgelehnt: Die fünf Ressourcen bleiben getrennt.* Ursprünglicher Vorschlag: Essen und Schlafen füllen beide Kraft auf. Dann bleibt **Glaube 🙏** die klare Hauptressource, **Kraft ❤️** die Ausdauer, **Vorräte 📦** das Material und **Erkenntnis 📖** der Fortschritt. Das sind vier statt fünf Werte und weniger Pflege-Arbeit. Dämonen bleiben gefährlich: Ihr Treffer kostet Kraft und Glauben.
- Spür-Feedback bei jeder Aktion (Säule 1): Sound (#10), Partikel, Haptik auf dem Handy.

### 3.9 Lern-Missionen: Fähigkeiten in Häusern finden (Jüngerschaft)

Idee (2026-10-17): Fähigkeiten wie Seelsorge, geistlicher Kampf oder Unterscheidung der Geister bekommt man nicht über Stufen. Man findet sie als **Lern-Missionen in bestimmten Häusern**, bei einem Mentor (ein bekehrter NPC, ein Mönch im Kloster, eine alte Beterin im Wohnhaus).

**Warum das passt:**
- Es ist **qualitativer Fortschritt** statt Prozente (#179, §3.3 "Freischaltungen statt Prozente"). Jede Mission schaltet etwas Sichtbares frei.
- Es gibt einen **Grund zum Erkunden**: Häuser werden interessant (§3.5), und man sucht gezielt nach Mentoren.
- Es ist ein **eingebautes Tutorial**: Ein System wird erst erklärt und freigeschaltet, wenn man es lernt. Am Anfang ist das Spiel kleiner und leichter zu verstehen, das hilft auch M1 (einfach & konsistent).
- Es passt zum Thema: Jüngerschaft, also von anderen lernen, statt allein Punkte zu sammeln.

**Beispiele (Startideen):**

| Lern-Mission | Wo | Schaltet frei |
| :--- | :--- | :--- |
| 🎓🫂 Seelsorge lernen | Pastorenhaus / erfahrener Christ | Tab 📜 Lebensgespräch (heute sofort verfügbar) |
| 🎓⚔️ Geistlicher Kampf | Kirche | Weitere Kampfmodi nach Liberation (Rebuke, Slow, Drain) |
| 🎓👁️ Unterscheidung der Geister | Kloster / Mentor | **Dämonenarten werden angezeigt** (Symbol über dem Dämon, #178). Ohne diese Fähigkeit sieht man nur "einen Dämon". |
| 🎓🙏 Fürbitte | Wohnhaus einer Beterin | Investitions-Aktion Fürbitte (`progression_and_unlocks.md` §3) |
| 🎓🍞 Fasten | Kloster | Investitions-Aktion Fasten |
| 🎓📢 Predigen | Kirche, nach erster Stadtteil-Erweckung | Predigen (#172) |

**Ablauf (einfach):** Mentor ansprechen → kurzer Lehrtext (2–3 Sätze, mit Bibelstelle) → eine kleine Übungsaufgabe mit den vorhandenen Systemen (z. B. "bearbeite eine Wunde im Lebensgespräch", "besiege 3 Dämonen mit Rebuke") → Fähigkeit frei, mit ⭐ im Aktions-Knopf markiert. Die Lern-Missionen sind ein eigener Missionstyp in `MissionService`, kein neues System.

**Text und Lokalisierung:** Hier ist Text sinnvoll und gewollt. Lehrinhalte lassen sich nicht mit Emojis erklären. Damit der Aufwand klein bleibt:
- Text **nur im Lehrmoment** (wie Tutorial und Menüs über `AppStrings`). Die Aufgabe selbst und das Spiel bleiben Emoji (`🎓⚔️ 0/3 👹`).
- Etwa 6–10 Missionen mit je 2–3 Sätzen, also rund 30 Strings je Sprache.
- **Bibelstellen** (z. B. 1. Kor 12,10 für Unterscheidung der Geister) kommen aus gemeinfreien Übersetzungen je Sprache (Luther 1912, KJV) und müssen nicht übersetzt werden, nur ausgewählt.

**Einordnung:** Den Rahmen (Missionstyp, Mentor, Freischaltung) zusammen mit den Dämonentypen in **M2** bauen, weil "Unterscheidung der Geister" die Dämonenarten sichtbar macht. Die übrigen Lern-Missionen kommen in **M3** zusammen mit den Fähigkeiten pro Stufe (#179).

**Entscheidung (2026-10-17):** **Neue Spielstände lernen, bestehende behalten alles.** Ein neuer Spielstand startet mit 💬 👂 🙏 📖 📦 ✝️🕊️ und dem Kampfmodus Befreiung. 📜 Lebensgespräch, Zurechtweisung/Verlangsamung/Entziehung und die Dämonenarten kommen über Lern-Missionen. Spielstände von vor der Einführung bekommen beim Laden alle Fähigkeiten als gelernt (Feld `learnedSkills` fehlt → alles gelernt). Begründung: Für Einsteiger wird der Anfang kleiner und jede Fähigkeit bekommt einen Moment, in dem sie erklärt wird (das ersetzt Teile des Tutorials #92). Bestandsspieler verlieren nichts, was sie schon nutzen. Das passt zur Säule "Freischaltungen statt Prozente".

---

## 4. Release-Weg (Meilensteine)

| Meilenstein | Inhalt | Issues |
| :--- | :--- | :--- |
| **M0 – Spielbar auf dem Handy** | PR #184 nach Test mergen (Touch-HUD, Zurück-Taste, Seed, Save-Bugs, Varianz, Lebensgeschichten) | #162 #170 #171 #174–#177 |
| **M1 – Einfach & konsistent** | Redesign §2 (Aktions-Modell, `ActionButton`, `OverlayShell`, Dateien aufteilen), Übung & Beziehung §3.4, Tutorial anpassen | #185 #83 #126 #92 |
| **M2 – Der fesselnde Kern** | Dämonentypen + Kombos, Stadtteil-Erweckung + Bollwerk, Tag + Tagesbilanz §3.3, wabernde unsichtbare Welt (Shader) §3.6, erste Sounds §3.7, Lern-Missionen-Rahmen + "Unterscheidung der Geister" §3.9 | #178 #180 #125 #169 #143 |
| **M3 – Gemeinde & Erkunden** | Rollen, verwundeter Heiler §3.2, Gemeinde-Übersicht, Predigen, Fähigkeiten pro Stufe, weitere Lern-Missionen §3.9, begehbare Innenräume §3.5 | #181 #172 #179 #173 |
| **M4 – Release 1.0** | Grafik (Kenney-Sprites §3.7, Distrikt-Identität), Audio, Legal/Datenschutz, Store-Assets, i18n-Audit, Credits, Vollbild/Insets auf Android | #13 #18 #182 #10 #93 #94 #95 #150 #151 #152 #153 #190 |
| **Nach 1.0** | Cloud-Speicher, reale Städte (OSM), dezente Werbung, Minimap | #165 #166 #128 #164 #146 |

**Warum diese Reihenfolge:** M1 vor M2, weil jedes neue Feature sonst noch eine sechste UI-Variante und noch mehr String-Aktionen erzeugt. M2 vor M3, weil die Gemeinde erst Sinn ergibt, wenn es Etappen gibt, in denen sie hilft. Grafik und Audio kommen bewusst spät: Sie verstärken den Spaß, ersetzen aber keinen fehlenden Kern.

### 4.1 Stand M1 (Branch `feat/m1-redesign`)

| Punkt | Stand |
| :--- | :--- |
| Aktions-Modell §2.1 | ✅ `GameAction`/`ActionId`/`ResourceCost`/`ResourceWallet` (`domain/actions/`). NPC- und Gebäude-Aktionen in je einer Registry; Kostenhinweis generiert; Verfügbarkeit mit Grund (`🔒3`, rote Kosten). |
| Domain-Services | ✅ `NpcInteractionService` (NPC-Regeln aus `NPCComponent` herausgelöst, getestet). Gebäude-Aktionen werden vor dem Service geprüft. |
| `PlayerResources` | ✅ eigene Klasse, Spiel delegiert. |
| Widget-Satz §2.2 | ✅ `ActionButton`/`ActionBar` ersetzen `_EmojiChip`, `_ActionMenuRow`, `_UpgradeRow`, `_BuyButton`, `_AttackTile`. ✅ `OverlayShell` für NPC-Dialog, Gebäude, Missionsbrett, Umgebung. Offen: `RadialAction` (Flame-Komponente, eigener Schritt), Pause/Tastenbelegung bleiben Menü-Bildschirme. |
| Dateistruktur §2.3 | ✅ `game_screen.dart` 5800 → 440 Zeilen (`overlays/`, `hud/`, `widgets/`). ✅ `spirit_world_game.dart` 2500 → 1575 Zeilen (`game/save_state`, `game/overlay_control`, `game/building_actions`). Offen: `GameBalance` (#83) für die restlichen Zahlen. |
| Übung & Beziehung §3.4 | ✅ umgesetzt und gespeichert. |
| Tutorial | ✅ Texte erklären Kostenhinweis, 🔒, ⭐, ♥, 📜 und dass Pastorenhaus/Kirche Glauben auffüllen. |
| Text in Spielbildschirmen | ✅ Gebäude, Missionen, Umgebung, Upgrades ohne Text (Adresse als Titel). |
| Gefundene Fehler | 👂 war bei 2❤️ gesperrt, kostete aber 8❤️. Gebäude-Aktionen veränderten das Gebäude auch, wenn sie danach wegen fehlender Ressourcen abgelehnt wurden. Glaubenskosten in Gebäuden wurden nicht geprüft. |

### 4.2 Stand M2 (Branch `feat/m2-core`, gestapelt auf M1)

| Punkt | Stand | Biblischer Bezug |
| :--- | :--- | :--- |
| Dämonentypen (#178) | ✅ 🐍 Schleicher (schwach gegen ⏳), 🪨 Brocken (🫸), 🦇 Sauger (🪫, zieht Glauben), 👁️ Besetzer. Stufe 1–3 an Größe und Schleimspur sichtbar, skaliert mit Upgrades und Erweckungen; Gnadenfrist 3 Besuche nach einem Upgrade. | Eph 6,12 – der Kampf ist geistlich |
| Kombos | ✅ ⏳ → 🪫 → 🫸: längeres Entziehen, stärkerer Rückstoß, Kettenblitz (50 % der Dämonen-Energie). Reine Regeln in `DaemonCombatRules`, getestet. | |
| Besessenheit (#180) | ✅ Sehr feindliche Menschen können besetzt sein. Frei werden sie nur, wenn beides geschieht: 👂 Seelsorge oder angenommenes 🙏 Gebet in der realen Welt **und** der besiegte 👁️ Besetzer in der unsichtbaren Welt. | Mk 9,29 |
| Bekehrte stützen Zellen | ✅ Weniger Rückfall in der Nähe von Christen, mit abnehmendem Ertrag. | Mt 5,14 – Licht der Welt |
| Lern-Missionen (§3.9) | ✅ Rahmen + 🫂 Seelsorge (🏥), ⚔️ Kampf (⛪), 👁️ Unterscheidung (📚/🏛️). Lektion = Emoji-Satz + Bibelvers (einziger Text, gemeinfreie Übersetzungen) + Aufgabe. Fürbitte/Fasten/Predigen sind angelegt, ihre Wirkung kommt in M3. | 2 Kor 1,4 · Eph 6,12 · 1 Joh 4,1 |
| Viertel + Bollwerk (#125) | ✅ Viertel = 3×3 Chunks. 🏰 öffnet sich ab 25 % Christen (mind. 3), fällt nur durch anhaltendes Befreiungsgebet, regeneriert ohne Gebet, schickt Wachen. Erweckung: +3 📖, helles Gebiet. Die 50 % aus `core_loop_and_retention.md` waren für eine Session zu viel. | 2 Kor 10,4 |
| Tag + Tagesbilanz (§3.3) | ✅ Schlafen im Pastorenhaus → Bilanz (✝️ 🌱 👹 🔥🏘️ 📋 🎓) → ☀️ nächster Tag. Jeder 7. Tag ist Sonntag: Gottesdienst ×1,5. | 1 Mo 2,2–3 – Ruhetag |
| Missionsbrett | ✅ Emoji-Gleichung `👤 wer · 📍 wo  🙏 ×3 ⇒ +10🙏`, im Tutorial erklärt. | |
| Wabern (§3.6) | ✅ Fragment-Shader je Chunk (Domain Warping), Rückfall auf den alten Renderer. | |
| Erste Sounds (§3.7) | ✅ Kenney CC0, 🔊/🔇 im Pausemenü. | |

### 4.3 Stand M3 (Branch `feat/m3-community`, gestapelt auf M2)

| Punkt | Stand | Biblischer Bezug |
| :--- | :--- | :--- |
| Gemeinde (#181) | ✅ Bekehrte werden Mitglieder: 🙏 Fürbeter (+🙏), 📖 Hauskreis (+📖), 🤝 Helfer (+📦), 🩹 verwundeter Heiler. Ertrag am Tagesende, flach (n^0,8). Übersicht ⛪👥 im Pastorenhaus, Rolle per Tippen wechseln. Zentral gespeichert, zählt auch außerhalb geladener Chunks. | Eph 4,11–12 · 1 Kor 12 |
| Verwundeter Heiler (§3.2) | ✅ Wer eine Wunde verarbeitet hat, trägt bei anderen mit derselben Wunde einen Lebensgesprächs-Schritt (kostenlos, einmal am Tag). | 2 Kor 1,4 |
| Fürbitte | ✅ 🙏🏠 in Wohnhäusern: Tür öffnet heute leichter (+30 %), Gespräche mit Bewohnern ×1,5. | 1 Tim 2,1 |
| Fasten | ✅ ➖🍞 im Pastorenhaus: Gebetswellen im nächsten Kampf −40 % 🙏. | Mt 6,16–18 |
| Predigen (#172) | ✅ 📢 in Kirchen, einmal am Tag: alle in 8 Zellen, flach; helle Zellen und Christen verstärken, sehr Feindliche wenden sich ab. Lernbar erst nach der ersten Erweckung. Bewusst als Gebäude-Aktion statt Halten-Mechanik (einfacher). | Röm 10,14 |
| Fähigkeiten pro Stufe (#179) | ✅ Je Modus zwei Fähigkeiten ab Modus-Stufe 3 und 6 (Summe der vier Upgrades), im ⚔️-Panel mit 🔒 und Ansage beim Freischalten. | |
| Missions-Tiers (#173) | ✅ Teil: Belohnung × (1 + 0,5 × erweckte Viertel); die Erweckung selbst ist das Tier-3-Ziel mit qualitativer Belohnung (Predigen). Offen: Quest-Ketten (Tier 2). | |
| Begehbare Innenräume (§3.5) | ✅ Vereinfacht im Raster des Raums: tippen zum Laufen, Möbel lösen Aktionen aus, ✨ Fundstück je Gebäude (einmalig), Bewohner stehen im Raum. Keine eigene Flame-Welt. | |

### 4.4 Stand M4 (Branch `feat/m4-release`, gestapelt auf M3)

| Punkt | Stand |
| :--- | :--- |
| Recht (#93, #150) | ✅ Datenschutz, Nutzungsbedingungen, Impressum in den Einstellungen (de/en); `web/privacy.html` als Store-URL. ⚠️ Impressum hat Platzhalter ⟨…⟩, die der Herausgeber ausfüllen muss. |
| Eltern-Hinweis (#153) | ✅ beim ersten Start, versioniert; „Verlassen“ schließt die App. |
| Credits (#151) | ✅ Kenney CC0, Bibelübersetzungen (gemeinfrei), Bibliotheks-Lizenzen über `showLicensePage`. |
| i18n-Audit (#152) | ✅ Spielbildschirme textfrei bzw. de/en; Sprachwahl wird gespeichert. |
| Grafik (#13/#18/#182) | ✅ Kenney-Figuren mit Laufanimation für Pastor und Menschen; Farbtönung je Distrikttyp. ✅ Stadt aus Kenney-Kacheln: ein Gebäude pro Grundstück mit Dach, Fassade, Tür, Garten (Playtest 2026-10-18). |
| Innenräume (§3.5, #182) | ✅ Dritte Ebene: begehbare Räume, prozedural je Gebäude (stabil aus der Gebäude-ID), Kenney Roguelike Indoors/RPG. Möbel sind Stationen der Gebäude-Aktionen; Bewohner, 🎓 Mentor, ✨. Alle Sondergebäude eigen eingerichtet. Anklopfen bleibt Tür-Dialog. |
| Minimap & Stadtkarte | ✅ Oben rechts: Stadt (Straßen, Häuser, Sondergebäude, 📋-Ziele) bzw. unsichtbare Welt (Zellzustand, Dämonen, 🏰); Tippen vergrößert, Doppeltippen öffnet die Karte der ganzen Stadt (aus dem Generator berechnet, 🎓 Mentoren, erweckte Viertel). |
| Missionen annehmen | ✅ 📍 im Missionsbrett: Ziel auf Minimap/Karte, Pfeil im HUD, gespeichert. ✅ Zweiter Reiter 🎓 Lern-Pfad: alle Fähigkeiten (✅ gelernt, Fortschritt, 🎓 Mentor-Gebäude, 🔒 Voraussetzungen, was sie freischalten); 📍 führt zum nächsten Mentor. Offen: Missions-Ketten, die zu neuen Fähigkeiten führen (Idee, siehe Lern-Missionen §3.9). |
| Audio (#10) | ✅ Effekte (M2). ✅ Umgebungsgeräusche (Stadt, Wohnung, Halle, Kirche, unsichtbare Welt – sphärisch mit fernen Dämonenstimmen) und Klänge für 💬, 🙏, 😴 und die vier Gebetswellen (🕊️ 🫸 ⏳ 🪫), synthetisch erzeugt (`tools/gen_ambience.py`). Offen: Musik / echte Aufnahmen (Pixabay-Audio-Zugang fehlt). |
| Android-Navigationsleiste (#190) | ❌ Offen: Systemleiste überdeckt HUD-Knöpfe (Kampf-Knopf teils nicht drückbar) → Immersive Mode + Insets beachten. |
| Store (#94/#95) | ✅ App-Name, vorläufiges Icon, Store-Texte de/en, Checkliste. ⚠️ App-ID, Signatur, Konten, IARC, Screenshots: Herausgeber, siehe `docs/release/release_checklist.md`. |

---

## 5. Entscheidungen (2026-10-17)

1. Versorgung + Gesundheit zusammenlegen: **Nein**, die fünf Ressourcen bleiben getrennt.
2. Tag als Session-Einheit mit Tagesbilanz: **Ja.** Schlafen beendet den Tag, kein Echtzeit-Druck. Teil von M2.
3. Wunden erzeugen Dämonen: **Nein**, Dämonen bleiben unabhängig von den Lebensgeschichten.
4. Start: **Erst PR #184 nach Test mergen**, dann M1 auf frischem `main`.
5. Dämonen bleiben gefährlich: Ihr Schaden wird nicht abgeschwächt (Rücknahme in `b4df08c`).
6. Lern-Missionen (§3.9): Neue Spielstände lernen Fähigkeiten, bestehende behalten alles.
7. Übung zählt je geistlicher Disziplin (🙏📖💬👂🤝🤲), nicht je einzelner Aktion.
8. Spielbildschirme so textfrei wie möglich; einziger echter Text in Lern-Missionen ist der Bibelvers (2026-10-18).
9. Jede Mechanik soll zur biblischen Lehre und zum Gemeindebau passen, vereinfacht; der Bezug steht im Design (2026-10-18).
10. Stadtteile sind Viertel aus 3×3 Chunks; ein Bollwerk öffnet sich ab 25 % Christen (statt 50 %).
