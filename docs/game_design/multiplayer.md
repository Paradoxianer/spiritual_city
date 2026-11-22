# Multiplayer: gemeinsame Stadt, zwei Welten

Stand 2026-11-22, abgestimmt. Epic #260, Meilenstein „Multiplayer (M5)“. Umsetzung schrittweise. Neue Spiellogik soll schon jetzt dazu passen (deterministisch, Befehle, mehrere Pastoren).

## Ausgangslage

Spiritual City soll später von mehreren Spielern gemeinsam gespielt werden (Stufe 5.3: Echtzeit in einer gemeinsamen Stadt). Wer eine Stadt startet, lädt andere über einen Teilen-Link ein. Jeder entscheidet selbst, wann er in die unsichtbare Welt wechselt.

Heute ist das Spiel auf **einen** Spieler gebaut:
- Beim Weltwechsel **bleiben die Menschen stehen.** `NPCComponent.update` (`components/npc_component.dart:268`) schaltet in der unsichtbaren Welt die KI ab, damit die Dämonen flüssig laufen. Die Menschen gleiten nur noch zum letzten Wegpunkt.
- Die Wellen (`domain/services/spirit_waves.dart`) gehören zu *einem* Besuch *eines* Pastors.
- Die Pause hält die ganze Welt an (`overlay_control.dart`).
- Es gibt 11 ungeseedete `Random()` in der Spiellogik und 20 Stellen mit `game.player`.

**Ziel:** ein klares Konzept, wie die gemeinsame Stadt technisch und spielerisch funktioniert, besonders der Wechsel zwischen den Welten. Dazu eine Reihenfolge, in der wir das Spiel schrittweise dorthin umbauen, ohne den Einzelspieler zu gefährden.

Festgelegt mit dir:
- private Stadt, Einladung per Teilen-Link
- gemeinsame Dämonenwellen
- Kommunikation nur über Emoji-Rufe

## 1. Spielkonzept

### Eine Welt, zwei Ansichten
- Die sichtbare und die unsichtbare Welt sind **dieselbe Stadt in zwei Ansichten**, kein eigener Ort. Jeder Spieler hat **eine** Position. Der Weltwechsel ändert nur, was er sieht und was er tun kann.
- **Jeder wechselt, wann er will**, wie heute für 🙏 Glauben (`toggleWorld`, `spirit_world_game.dart:1056`). Kein Zwang, keine Abstimmung.
- **Wie man die anderen sieht:**
  - Wer in der sichtbaren Welt ist, sieht Mitspieler in der unsichtbaren Welt als **kniende Beter mit goldenem Schein**. Es ist sichtbar, dass dort gerade jemand betet.
  - Wer in der unsichtbaren Welt ist, sieht Mitspieler in der sichtbaren Welt als **helle Lichtpunkte**. Ihr Wirken in der Stadt ist zu sehen.
- **Zusammenspiel der Welten.** Das ist der Kern des Koop:
  - A betet in der unsichtbaren Welt ein Viertel frei. Die Menschen dort werden offener, und B hat es in der sichtbaren Welt leichter mit Gespräch und Bekehrung.
  - B bekehrt Menschen und holt Jünger dazu. Sie kämpfen bei A mit (Versammlung und Jünger gibt es schon).
  - Das passt zu Epheser 6,12 und zum Gemeindegedanken: Beter und Seelsorger brauchen einander.

### Lösung für „die NPCs bleiben stehen“
Die Menschen laufen **in beiden Welten weiter**, nach einem **Tagesplan aus Zeit und Seed**:
- Jeder Mensch hat aus `(worldSeed, npcId, Tagesstunde)` einen festen Ablauf: zu Hause, Arbeit oder Schule, Laden, Kirche, zurück.
- Die Position ist eine **reine Funktion der Weltzeit**. Jeder Client rechnet sie selbst aus, das kostet kein Netz.
- In der unsichtbaren Welt laufen nur Position und Aura mit, das ist billig. Wegfindung und Gesprächs-KI bleiben aus, wie heute.
- Synchronisiert wird nur, **was sich ändert**: Glaube, bekehrt, besessen, Jünger, Mission, unterbrochener Ablauf (z. B. „spricht gerade mit Spieler B“).
- Das ist auch im Einzelspieler sofort besser: Die Stadt lebt weiter, während man betet.

### Gemeinsame Wellen
- Eine Welle gehört zu einem **Kampfort**. Das ist das Viertel, in dem die Beter sind.
- Alle Spieler in der unsichtbaren Welt im selben Viertel kämpfen gegen dieselbe Welle.
- Die Größe wächst mit der Zahl der Beter, etwa um den Faktor `1 + 0,6 × (Beter − 1)`, und mit ihrer Stärke (`daemonPower` aus `DaemonCombatRules`).
- Wer dazukommt, steigt in die laufende Welle ein. Wer geht, behält, was gewonnen ist, wie heute.
- Der **Durchbruch** (grüne Welle) kommt von allen Betern gleichzeitig. Das ist das spektakuläre Bild vom Kampf mit allen Jüngern, nur jetzt mit Freunden.

### Was wem gehört
| Gemeinsam (Stadt) | Persönlich (Spieler) |
|---|---|
| Boden und Zellen, Menschen (Glaube, bekehrt), Gebäude, Viertel (erweckt, freigebetet, christlich), Gemeinde mit Mitgliedern, Weltzeit, Feiern, Sieg | ❤️🍞🙏📦, 📖 Einsicht, Level, Skills, Gebets-Upgrades, Missionen, persönlicher Tag (Schlafen), Position, Ansicht |

- Eine Bekehrung zählt für die Stadt. Erfahrung und Missionsfortschritt bekommt, wer gehandelt hat.
- **Jünger** gehören der Gemeinde. Sie folgen dem Pastor, der sie zuletzt gerufen hat (Versammlung).
- **Feiern und Sieg** erleben alle gleichzeitig. Der Offizier gratuliert „euch“.
- Die 🌉 Brücke führt die ganze Gruppe in die nächste Stadt. Jeder nimmt seinen Pastor mit (`CityCrossing.carry` passt bereits).

### Zeit und Pause
- **Weltzeit** läuft auf dem Server. Der Tagestakt (`GameTime.gameDaySeconds`, `spiritual_dynamics_system.dart:103`) wird zum Server-Tick, und `WorldSimulation.simulateDay` läuft dort. Die Funktion ist schon dafür gebaut („the same day can later run on a server“).
- **Pause** hält im Multiplayer nur die eigene Eingabe an. Die Welt läuft weiter. Ist niemand online, schläft die Stadt (kein Tick). Beim nächsten Start holt sie den Rückstand auf, wie bisher beim Wiederkommen (`world_control.dart` Catch-up).
- **Schlafen** bleibt persönlich (`endDay`). Der Gemeinde-Ertrag geht an den Schlafenden, die Weltzeit springt nicht.

### Einladen und Emoji-Rufe
- „Stadt teilen“ erzeugt einen Link `https://spiritual-city.org/s/<code>`.
  - Ist die App installiert, öffnet der Link sie (Android App Links mit Paket `de.heilsarmee.spiritual_city`).
  - Sonst öffnet er die Web-Version, die direkt beitritt.
  - Der Code ist 8 Zeichen lang und zufällig. Der Gründer kann ihn erneuern und so alte Links ungültig machen.
- **Emoji-Rufe** gehen über ein Rad, wie das Aktionsmenü:
  - 🙏 „Bete mit mir“ (setzt eine Markierung auf der Minimap)
  - 🆘 „Hilfe“
  - 📍 „Komm her“
  - 👍 „Danke“
  - 🎉 „Super“

  Es gibt keinen freien Text. Das passt zum Emoji-Spiel und ist sicher für Kinder.

## 2. Technische Architektur

### Grundsatz: dieselben Regeln auf Client und Server
Die Spiellogik ist Dart, also kann sie **auf dem Server in Dart** laufen. Die Regeln wandern als reine Dart-Bibliothek ohne Flutter und Flame in ein eigenes Paket, das Client und Server teilen. Darin liegt heute schon das meiste:
- `domain/services/world_simulation.dart`, `spirit_waves.dart`, `daemon_combat_rules.dart`, `combat_abilities.dart`
- `domain/models/quarter.dart`, `domain/city_generation/*`, `city_crossing.dart`

### Wer entscheidet was
| Bereich | Autorität | Warum |
|---|---|---|
| Stadt (Zellen, Menschen, Gebäude, Viertel, Gemeinde, Zeit) | **Server** | gemeinsam und dauerhaft, keine Widersprüche |
| Wellen und Dämonen eines Kampforts | **Server**, 10 Ticks/s | gemeinsame Wellen, alle sehen dasselbe |
| eigene Bewegung | **Client** mit Vorhersage, Server prüft (Geschwindigkeit, begehbar) | fühlt sich sofort an |
| Menschen-Positionen | **niemand**, aus dem Tagesplan berechnet | spart fast den ganzen Netzverkehr |
| Persönliches (Ressourcen, Skills) | **Server** speichert, Client zeigt an | Cloud-Speicher (5.1) |

### Befehle statt direkter Änderungen
Jede Änderung an der Welt ist ein **Befehl** `{spieler, aktion, ziel, parameter}`:
- `talk(npcId)`, `pray(npcId)`, `convert(npcId)`
- `prayerWave(mode, pos)`, `hitDaemon(id, mode)`
- `enterSpirit()`, `leaveSpirit()`, `gather()`, `buildingAction(buildingId, action)`

Ablauf:
1. Der Client schickt den Befehl.
2. Der Server prüft ihn mit denselben Regeln, wendet ihn an und verteilt das Ergebnis als **Ereignis**.
3. Im Einzelspieler läuft derselbe Weg lokal, ohne Netz. Das ist der wichtigste Umbau, denn er macht beide Modi gleich.

### Netz
- **WebSocket** (funktioniert in der Web-Version und in der App), Nachrichten zuerst als JSON, später kompakter.
- **Interessenbereich:** Jeder Client abonniert die Chunks um sich und das Viertel, in dem er ist. Er bekommt nur Änderungen von dort, dazu einmal pro Sekunde Spielerpositionen der ganzen Stadt für Minimap und Stadtplan.
- Dämonen: Position und Energie mit 10 Hz, der Client interpoliert dazwischen.
- Zellen: nur geänderte Zellen pro Chunk, gebündelt alle 250 ms.

### Server
- `dart_frog` oder `shelf` mit WebSocket. **Ein Prozess pro Stadt** im Speicher, solange jemand online ist.
- **Speichern:** Schnappschuss der Stadt alle 60 s und beim letzten Verlassen in SQLite, dazu ein Befehlsprotokoll für Fehlersuche.
- **Hosting:** der **hosting.de Cloud Server** (ab 4,90 €/Monat), weil Shared Hosting keine dauerhaften Prozesse erlaubt. Davor Caddy für TLS. Die Web-Version bleibt auf dem Webspace.
- **Anmeldung:** anonym per Geräteschlüssel, optional Google-Login für mehrere Geräte. Das ist Stufe 5.1 und zugleich der Cloud-Speicher.

### Determinismus und Prüfbarkeit
- Jeder Zufall in den Regeln wird `Random(hash(worldSeed, tag, id, tick))`. Betroffen sind die 11 Stellen mit `Random()` in `lib/src/features/game`. Für Klänge wie `Footsteps` bleibt ungeseedet erlaubt, weil sie keine Regel sind.
- Ein **Zustands-Hash** pro Chunk ermöglicht den Vergleich von Client und Server. Weichen sie ab, holt der Client den Chunk neu.

## 3. Umsetzung in Stufen

Jede Stufe ist einzeln spielbar und verbessert auch den Einzelspieler.

**Stufe A – Vorbereitung im Einzelspieler (kein Server)**
1. **Tagesplan der Menschen:** neuer Dienst `domain/services/npc_schedule.dart`, Position = f(seed, id, Weltzeit). `NPCComponent` folgt ihm in beiden Welten. Damit ist das Stehenbleiben gelöst. (#248)
2. **Befehle:** Aktionen aus `building_actions.dart`, Dialog (`overlays/npc_dialog.dart`), Gebetswellen (`spirit_waves_control.dart`) und Dämonentreffer laufen über `GameCommand` → `WorldRules.apply` → Ereignis. Die verstreuten direkten Schreibzugriffe auf `cell.spiritualState` werden ersetzt. (#249)
3. **Spieler als Parameter:** `game.player` an den 20 Stellen ersetzen. Wirkungen bekommen den handelnden Pastor übergeben (Versammlung, Jünger folgen *ihrem* Pastor). (#250)
4. **Zustand trennen:** `PlayerProgress` in einen persönlichen Teil und `CityState` (Viertel, Gemeinde, Weltzeit) aufteilen. Bestehende Spielstände werden beim Laden umgebaut, siehe `kSaveDataVersion` und die Migrationen in `game/save_state.dart`. (#251)
5. **Zufall seeden** (siehe oben). (#252)
6. **Wellen pro Kampfort** statt pro Besuch, mit „Beter im Viertel“ als Eingabe (im Einzelspieler immer 1). (#253)

**Stufe B – Cloud-Speicher (5.1)** (#254, #255)
- Dart-Server mit Anmeldung, Spielstand hoch- und runterladen, Gerätewechsel.
- Gemeinsames Regelpaket `packages/city_rules/` (reines Dart), das Client und Server nutzen.

**Stufe C – Gemeinsame Stadt in Echtzeit (5.3)** (#256–#259)
- Stadt-Prozess auf dem Server, WebSocket, Interessenbereich, Befehle und Ereignisse.
- Einladungslink und App Links (`AndroidManifest.xml` und `/.well-known/assetlinks.json` auf spiritual-city.org).
- Mitspieler darstellen (Beter mit Schein, Lichtpunkte), Emoji-Rufrad, gemeinsame Feiern, Sieg und Brücke für die Gruppe.

Stufe 5.2 (asynchrone Stadt) lassen wir aus. Mit dem Server aus Stufe C ist der Unterschied klein.

## 4. Risiken

- **Aufwand:** Stufe A ist ein großer Umbau, etwa 2 bis 4 Wochen in Teilen. Jede Teilstufe muss alle Tests grün halten.
- **Alte Spielstände:** Das Aufteilen von `PlayerProgress` braucht eine saubere Migration.
- **Kosten:** Der Cloud Server ist erst ab Stufe B nötig.
- **Datenschutz:** Ein Online-Konto ändert die Datenschutzerklärung (`web/privacy.html`, `legal_texts.dart`), den Elternhinweis und die Play-Fragebögen zur Datensicherheit.
- **Jugendschutz:** Private Städte und Emoji-Rufe halten ihn einfach.

## Verifikation

- Tagesplan (#248): zweimal gerechnet gleiche Position; Menschen bewegen sich in der unsichtbaren Welt.
- Befehle (#249): `test/simulation/playthrough.dart` läuft über Befehle mit denselben Ergebnissen.
- Determinismus (#252): zwei Simulationen mit denselben Befehlen → gleicher Zustands-Hash.
- Echtzeit (#256–#258): Bot-Clients spielen gemeinsam; zwei echte Geräte in einer Stadt, eins in jeder Welt.
