# 📋 GitHub Issues Roadmap
_Last updated: 26.04.2026 20:45_
_Sorted by Release and Priority (High > Medium > Low)_

## 🔥 ✨ #92: feat: Interaktives Tutorial-System für neue Spieler [enhancement, prio: 1] 🏁 [Release 1]
---
**Status / Description:**

Neue Spieler (insbesondere Kinder) benötigen eine klare Einführung in die Kernmechaniken: Bewegung, Interaktion mit NPCs/Häusern, Wechsel zwischen sichtbarer und unsichtbarer Welt, geistlicher Kampf/Gebet sowie das Management von Health/Hunger/Faith. Das Tutorial sollte als geführte Start-Mission oder über gut platzierte Popups/Tooltips integriert werden.

---

## ⚡ ✨ #85: feat: Signifikante Auswirkungen der geistlichen Welt auf die reale Welt [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Es muss sich lohnen, in der geistlichen Welt zu kämpfen. Positive Bereiche in der geistlichen Welt müssen signifikante Auswirkungen auf die reale Welt haben.

---

## ⚡ ✨ #114: feat: Game Over / Ohnmacht Mechanik (0 Leben) [enhancement, prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Wenn das Leben des Spielers auf 0 sinkt, soll der Bildschirm dunkel abblenden (Ohnmacht). Der Spieler wacht danach im Pastorenhaus (oder einem Krankenhaus) wieder auf. Konsequenz: Er hat wieder 100% Leben und 100% Hunger, aber **alle gesammelten Ressourcen (Faith, Material etc.) werden auf 0 gesetzt**. Spielfortschritt wie Bekehrungen oder befreite Bereiche in der unsichtbaren Welt bleiben erhalten.

---

## ⚡ ✨ #101: feat: Game Over / Ohnmacht Mechanik (0 Leben) inkl. Rückschlag in der geistlichen Welt [enhancement, prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Wenn das Leben des Spielers auf 0 sinkt, blendet der Bildschirm dunkel ab (Ohnmacht). Der Spieler wacht in einem weiter entfernten Krankenhaus  auf. Konsequenz: Er hat 100% Leben und Hunger, **aber alle gesammelten Ressourcen (Faith, Material) werden auf 0 gesetzt**. Zusätzlich erobert die Dunkelheit Raum zurück: (am besten dort wo er unmöchtig geworden ist) **Einige zuvor grün/befreite Bereiche der unsichtbaren Welt färben sich wieder rot (dämonisch).** Dies muss dem Spieler über eine UI-Nachricht (z.B. 'Während du ohnmächtig warst, ist die Finsternis zurückgekehrt...') mitgeteilt werden.

---

## ⚡ ✨ #82: feat: Interactive Mission Completion with Gameplay Actions [enhancement, prio: 2] 🏁 [Release 1]
---
**Status / Description:**

feat: Interactive Mission Completion with Gameplay Actions

Problem

Current Behavior:
Wenn man eine Mission (📋) im Radial Menu drückt:
- Mission wird sofort abgeschlossen
- Player erhält +10 Faith + 5 Materials
- Keine visuelle Rückmeldung – nichts wahrnehmbar passiert
- Null Gameplay – einfach nur "click to win"

Gewünscht:
Missions sollten echte Aufgaben sein:
Designfrage : sollten nicht die Missionen teil des NPCs oder Hausdialog / Loook dialog sein... es wird ja an interactible objekt dran gehangen?????
sollte es dann nicht erst zugänglich sein, wenn man die Person anspricht oder in das haus rein kommt.. und dort entsprechende "Aufgaben erledigt"
evtl...
1. Dialog öffnet sich mit Mission-Details 
2. Mann benötig bestimmte Ressourcen (hoffentlich hat man genug Faith)
3. Bestimmte Action durchführen (z.B. "Bete 3x", "Liefere 10 Materials ab", "Lerne Prophezeiung ---> man bekommt mehr Geistliche Erfahrungspunkte... ")
4. Belohnung erst nach Completion der Action


Beispiel-Missionen mit Actions zum diskutieren??? - Könnte man Missionen auch "sinnvoll" Prozedural erzeugen?

Mission | Aktion | Bedingung | Reward
🙏 Bete für die Gegend | pray im Spiritual World | 5x gebetet |  --> Grüne Riesen Explosin in dem bereich in der unsichtbaren Welt??? (+ x geistliche Erkenntniss)
📦 Bring Hilfsmittel | deliverMaterials im Building | 10 Materials abliefern | +10 Faith, +5 Materials die das Max Materials steigt um x punkte (z.b. von 100 auf 103) (+ x geistliche Erkenntniss)
💬 Sprich mit jemand | talk im Dialog | 3 Konversationen | +10 Faith, +2 Materials NPC bekommt + 100 Faith beim NPC (+ x geistliche Erkenntniss)
🏠 Segne ein Haus | pray im Building | 1x gebetet | man bekommt Segens modfifer der dan in der unsichtbaren welt hilft.. oder das haus wird automatisch 100 % faith? (+ x geistliche Erkenntniss)
📖 Teile Gute Nachricht | shareGospel im NPC Dialog | Gospel gepredigt | +25 persönl. Faith + NPC bekehrt sich instant (+100 faith)... (+ x geistliche Erkenntniss)
💡 Bring Licht ins Haus | prayBusiness im Building |1x gebetet |  +100 Materials (unsichtbare welt wird kleinen Umfang grün) (+ x geistliche Erkenntniss)


Nimm das  Solution Design als inspiration hinterfrage kritisch nach modularität und skalierbarkeit und elegance in der implementierung

Phase 1: Mission-Typen mit Tracking
(suche noch weiter biblische Typen)
enum MissionType {
  pray,
  deliverMaterials,
  talk,
  shareGospel,
  prayInBuilding,
  help,
}

class MissionModel {
  final String id;
  final MissionType type;
  final String description;
  
  final int targetCount;
  int progressCount = 0;
  
  bool get isCompleted => progressCount >= targetCount;
  
  void advance([int amount = 1]) {
    progressCount = (progressCount + amount).clamp(0, targetCount);
  }
}

Phase 2: Mission an NPC/Building tracken

class NPCModel {
  MissionModel? activeMission;
}

class BuildingModel {
  MissionModel? activeMission;
}

Phase 3: Missions-Hooks in Game-Actions

Beim Beten im Spiritual World:
spiritualDynamics.onPrayerCast(() {
  missionService.advanceMissionsOfType(MissionType.pray);
});

Beim Material abliefern in Building:
buildingInteractionService.onMaterialDeliver((amount) {
  missionService.advanceMissionsOfType(MissionType.deliverMaterials, amount);
});

Beim Dialog sprechen:
dialogService.onConversationEnd(() {
  missionService.advanceMissionsOfType(MissionType.talk);
});

Phase 4: Mission Dialog & Progress UI

Mission Dialog zeigt:
- 📋 Mission-Emoji + Beschreibung
- Progress Bar: [████░░░░] 3/5 Gebete
- Action Button: "Jetzt beten" / "Aktuell nicht möglich"
- Reward Preview: +10 Faith, +5 Materials

Wenn Complete:
- ✅ "Mission Erfolgreich!"
- Confetti/Particles Animation
- Auto-schließen nach 2 Sek

Phase 5: Mission Board Update

Im Mission Board (📋 Missionen):

🙏 Maria – Bete für die Gegend
  [████░░░░] 3/5 Gebete
  📍 Kaiserstraße 14
  ⏫ +10 Faith, +5 Materials
  
📦 Supermarkt – Bring Hilfsmittel
  [██░░░░░░] 2/10 Materials
  📍 Marktplatz 1
  ⏫ +10 Faith, +5 Materials

Tasks

Phase 1: Mission-Modell erweitern
- [ ] Neue Datei: lib/src/features/game/domain/models/mission_model.dart???
  - enum MissionType
  - class MissionModel mit Type + Progress
- [ ] Erweitere NPCModel.activeMission: MissionModel?
- [ ] Erweitere BuildingModel.activeMission: MissionModel?
- [ ] Update MissionService:
  - Generiere MissionModel statt String Text
  - Track verschiedene Mission-Typen

Phase 2: Mission-Hooks integrieren
- [ ] SpiritualDynamicsSystem: Hook für Prayer-Events
- [ ] BuildingInteractionService: Hook für Material-Deliver + Actions
- [ ] DialogService: Hook für Konversations-Ende
- [ ] MissionService.advanceMissionsOfType() implementieren

Phase 3: Mission Dialog (Overlay)
- [ ] Neue Datei: lib/src/features/game/presentation/components/mission_dialog.dart
- [ ] Zeige Progress Bar + Action Buttons
- [ ] Auf Completion: Celebration Animation
- [ ] Auto-close nach Mission-Complete

Phase 4: Mission Board Redesign
- [ ] Update MissionBoardOverlay:
  - Zeige Progress Bars statt nur Text
  - Zeige erforderliche Action
  - "Go To" Button → Navige zu NPC/Building
- [ ] Update MissionEntry mit Progress-Daten

Phase 5: Reward Feedback
- [ ] Auf Mission-Complete:
  - Floating Text: +10 Faith, +5 Materials
  - Particle Effect
  - Sound FX (optional)
- [ ] Speichere kompletierte Missionen in Progress-Tracker

Akzeptanz-Kriterien

- [ ] Mission-Typen sind klar definiert (mind. 6 verschiedene)
- [ ] Missions zeigen Progress Bars, nicht nur Text
- [ ] Spieler muss echte Game-Actions durchführen (nicht einfach klicken)
- [ ] Mission Dialog öffnet sich, wenn Mission angeklickt
- [ ] Progress ist visuell sichtbar unter NPC/Building Namen
- [ ] Rewards sind zeitlich verzögert (erst nach echter Completion)
- [ ] Mission Board ist hilfreich + navigierbar
- [ ] Alte Saves kompatibel (Fallback auf alte String-Format)

Optional: Future Improvements

- [ ] Mission-Kette: Quest A → Quest B → Quest C (mit Story)
- [ ] Schwierigkeit: Easy/Hard Missions mit unterschiedlichem Reward
- [ ] Timed Missions: "Bete 5x in 5 Minuten"
- [ ] Wiederholbare Missionen vs. One-Time Quests
- [ ] Missionslog (History)

Notes

Warum ist das wichtig?
- Gibt Gameplay Sinn + Richtung
- Spieler sieht was passiert wenn er eine Action tut
- Motivierend: "Noch 2 Gebete bis fertig!"
- Führt Spieler zu verschiedenen Game-Systemen (Spiritual World, Buildings, Dialoge)

Komplikation: aus Chunks Ungeladen
- Wenn NPC-Chunk ungeladen wird → Mission-Progress sollte erhalten bleiben
- Speichern: activeMission.progressCount mit NPC-Daten

---

## ⚡ ✨ #4: feat: Waffenrüstung & Upgrade-Zentrale (Pastorenhaus) [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

## System-Design
- **Ort:** Neues Menü-Tab 'Upgrade' im Pastorenhaus-Dialog.
- **Logik:** Verwendung von 'Geistliche Erkenntnis' für alle permanenten Verbesserungen.
- **Upgrade-Kategorien:**
  1. **Verteidigung (Waffenrüstung):** Schild (Schadensreduktion), Helm (Hunger-Resistenz).
  2. **Angriff (Kampf-Modifier):** Stufenweise Steigerung von Radius, Stärke, Dauer und Geschwindigkeit für jeden der 4 Gebetsmodi.
- **Progression:** Exponentielles Kostenwachstum für Langzeitmotivation, günstige Einstiegs-Level.
- **Datenmodell:** Implementierung einer \CombatProfile\ Klasse im \PlayerProgress\, die alle Modifikatoren speichert.
Modifikatoren sollten prinzipell nur mit der neuen Geistliche Erkentniss ressource arbieten (also keine extra "funktionalität" wie "Inbrunst" usw.. keep it simpel und nachvollziehbar!!

---

## ☕ ✨ #83: refactor: Codebase Modularisierung & Code Quality Optimization [enhancement, prio: 3] 🏁 [Release 1]
---
**Status / Description:**

Problem

Aktuelle Situation:
- Styling: Farben, Border, Padding wiederholen sich überall (Color.withValues, BorderRadius, etc.)
- Constants: Magic Numbers überall verteilt (Spawn-Position, LOD-Distanzen, Reward-Values)
- Models: Gemeinsame Patterns (Serialization, Influence Clamping) nicht zentral
- Services: Fire-and-Forget, keine Error Handling oder Callbacks
- Performance: Keine Lazy Loading, NPC Position Updates für alle LOD-Level

Ziele:
- Zentralisiere Theme, Constants und wiederverwendbare Logic
- Verbesser Maintainability & Reusability
- Reduziere Code Duplication
- Optimiere Performance wo möglich
- Einheitliches Look & Feel garantieren

Top Refactoring Opportunities

1. Design System & Constants (HIGH IMPACT, LOW EFFORT)

Neue Dateien:
- lib/src/core/theme/app_theme.dart (Farben, TextStyles, Decorations)
- lib/src/core/constants/game_constants.dart (Spawn-Pos, LOD-Distanzen, Rewards)
- lib/src/core/constants/ui_constants.dart (Padding, Border, Size Values)

Beispiel - Aktuell überall:
Container(
  color: Colors.black54,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
)

Mit Constants:
Container(
  decoration: AppTheme.dialogDecoration,
)

Beispiel - Spawn Position:
Aktuell in spirit_world_game.dart Zeile 174:
player.position = Vector2(7040, 7168);

Mit Constants:
player.position = GameConstants.playerSpawnPos;

Impact: -150+ Zeilen Duplikation, +Consistency, +Easy Theme Changes

2. Models: Shared Logic Extrahieren (MEDIUM IMPACT, LOW EFFORT)

Neue Datei: lib/src/features/game/domain/models/base_entity.dart

Patterns die wiederkehren:
- Serialization (toJson/fromJson in NPCModel, BuildingModel, Cell)
- Influence Clamping (Faith -100..100 in NPCModel, Cell Spiritual State)
- lastModified Tracking

Lösung:
abstract class GameEntity {
  String get id;
  DateTime lastModified = DateTime.now();
  
  Map<String, dynamic> toJson();
  void fromJson(Map<String, dynamic> json);
}

mixin Influenceable {
  double influence = 0.0;
  void applyInfluence(double amount) {
    influence = (influence + amount).clamp(-100.0, 100.0);
  }
}

Dann:
class NPCModel extends GameEntity with Influenceable {
  final String id;
  final String name;
  // ... rest
}

Impact: -100 Zeilen Duplikation, +Type Safety, +Consistency

3. Service Layer Patterns (MEDIUM IMPACT, LOW EFFORT)

Problem:
Alle Services sind void, kein Feedback oder Error Handling

Lösung:
abstract class BaseService {
  final _eventStream = StreamController<ServiceEvent>.broadcast();
  Stream<ServiceEvent> get eventStream => _eventStream.stream;
  
  void emit(ServiceEvent event) => _eventStream.add(event);
  void dispose() => _eventStream.close();
}

class ServiceEvent {
  final String type;
  final dynamic data;
  ServiceEvent(this.type, [this.data]);
}

Dann in MissionService:
void completeMission(NPCModel npc) {
  npc.activeMissionDescription = null;
  emit(ServiceEvent('mission_completed', {'npc': npc}));
}

Game Layer:
missionService.eventStream.listen((event) {
  if (event.type == 'mission_completed') {
    showRewardParticles(event.data['npc']);
  }
});

Impact: +Observability, +Error Handling, +Testing, -Silent Failures

4. UI Constants & Reusable Components (MEDIUM IMPACT, LOW EFFORT)

Neue Datei: lib/src/core/ui/reusable_widgets.dart

Beispiele:
- ProgressBar (für Missions, Health, Hunger)
- ResourceDisplay (Faith, Materials, Health Anzeige)
- EmojiButton (überall wo Buttons mit Emoji sind)
- DialogContainer (Standard Dialog Wrapper)
- RewardText (floating text mit +X Faith)

widget RewardText extends StatelessWidget {
  final String text;
  final Color color;
  const RewardText(this.text, {this.color = Colors.green});
  
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.rewardText.copyWith(color: color),
    );
  }
}

Impact: -100+ Zeilen Duplikation, +Consistency, +Easy Customization

5. Performance: Selective Updates


---

## ☕ ✨ #61: feat: Ressourcen-Stage-System mit visueller Progression (Faith, Materials, Health, Hunger) [prio: 3, feature] 🏁 [Release 1]
---
**Status / Description:**

## Ziel
Ein einfach verständliches, ressourcenbasiertes Stage-System für fortlaufenden Progress ohne Meta-Überfrachtung. Fokus auf Faith, Materials, Health, Hunger (später erweiterbar):

### System-Design
- Jede Ressource (Faith, Materials, Health, Hunger...) sammelt **eigenen Counter**
- Jeder Verbrauch/Erwerb (z.B. Faith ausgeben/sammeln) erhöht Counter für diese Ressource
- Erreichen von definierten Counter-Schwellen (z.B. Faith 500/777/1500) erhöht das jeweilige Ressourcenkonto (maxFaith, maxMaterials etc.)
- Fortschrittsbalken/Countern werden **sichtbar im HUD** abgebildet (leuchtender Pixelstreifen + Stufenanzeige)
- Stage-Fortschritt ist klar getrennt pro Ressource und kann gezielt trainiert / gefördert werden.
- Stage-Counter und Schwellen sind jederzeit im UI ersichtlich.

###Important
- Stufenaufstieg  (vor allem Faith) muss so gestaltet werden, dass er imt dem Kampsystem in der unsichtbaren Welt gut zusammen arbeitet (nicht zu stark und nicht zu wenig steigt... beachte balancing!!!!) - was wären sinnvolle Schritte (sollte es logarithmisch aufsteigen???)

### Acceptance Criteria
- Stages und ihre Wirkung sind jederzeit für den Spieler einsehbar.
- Jede Ressource bietet motivierende Fortschrittserhöhung durch Nutzung.
- Kein RPG-Statistik-Overhead, klarer Fokus auf Purpose.

---

## #94: release: App Store Assets (Icons, Screenshots, Beschreibung) [documentation] 🏁 [Release 1]
---
**Status / Description:**

Vor dem Release müssen vorbereitet werden: 1. Finales App Icon in allen geforderten Auflösungen (iOS & Android). 2. Aussagekräftige und ansprechende Screenshots für verschiedene Gerätegrößen (inkl. Tablets). 3. Eine packende Store-Beschreibung (kurz & lang) mit Fokus auf die Kern-Features. 4. Optional: Ein kurzes Gameplay-Promo-Video.

---

## #95: release: Store Konfiguration & Altersfreigabe (IARC) [documentation] 🏁 [Release 1]
---
**Status / Description:**

Die App muss in der Google Play Console und in App Store Connect angelegt werden. Dazu gehört das Ausfüllen des IARC-Fragebogens für die korrekte Altersfreigabe (USK/PEGI) sowie die Deklaration der Inhalte (z.B. Datensicherheit, Zielgruppe, keine Werbung / In-App-Käufe für den Anfang).

---

## ✨ #59: refactor: Unified Shockwave & Aura Framework [feature] 🏁 [Release 1]
---
**Status / Description:**

## Architektur
- **Aura-Manager:** Zentrales System zur Steuerung der 4 Modi.
- **Schockwellen-Renderer:** Implementierung eines performanten Ripple-Effekts (klein -> groß expandierend).
- **Power-Scaling:** Logik zur Berechnung der Haltedauer-Multiplikatoren.
- **Color-Strategy:** Einfaches Umschalten der Aura-Farbe und Effekt-Logik basierend auf dem gewählten Modus.

---

## #126: ui: Needs cleanup 🏁 [Release 1]
---
**Status / Description:**

At  the moment we have so many "buttons" ui elements in de hud.. we need to clean it up.. (also you can exiendtly tap on "exit" or help
we should have a "Menü button" on the right top wich opens a Menu .. 
Save
Load
Help
[do we need more Options]
Quit

---

## #93: legal: Datenschutzerklärung (DSGVO) & Impressum [documentation] 🏁 [Release 1]
---
**Status / Description:**

Für den Release im Google Play Store und Apple App Store sind zwingend erforderlich: 1. Eine rechtssichere Datenschutzerklärung (besonders wichtig, falls Analytics, Crash-Reports oder Cloud-Saves genutzt werden). 2. Ein Impressum (Pflicht im DACH-Raum). Beides muss auf einer Webseite gehostet, im Store verlinkt und in der App aufrufbar sein.

---

## ✨ #96: feat: Gottesdienst/Gebet in Kirchen mit Flächenwirkung (AoE) [enhancement, feature] 🏁 [Release 1]
---
**Status / Description:**

In Kirchen sollte man Gottesdienst halten oder beten können. Das sollte in der unsichtbaren Welt einen deutlich größeren Einflussradius haben als normale Aktionen. Zudem sollen NPCs in diesem Radius einen Boost auf ihren 'Faith'-Wert bekommen.

---

## #121: bug: loot loading 🏁 [Release 1]
---
**Status / Description:**

Nach dem Laden erscheint immer ein loot direkt neben der geladen position

---

## ✨ #118: feat: Spezialgebäude und Sonderhäuser – Balancing, Multiplikatoren und AoE-Effekte [feature] 🏁 [Release 1]
---
**Status / Description:**

## Ziel
Jedem Special House / Gebäudetyp klare AoE-Multiplikatoren und Action-Anknüpfungen zuweisen. Ziel: jedes Haus/Schauplatz erzeugt spezifische Balance-/Effekte.

### System-Design
- Jeder Gebäudetyp hat einen Grund-AoE-Multiplikator (Kirche/Kathedrale > Krankenhaus > Schule > Wohnhaus > Supermarkt etc.)
- Actions wie "Gemeinschaft" oder "Gebet" in Spezialgebäuden haben stark erhöhte Kosten (Faith, Zeit), aber auch massive Effekte in der unsichtbaren Welt.
- **Sichtbare Auswirkungen** (z.B. Nachleuchten der Zellen, Flächenreinigung, Ausbreitung grüner Bereiche, NPC-Boost, Segenstimer etc.) sind verpflichtend umsetzbar.
- Mechanische Differenzierung pro Spezialgebäude (z.B. Kirche: AoE-Segen, Krankenhaus: Langzeitheilung, Schule: Education-Buff, Friedhof: starker Widerstand, Supermarkt: Versorgungssegen...).
- Integrationspunkt für Issue #59 (Effektsystem) und #4 (Action-Modell).
- Balancing der Kosten und Stärken muss auf Multiplikatoren basieren, nicht nur fest auf Zahlen.

### Acceptance Criteria
- Für jeden Special-Haus-Typ existiert ein Multiplikator und Beispiel-Action mit dokumentierten Effekten.
- Balancing folgt klarer, agentenlesbarer Formel (siehe Effektsystem #59).
- Effektauslösung und Sichtbarkeit (UI, Nachleuchten, etc.) sind Pflicht.
- Erweiterbar für neue Haus-/Gebäudetypen.

---

## #124: feat: Ressourcen-Erweiterung - Geistliche Erkenntnis (Insight) 🏁 [Release 1]
---
**Status / Description:**

## Anforderungen
- **Währungstyp:** Integer (\int\) für klare Erfolgserlebnisse.
- **Quellen:**
  - **Bekehrungen:** 10 bekehrte Personen = 1 Punkt Erkenntnis.
  - **Missionen:** Belohnung je nach Schwierigkeit (z.B. 1-3 Punkte).
  - **Loot:** Seltene Funde in der Welt (1 Punkt).
- **Integration:** 
  - Schnittstelle zum \ConversionService\ (triggert bei Erreichen von Vielfachen von 10).
  - UI-Anzeige im HUD und in der Upgrade-Zentrale.

---

## ✨ #123: META: Refactoring & Architektur-Koordination (Gebetskampf, Effektsystem, Modifier, Resourcen, Buildings) [feature] 🏁 [Release 1]
---
**Status / Description:**

# Meta-Issue: Refactoring Gebetskampf & Systemintegration – Modular, Simpel, Wartbar

## Ziel
Die verschiedenen Teilaspekte von Gebetskampf, Unsichtbare-Welt-Effekten, Ressourcensystem und Spezialgebäude sollen in einem modularen, eleganten und wartbaren Ansatz zusammengeführt werden. **Dieses Issue ist ein reines Koordinations- und Architektur-Issue; Implementierung erfolgt ausschließlich über die referenzierten Teil-Issues.**

## Systemübersicht
- **Kern-Loop:** Stationärer Gebetskampf in der unsichtbaren Welt, 10–20 Sekunden, Eintrittskosten, Faith-Drain, klare Gebetsformen (Kreis/AoE /Angriff), Gegnertiming.
- **AoE-/Stärke-/Wirkungsmodifikatoren:** Fortschritt und Tiefe durch sammelbare Modifier aus Missionen/Loot.
- **Realwelt-Effekte:** Framework koppelt reale Aktionen mit persistenten, parametrisierten Effekten in der unsichtbaren Welt.
- **Spezialgebäude:** Unterschiedliche AoEs, Modifier-Anbindung.
- **Ressourcen-Stages:** Klar sichtbare Progression nach Sammeln/Verbrauchen.

## Prinzipien
- **Modularität, Eleganz, Wartbarkeit, Keep it simple but elegant** (siehe ursprüngliche Meta-Issue).
- **Dieses Issue NICHT für Implementierung verwenden!** PRs/Merges/Tickets werden ausschließlich in den Teil-Issues (#4, #9, #59, #61, #118) abgestimmt.

### Referenzen
- #4 Interaktion+Modifier/Reward-System
- #9 Prayer Combat UX
- #59 Effekt-Framework
- #61 Ressourcen-Stage-System
- #118 Spezialgebäude

---

### MVP = #9 -> #59 -> #118 -> #61, Coordination/Reward/Modifier-Fragen über #4 klären.

---

## #115: feat: Hunger Mechanik 🏁 [Release 1]
---
**Status / Description:**

Wenn man Hunger hat... wäre ein sinnvolles Feature.. dass man sich viel langsamer bewegt und Aktionen allgmein mehr kosten (anstrengerder) :-)

---

## #108: doc: ergänze Kommentare im Code wo nötig [documentation] 🏁 [Release 1]
---
**Status / Description:**

Schau wo der Code noch auskommentiert werden muss um besser zu verstehen was passiert und die Wartbarkeit zu erhöhen..
folge Kommentierungsregeln so dass wir wenn notwendig daraus mit einem Tool eine entsprechende dokumentation erstelle können

---

## ✨ #100: feat: Bekehrungs-Zähler (Christen-Anzeige) im HUD [enhancement, feature] 🏁 [Release 1]
---
**Status / Description:**

Das HUD soll immer sichtbar anzeigen, wie viele Menschen in der Stadt bereits Christen (bekehrt) geworden sind. Das gibt dem Spieler (und vor allem Kindern) ein tolles Erfolgserlebnis und ein klares Ziel vor Augen.

---

## 🔴 #111: bug: Problems with Menuselection of pwa [bug] 🏁 [Release 1]
---
**Status / Description:**

on ios devices with the default browser... the difficulty menu dosent work... the main menu works.. but diffuctly jsut dont reakt.

---

## #109: doc: erstelle eine Dokumentation für User [documentation] 🏁 [Release 1]
---
**Status / Description:**

Diese sollte umfassende einfühurung in das Spiel.. sowie Tipps und Tricks, best practices.. beinhalten... Es sollte spannend beschrieben sien..
und die Spielmechanik auch mit bibelversen hinterlegt / bedgründet werden

Sollten wir diese dokumente auf verschieden Sprachen erhältlich machen?? und wenn ja wie?

---

## ⚡ ✨ #13: feat: Asset Management & Sprite Loading [prio: 2, feature] 🏁 [Release 2]
---
**Status / Description:**

# feat: Asset Management & Sprite Loading

## Anforderungen:
- Sprite-Loading für alle Entities
- Asset-Caching
- Lazy-Loading für große Maps
- Sprite-Atlas

## Sprites zu erstellen:
- **Pastor:** 4 Richtungen + Gebets-Pose
- **NPCs:** 3-5 Typen, 4 Richtungen
- **Buildings:** Kirche, Haus, Park, Shop, Gemeinde-Center
- **Vehicles:** 5-10 Auto-Varianten (verschiedene Farben)
- **UI-Elements:** Buttons, Icons

## Akzeptanzkriterien:
- [ ] Sprite-Loading funktioniert
- [ ] Asset-Caching funktioniert
- [ ] Vehicle-Sprites (5-10) vorhanden
- [ ] Alle Sprites vorhanden

---

## ⚡ ✨ #18: feat: Sprite-basiertes Tile-Rendering [prio: 2, feature] 🏁 [Release 2]
---
**Status / Description:**

Ersetzt die Canvas-Zeichnungen durch Pixel-Art Sprites. Nutzt SpriteBatch für Performance. Blocks #1

---

## ☕ ✨ #10: feat: Audio Engine & Ambient Sound [prio: 3, feature] 🏁 [Release 2]
---
**Status / Description:**

Implementierung von Flame_Audio. Integration von Ambient-Pads und Stadtgeräuschen gemäß Kap. 9 Lastenheft.

---

## ☕ #14: task: Multi-Platform Compatibility Check [question, prio: 3] 🏁 [Release 2]
---
**Status / Description:**

Validierung der Performance und Steuerung auf Web, Android und iOS (Lastenheft Punkt 1).

---

## ☕ #52: question: Design - Health & Hunger System (Keep it Simple?) [question, prio: 3] 🏁 [Release 2]
---
**Status / Description:**

## Frage

Sollen Health und Hunger als vollwertige Mechaniken implementiert werden oder vereinfacht werden?

---

## Optionen

**Option A - Vollwertig:**
- Health & Hunger als eigene Balken im HUD
- Essen/Trinken noetig (im Pastorat oder unterwegs)
- Hunger fuehrt zu Faith-Malus bei 0 %

**Option B - Vereinfacht (Keep it Simple):**
- Nur ein Energie-Balken
- Regeneriert automatisch im Pastorat
- Kein separates Hunger-System

**Option C - Minimal:**
- Health & Hunger vollstaendig entfernen
- Fokus nur auf Faith & Materials

## Ueberlegungen

- Health/Hunger koennen Komplexitaet erhoehen ohne den Core Loop zu bereichern
- Einfachere Mechaniken -> besserer Spielfluss fuer spirituellen Fokus

## Entscheidung gesucht

Welche Option passt am besten zum Spielkonzept?

---

## ☕ ✨ #50: feat: Future - Running/Sprint Mechanic (Doppeltap oder Doppeltaste) [prio: 3, feature] 🏁 [Release 2]
---
**Status / Description:**

## Beschreibung

Pastor soll sprinten koennen, um sich schneller durch die Stadt zu bewegen.

---

## Konzept

- **Mobile:** Doppeltap auf Joystick / Richtungsfeld aktiviert Sprint
- **Desktop:** Doppeldruck auf Bewegungstaste (z. B. W+W) oder dedizierte Sprint-Taste (Shift)
- Sprint dauert max. 5 Sekunden, dann Abklingzeit
- Optional: Sprint kostet leicht Hunger

## Acceptance Criteria

- [ ] Sprint per Doppeltap (Mobile) / Shift (Desktop) ausloesbar
- [ ] Maximale Sprint-Dauer: 5 Sekunden
- [ ] Abklingzeit nach Sprint: 3 Sekunden
- [ ] Visuelles Feedback (z. B. Bewegungsunschaerfe oder Staub-Partikel)

---

## ☕ ✨ #19: feat: Stadt-Grenzen & Biom-Fading [enhancement, prio: 3] 🏁 [Release 2]
---
**Status / Description:**

Implementierung eines Übergangs von Stadt zu unendlicher Natur am Rand der Welt.

---

## #125: feat: Geistliche Festungen & Bollwerke (Prio: Medium)
---
**Status / Description:**

## Konzept
- Festungen spawnen an strategischen Orten in der unsichtbaren Welt.
- Erfordern massives 'anhaltendes Gebet' zum Einnehmen.
- Festungen fungieren als Spawn-Zentren für starke Dämonen.
- Belohnung: Massive Insight-Gutschrift und langanhaltende Reinigung des Sektors.

---

