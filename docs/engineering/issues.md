# 📋 GitHub Issues Roadmap
_Last updated: 10.04.2026 20:40_
_Sorted by Release and Priority (High > Medium > Low)_

## 🔥 ✨ #3: feat: Die Geistliche Welt (The Invisible Realm) [prio: 1, feature] 🏁 [Release 1]
---
**Status / Description:**

Toggle-Mechanik fuer Weltenwechsel (Kosten: 10 Faith).

**Visueller Stil:**
- Transparenter, organisch-lebendiger Overlay ueber die reale Welt
- Zellen werden mit **Gaussian Blur** weichgezeichnet (kein harter Pixel-Look)
- Dunkle Bereiche haben animierte **Perlin-Noise-Verschiebung** (Lavalampen-Effekt)
- Positive Bereiche: funkelnde Partikel / leichtes Pulsieren

**Farbpalette (Rot <-> Gruen):**
- Hellgruen bis Dunkelgruen = Gottes Prasenz (+30..+100)
  - Hellgruen: schwache Prasenz; Dunkelgruen: stark fuer Gott eingenommen
- Rot bis Dunkelrot = Dunkelheit (-30..-100)
  - Tiefrot/Schwarz: daemonische Bastion, bewegt sich wie Lavalampe
- Beige/Weiss: Neutral (-30..+30)

**Startverteilung:**
- 80% der Stadt: ROT, bewusst ungleichmaessig verteilt
- Einige Bereiche sehr dunkel (-90), andere nur leicht negativ (-20)
- Kirchen-Zellen: +50 Gruen (isolierte positive Inseln)

**Game-of-Life Dynamik:** Zellen beeinflussen Nachbarn stÃ¼ndlich.

Kap. 5.1, 5.3 Lastenheft.

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

## ⚡ ✨ #9: feat: Balancing & UX-Fine-tuning [enhancement, prio: 2] 🏁 [Release 1]
---
**Status / Description:**

Optimierung der Game-of-Life Parameter für die geistliche Welt. Validierung der Erfolgskriterien (Intuitive Steuerung, Stabilität). Kap. 13.

---

## ⚡ ✨ #8: feat: Daten-Persistenz & Welt-Speicherung [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Implementierung der Speicherlogik mit Hive. Speichern von Zellzuständen (geistlich/real) und NPC-Eigenschaften beim Verlassen des Spiels. Kap. 8 & 10.

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

## ⚡ ✨ #15: chore: Global Error Handling & Logging [enhancement, prio: 2] 🏁 [Release 1]
---
**Status / Description:**

Implementierung eines robusten Error Handlings (try-catch Blocks) und Logging (z.B. mit logger package) laut rules.md.

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

HUD mit 4 Ressourcen-Balken (Health, Hunger, Faith, Materials) oben links und kontext-sensitivem Aktions-Button unten rechts.

**Prayer-Combat HUD (Unsichtbare Welt):**
- Zeigt zwei unabhaengige Balken: FAITH POWER (pulsiert 0->100%) und ZONE SIZE (waechst mit Joystick)
- Visuell: flammige Zone um den Pastor formt sich je nach Joystick-Richtung
- Timing-Fenster-Indikator (gruen wenn 70-100%)
- Abort-Button (-5 Faith)

Kap. 9 Lastenheft. Depends on #2, #4.

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

## ☕ #12: chore: Setup GitHub Actions for CI [documentation, prio: 3] 🏁 [Release 1]
---
**Status / Description:**

Automatisierte Tests und Linting bei jedem Push/PR sicherstellen (Analyze & Test).

---

## ☕ #14: task: Multi-Platform Compatibility Check [question, prio: 3] 🏁 [Release 1]
---
**Status / Description:**

Validierung der Performance und Steuerung auf Web, Android und iOS (Lastenheft Punkt 1).

---

## 🔥 ✨ #30: feat: Invisible World Visual Renderer (Gaussian Blur + Perlin Lava) [prio: 1, feature]
---
**Status / Description:**

Technische Implementierung des organischen Looks fuer die unsichtbare Welt.

**Anforderungen:**
- Zell-Farbwerte (-100..+100) werden mit Gaussian Blur weichgezeichnet (kein Pixellook)
- Negative Zellen (-60..-100): animierte Perlin-Noise-Verschiebung (Lavalampen-Effekt, daemonisch)
- Positive Zellen (+60..+100): funkelnde Partikel-Effekte oder leichtes Pulsieren
- Farbskala: Dunkelrot/Schwarz (negativ) <-> Beige/Weiss (neutral) <-> Hellgruen/Dunkelgruen (positiv)
- Transparenter Overlay ueber die reale Pixel-Welt

**Performance:**
- Gaussian Blur nur auf aendernde Bereiche anwenden (dirty-rect Optimierung)
- Perlin-Noise vorab berechnen und pro Frame interpolieren

Kap. 5.1 Lastenheft. Depends on #3.

---

## 🔥 ✨ #28: feat: Dual-Control Prayer Combat Mechanics [prio: 1, feature]
---
**Status / Description:**

Skill-basierter Gebet-Mechanismus in der unsichtbaren Welt mit zwei unabhaengigen Eingaben:

**INPUT A â€“ Faith-Button (rechter Daumen):**
- Gedrueckt halten: Faith-Ladebalken pulsiert zyklisch 0% -> 100% -> 0%
- Loslassen: loest den Angriff aus; aktueller %-Wert = Timing-Multiplikator
- OPTIMAL (70-100%): 1.0x | FRUEH (<50%): 0.6x | SPAET (<30%): 0.4x

**INPUT B â€“ Joystick (linker Daumen):**
- Nur gedrueckt (keine Richtung): Ringfoermige Zone waechst gleichmaessig um Pastor
- In Richtung gedrueckt: Ring beugt sich flammig in Joystick-Richtung (Apg 2,3)
- Zone waechst solange Joystick gedrueckt; schrumpft langsam beim Loslassen
- Farbintensitaet der Zone zeigt Groesse/Kraft

**Ausloesung:**
- Zone wird erst aktiviert wenn INPUT A losgelassen wird
- Groessere Zone = mehr Flaeche, aber weniger Kraft pro Zelle
- Mehr Faith = staerkerer Gesamteffekt

Kap. 2.3 & 9.2 Lastenheft. Depends on #3, #6.

---

## ⚡ ✨ #25: feat: Initial Loading Screen & Progress Indicator [enhancement, prio: 2]
---
**Status / Description:**

Zeigt einen Ladebildschirm an, während die ersten Stadt-Chunks generiert werden. Verhindert das 'Springen' der Welt beim Start.

---

## ⚡ ✨ #18: feat: Sprite-basiertes Tile-Rendering [prio: 2, feature]
---
**Status / Description:**

Ersetzt die Canvas-Zeichnungen durch Pixel-Art Sprites. Nutzt SpriteBatch für Performance. Blocks #1

---

## ⚡ ✨ #29: feat: Modifier-System (Progressive Kampf- & Territoriums-Verstaerker) [prio: 2, feature]
---
**Status / Description:**

Einfaches, passives Modifier-System das durch Spielfortschritt freigeschaltet wird.
Kein aktives Ausruesten noetig - einmal freigeschaltet immer aktiv.

**COMBAT-MODIFIER (Kampfring):**
- Inbrunst (10x Prayer Combat): Timing-Fenster +5% breiter
- Ausdauer (5 Territorien teilweise eingenommen): Zone waechst 20% schneller
- Konzentration (10x Bibellesen): Faith-Pulse 15% langsamer
- Kraft (3 NPCs konvertiert): Impact-Power +20%
- Weisheit (20 Gespraeche): Faith-Kosten -10%

**TERRITORIUMS-MODIFIER (Eingenommene Bereiche):**
- Bewahrung (1 Territorium voll): Rueckfall-Rate -15%
- Gemeinde (5 Christen in einer Zelle): Zelle verliert weniger Einfluss/Tag
- Wachstum (30 Gespraeche): Gruene Zellen beeinflussen Nachbarn +10%
- Fundament (Kirche): Zellen um Kirche resistent gegen Rueckfall

Kap. 5.4 & 10.1 Lastenheft. Depends on #3, Prayer-Combat Issue.

---

## ⚡ ✨ #23: feat: Deterministic Building Interiors [prio: 2, feature]
---
**Status / Description:**

Jedes Gebäude im Grid erhält basierend auf seinen Welt-Koordinaten einen eindeutigen Seed. 
- Beim Betreten eines Hauses wird ein Innenraum generiert, der bei jedem Besuch identisch bleibt.
- Verknüpfung der Außen-Zelle mit der Innenraum-Logik.
Blocks #8

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

## ⚡ ✨ #21: feat: Building Interaction & Action Button [prio: 2, feature]
---
**Status / Description:**

Ein kontextsensitiver Button im HUD, der erscheint, wenn der Spieler vor einem interaktiven Gebäude steht. 
- Ermöglicht das Betreten von Häusern oder das Handeln mit NPCs.
- Erste Implementierung einer 'Interaktions-Range'.
Blocks #4

---

## ☕ ✨ #24: feat: NPC AI - Road & Path Navigation [prio: 3, feature]
---
**Status / Description:**

NPCs (Bewohner) sollen sich entlang des Straßennetzes und in Parks bewegen. 
- Pathfinding-Logik für einfache Patrouillen oder Wege von A nach B.
- NPCs reagieren auf den geistlichen Zustand der Zelle, in der sie sich befinden.
Blocks #5

---

## ☕ ✨ #19: feat: Stadt-Grenzen & Biom-Fading [enhancement, prio: 3]
---
**Status / Description:**

Implementierung eines Übergangs von Stadt zu unendlicher Natur am Rand der Welt.

---

