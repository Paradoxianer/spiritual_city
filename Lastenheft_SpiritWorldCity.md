
# Lastenheft – 2D-Geistliches Open-World-Prozedural-Game („SpiritWorld City“)

## 1. Zielsetzung des Projekts
Ziel ist die Entwicklung eines minimalistisch gestalteten 2D-Top-Down-Spiels, das eine moderne Stadt darstellt, die prozedural generiert wird. Der Spieler übernimmt die Rolle eines Pastors, der zwischen der sichtbaren realen Welt und der unsichtbaren geistlichen Welt wechseln kann.
Durch Gebet, Bibellesen, Gottesdienste und Interaktionen beeinflusst der Spieler beide Welten.

## 2. Spielwelt
### 2.1 Reale Welt
- Moderne prozedural generierte Stadt
- Grid-basiert
- Enthält Straßen, Häuser, Parks, NPCs
- Werte jeder Zelle: Kriminalität, Hoffnung, geistliche Prägung, Bevölkerungsdichte

### 2.2 Unsichtbare Welt
- Transparente Überlagerung
- Farben zeigen geistliche Zustände: Blau/Gold (positiv), Grau/Rot (negativ)
- Dynamik wie Game of Life: dunkle Zellen verstärken Dunkelheit
- Menschen sichtbar als Licht- oder Schattenfiguren

## 3. Spielfigur
- Pastor
- Freie Bewegung in realer Welt
- Wechsel in unsichtbare Welt jederzeit möglich
- Ressourcen: Fokus, Energie/Hunger, geistliche Stärke

## 4. Steuerung
- Joystick links
- Zwei Buttons rechts: Interaktion & Gebet
- In unsichtbarer Welt: Bewegung deaktiviert, Tap-&-Hold-Pulsmechanik

## 5. Kernspielmechaniken
### 5.1 Wechsel der Welten
- jederzeit möglich, keine Cooldowns
- kostet Fokus

### 5.2 Geistlicher Einfluss
- Gebet, Bibel, Gottesdienst erzeugen Einflusszonen
- Reinigen negativer Bereiche

### 5.3 Häuser & Bewohner
- prozedurale Bewohner
- geistliche Zustände (-100 bis +100)
- Mini-Maps in Häusern
- Missionen abhängig vom Bewohnerzustand

### 5.4 Missionen
- Dialogmissionen
- Hilfeleistung
- Stadtteilbefreiung
- Gottesdienstvorbereitung

## 6. Prozedurale Generierung
- Map per Noise/Random Walk
- Gebäudegrößen zufällig
- NPCs mit Routinen

## 7. Grafik
- Minimalistischer Pixelstil (4x4 bis 8x8)
- Wenige Farben

## 8. Datenmodelle
### 8.1 Zellen
- Zustand real + geistlich
### 8.2 NPCs
- geistlicher Zustand, Eigenschaften, Offenheit

## 9. Sound
- Ambient, leichte Pads
- Stadtgeräusche

## 10. Technologie
- Flutter + Flame
- Hive/Drift als Speicher
- Spatial Grid für Welt

## 11. Erweiterbarkeit
- Mehr NPC-Verhalten
- Mehr Missionen
- Multiplayer optional

## 12. Abgrenzung
- Keine Kämpfe
- Keine Fahrzeuge
- Keine High-End-Grafik

## 13. Erfolgskriterien
- Steuerung in < 30s verstanden
- Geistliche Welt intuitiv
- Prozedurale Welt stabil

