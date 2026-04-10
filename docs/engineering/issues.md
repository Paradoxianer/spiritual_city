# 📋 GitHub Issues Roadmap
_Last updated: 10.04.2026 11:20_
_Sorted by Release and Priority (High > Medium > Low)_

## 🔥 ✨ #3: feat: Die Geistliche Welt (The Invisible Realm) [prio: 1, feature] 🏁 [Release 1]
---
**Status / Description:**

Toggle-Mechanik für Weltenwechsel. Visuelle Überlagerung (Blau/Gold vs. Grau/Rot) und Game-of-Life Dynamik. 
die geistliche Welt sollte im Vergelich zur "realen" Welt organischer sein (reale Welt ist ja pixel look) geistliche welt (Transparenter overlay über die Reale WElt" mit permanent verändernderder "lebender" "weichgezeichnetem" look .. so wie eine Lavalampe nur mit einem eigenen Prinzip vergleichbar dem "game of life"
Kap. 2.2 Lastenheft.

---

## 🔥 ✨ #1: feat: Prozedurale Stadt-Generierung + Vehicle Traffic [prio: 1, feature] 🏁 [Release 1]
---
**Status / Description:**

# feat: Prozedurale Stadt-Generierung + Vehicle Traffic

## Stadt-Generierung:
- Grid-basiert (40x40 oder konfigurierbar)
- Straßen-Netzwerk
- Gebäude-Platzierung (zufällig)
- POIs (Parks, Kirchen, etc.)

## Fahrzeuge (NEU):
- 5-10 Auto-Sprites (verschiedene Farben)
- Folgen Straßen-Pfaden
- 30-50 Autos gleichzeitig
- **Keine Kollision mit Pastor** (visuell ambient)
- Motor-Sounds + Hupens

## Performance:
- Spatial Grid für Queries
- Chunk-basiertes Rendering
- 30-50 Autos + 20-30 NPCs stabil

## Akzeptanzkriterien:
- [ ] Stadt prozedural generiert
- [ ] Fahrzeug-Sprites (5-10) vorhanden
- [ ] Autos spawnen/despawnen dynamisch
- [ ] Performance stabil

---

## ⚡ ✨ #8: feat: Daten-Persistenz & Welt-Speicherung [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Implementierung der Speicherlogik mit Hive. Speichern von Zellzuständen (geistlich/real) und NPC-Eigenschaften beim Verlassen des Spiels. Kap. 8 & 10.

---

## ⚡ ✨ #9: feat: Balancing & UX-Fine-tuning [enhancement, prio: 2] 🏁 [Release 1]
---
**Status / Description:**

Optimierung der Game-of-Life Parameter für die geistliche Welt. Validierung der Erfolgskriterien (Intuitive Steuerung, Stabilität). Kap. 13.

---

## ⚡ ✨ #13: feat: Asset Management & Sprite Loading [prio: 2, feature] 🏁 [Release 1]
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

## ⚡ ✨ #2: feat: Spieler-Steuerung & Movement [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Virtueller Joystick (links), Kollisionsabfrage und Kamera-Following für den Pastor. Kap. 4 Lastenheft.

---

## ⚡ ✨ #4: feat: InteractableObject Framework & Mission-Action System [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

# feat: InteractableObject Framework & Mission-Action System

## Framework:
\\\dart
abstract class InteractableObject {
  String name;
  Vector2 position;
  List<InteractionAction> actions;
}

class InteractionAction {
  String title;
  void Function() onExecute;
}
\\\

## 5 Mission-Typen:

1. **Dialog-Missionen:** Sprich mit NPCs (+5-10 Faith)
2. **Dienst-Missionen:** Hilf Menschen (2-3 Min, +10 Faith, +10 MP)
3. **Gebets-Missionen:** Bete im Gebiet (5x Prayer-Combat, +50 Faith)
4. **Sammelmissionen:** Sammle Lebensmittel (+30 MP, +15 Faith)
5. **Territorium-Befreiung:** Multi-Step Mission (+100 Faith, +50 MP, +40 Blau)

## Akzeptanzkriterien:
- [ ] Framework existiert
- [ ] Alle 5 Mission-Typen funktionieren
- [ ] Mission-State korrekt managed

---

## ⚡ ✨ #6: feat: UI-Layer & HUD [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

# feat: UI-Layer & HUD

## Haupt-HUD (Reale Welt):
\\\
OBEN LINKS:
❤️  HEALTH:     ██████░░░░ 60/100
🍽️  HUNGER:     █████░░░░░ 50/100
⛪ FAITH:      ████████░░ 85/100
📦 MATERIALS:  ██████░░░░ 42/100 MP

UNTEN RECHTS:
[A] Interact / [B] Prayer / [X] Menu
\\\

## Prayer-Combat HUD:
\\\
💫  🔷 🔷  💫
🔷    ⛪    🔷
🔷         🔷
🔷     🔷

FAITH INVESTED: 75→60→45...
RING SIZE: ████████░░░░░░ (75%)
🟢 WINDOW OPEN – RELEASE NOW!
\\\

## Akzeptanzkriterien:
- [ ] Resource-Bars korrekt angezeigt
- [ ] Prayer-Ring flüssig
- [ ] Optimal-Fenster sichtbar
- [ ] Buttons klar

---

## ⚡ ✨ #15: chore: Global Error Handling & Logging [enhancement, prio: 2] 🏁 [Release 1]
---
**Status / Description:**

Implementierung eines robusten Error Handlings (try-catch Blocks) und Logging (z.B. mit logger package) laut rules.md.

---

## ☕ ✨ #10: feat: Audio Engine & Ambient Sound [prio: 3, feature] 🏁 [Release 1]
---
**Status / Description:**

Implementierung von Flame_Audio. Integration von Ambient-Pads und Stadtgeräuschen gemäß Kap. 9 Lastenheft.

---

## ☕ ✨ #5: feat: NPC-System & Einfache Missionen [prio: 3, feature] 🏁 [Release 1]
---
**Status / Description:**

Basis-Klasse für NPCs mit geistlichem Zustand (-100 bis +100). Prozedurale Bewohner und erste Dialogmissionen. Kap. 5.3 & 8.2.

---

## ☕ #14: task: Multi-Platform Compatibility Check [question, prio: 3] 🏁 [Release 1]
---
**Status / Description:**

Validierung der Performance und Steuerung auf Web, Android und iOS (Lastenheft Punkt 1).

---

## ☕ #12: chore: Setup GitHub Actions for CI [documentation, prio: 3] 🏁 [Release 1]
---
**Status / Description:**

Automatisierte Tests und Linting bei jedem Push/PR sicherstellen (Analyze & Test).

---

## ⚡ ✨ #23: feat: Deterministic Building Interiors [prio: 2, feature]
---
**Status / Description:**

Jedes Gebäude im Grid erhält basierend auf seinen Welt-Koordinaten einen eindeutigen Seed. 
- Beim Betreten eines Hauses wird ein Innenraum generiert, der bei jedem Besuch identisch bleibt.
- Verknüpfung der Außen-Zelle mit der Innenraum-Logik.
Blocks #8

---

## ⚡ ✨ #21: feat: Building Interaction & Action Button [prio: 2, feature]
---
**Status / Description:**

Ein kontextsensitiver Button im HUD, der erscheint, wenn der Spieler vor einem interaktiven Gebäude steht. 
- Ermöglicht das Betreten von Häusern oder das Handeln mit NPCs.
- Erste Implementierung einer 'Interaktions-Range'.
Blocks #4

---

## ⚡ ✨ #18: feat: Sprite-basiertes Tile-Rendering [prio: 2, feature]
---
**Status / Description:**

Ersetzt die Canvas-Zeichnungen durch Pixel-Art Sprites. Nutzt SpriteBatch für Performance. Blocks #1

---

## ⚡ ✨ #25: feat: Initial Loading Screen & Progress Indicator [enhancement, prio: 2]
---
**Status / Description:**

Zeigt einen Ladebildschirm an, während die ersten Stadt-Chunks generiert werden. Verhindert das 'Springen' der Welt beim Start.

---

## ⚡ ✨ #20: feat: Navigation & Collision System [prio: 2, feature]
---
**Status / Description:**

Implementierung der Kollisionslogik für den Pastor. 
- Erlaubte Zonen: Straßen (Roads), Parks, Gehwege und Naturzellen.
- Hindernisse: Gebäude (Buildings) und tiefes Wasser (Water).
- Ziel: Der Spieler soll sich organisch durch die Stadt bewegen, aber nicht durch Wände gehen können.
Blocks #2

---

## ☕ ✨ #19: feat: Stadt-Grenzen & Biom-Fading [enhancement, prio: 3]
---
**Status / Description:**

Implementierung eines Übergangs von Stadt zu unendlicher Natur am Rand der Welt.

---

## ☕ ✨ #24: feat: NPC AI - Road & Path Navigation [prio: 3, feature]
---
**Status / Description:**

NPCs (Bewohner) sollen sich entlang des Straßennetzes und in Parks bewegen. 
- Pathfinding-Logik für einfache Patrouillen oder Wege von A nach B.
- NPCs reagieren auf den geistlichen Zustand der Zelle, in der sie sich befinden.
Blocks #5

---

