# 📋 GitHub Issues Roadmap
_Last updated: 10.04.2026 08:59_
_Sorted by Release and Priority (High > Medium > Low)_

## 🔥 ✨ #3: feat: Die Geistliche Welt (The Invisible Realm) [prio: 1, feature] 🏁 [Release 1]
---
**Status / Description:**

Toggle-Mechanik für Weltenwechsel. Visuelle Überlagerung (Blau/Gold vs. Grau/Rot) und Game-of-Life Dynamik. 
die geistliche Welt sollte im Vergelich zur "realen" Welt organischer sein (reale Welt ist ja pixel look) geistliche welt (Transparenter overlay über die Reale WElt" mit permanent verändernderder "lebender" "weichgezeichnetem" look .. so wie eine Lavalampe nur mit einem eigenen Prinzip vergleichbar dem "game of life"
Kap. 2.2 Lastenheft.

---

## 🔥 ✨ #1: feat: Prozedurale Stadt-Generierung (Grid-System) [prio: 1, feature] 🏁 [Release 1]
---
**Status / Description:**

Spatial Grid Implementierung. Noise-basierte Generierung der Stadtzellen (Kriminalität, Hoffnung). Pixel-Art Style gemäß Lastenheft Kap. 2 & 6. MUSS DETERMINISTISCH SEIN: Implementierung eines Seed-Systems, sodass derselbe Startwert immer dieselbe Stadt generiert.

---

## ⚡ ✨ #6: feat: UI-Layer & HUD [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Statusanzeigen für Fokus, Energie und geistliche Stärke. Minimales In-Game Menü. Kap. 3 & 10.

---

## ⚡ ✨ #8: feat: Daten-Persistenz & Welt-Speicherung [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Implementierung der Speicherlogik mit Hive. Speichern von Zellzuständen (geistlich/real) und NPC-Eigenschaften beim Verlassen des Spiels. Kap. 8 & 10.

---

## ⚡ ✨ #4: feat: Interaktions-System & Gebets-Mechanik [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Pulsmechanik (Tap-&-Hold) in der unsichtbaren Welt. Einflusszonen zur Reinigung von Zellen. Kap. 5.2 Lastenheft.

---

## ⚡ ✨ #2: feat: Spieler-Steuerung & Movement [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Virtueller Joystick (links), Kollisionsabfrage und Kamera-Following für den Pastor. Kap. 4 Lastenheft.

---

## ⚡ ✨ #15: chore: Global Error Handling & Logging [enhancement, prio: 2] 🏁 [Release 1]
---
**Status / Description:**

Implementierung eines robusten Error Handlings (try-catch Blocks) und Logging (z.B. mit logger package) laut rules.md.

---

## ⚡ ✨ #13: feat: Asset Management & Sprite Loading [prio: 2, feature] 🏁 [Release 1]
---
**Status / Description:**

Implementierung einer sauberen Pipeline zum Laden von Pixel-Art Assets und Mapping auf die Grid-Zellen.

---

## ⚡ ✨ #9: feat: Balancing & UX-Fine-tuning [enhancement, prio: 2] 🏁 [Release 1]
---
**Status / Description:**

Optimierung der Game-of-Life Parameter für die geistliche Welt. Validierung der Erfolgskriterien (Intuitive Steuerung, Stabilität). Kap. 13.

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

## ☕ ✨ #11: feat: Audio Engine & Ambient Sound [prio: 3, feature] 🏁 [Release 1]
---
**Status / Description:**

Implementierung von Flame_Audio. Integration von Ambient-Pads und Stadtgeräuschen gemäß Kap. 9 Lastenheft.

---

