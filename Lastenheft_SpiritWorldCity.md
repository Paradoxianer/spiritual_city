
# Lastenheft – 2D-Geistliches Open-World-Prozedural-Game („SpiritWorld City")
## VERSION 3 – VEREINFACHT, PRAKTISCH, IMPLEMENTIERBAR

---

## 1. ZIEL DES SPIELS

Ein spirituelles Sandbox-Simulationsspiel, wo ein Pastor eine prozedural generierte Stadt in zwei Welten gleichzeitig beeinflusst:

- **Reale Welt:** Stadt mit NPCs, Verkehr, Gebäuden
  - Pastor läuft herum, spricht mit Menschen, dient, sammelt Ressourcen
  - **Zweck:** Faith & Materials (Ressourcen) akkumulieren
  
- **Unsichtbare Welt:** Spirituelles Overlay mit dynamischer Zell-Farbe (Rot = Dunkel, Grün = Licht)
  - Pastor betritt diese durch Gebets-Button
  - **Zweck:** Mit gesammeltem Faith "Territorium für Jesus gewinnen"
  - **Mechanik:** Pulsing-Ring-Combat mit Skill-Element

**Core Loop:**
1. In realer Welt umherlaufen → Faith & Materials sammeln
2. Zu Kirche/Pastorat gehen → Faith durch Bibellesen + Gebet regenerieren
3. In unsichtbare Welt wechseln → Gesamten Faith im Ring-Combat "ausgeben"
4. Territorium wird Grün/Gold → NPCs werden empfänglicher → mehr Ressourcen
5. Zurück zu Schritt 1

---

## 2. RESSOURCEN-SYSTEM (UNIVERSAL & SIMPEL)

### 2.1 FAITH (Glaube) – Primäre Ressource

**Generierung (In Realer Welt):**
- Bibellesen in Kirche: +10-20 Faith
- Gebet mit Gemeinde: +5-15 Faith
- Mit NPCs sprechen (positiv): +0-5 Faith .aber es wird immer klarer welchen "Faith" stand die Person hat.
- Hilfsaktion durchführen: +5-10 Faith
- NPC konvertiert zum Glauben: +30 Faith
- Gottesdienst halten: +20-50 Faith

**Verbrauch:**
- **Weltenwechsel zur unsichtbaren Welt:** 7 Faith (Eintritts-Kosten)
- **Gebets-Ring in unsichtbarer Welt:** Wird vollständig aufgebraucht (siehe 2.3)

**Regeneration:**
- Passiv in Kirche/Pastorat: +1 Faith/Sekunde wenn wartend
- Täglich: Wenn Pastor >2h in Kirche verbracht hat → nächster Morgen kein Drain

**Darstellung im HUD:**
```
FAITH: [████████░░] 85/100
```

---

### 2.2 MATERIALS (Sachspenden & Versorgung)

**Einheit:** "Material Points" (MP)
- Repräsentiert: Lebensmittel, Kleidung, Medikamente, Baumaterial, etc.
- **Nicht-monetär**, sondern direkte Sachspenden
- Visuell: "Kartons" oder "Pakete" im Inventory
- Materials können selten auf der Straße gefunden und über aktionsring aufgelesen werden

**Generierung (In Realer Welt):**
- Misison gehe zu Haus.. x,y (wir benötigen Strapßennamen und Hausnunmmern (vor allem commerzellie /firmen gebäudeI und hole Spenden ab..)
- Kirchen-Sammlung: +20-40 MP pro Gottesdienst
- Missionen bei NPCS finde  NPCs (NPCS mit misisonen mit hüpfendem Pfeil gekennzeichet..): +50-xxx MP pro Misison (im Chat missions icon--> ÜPfeil mi Fragezeichen emjoi??? oder so was??)
- Gemeinde-Hilfe organisieren: +30-50 MP

**Verbrauch:**
- Mit bedürftigen NPCs teilen: -10 MP, +15 Faith (!) 
- Kirche instand halten: -5 MP/Spieltag +10 Faith
- Gemeinde-Projekte (Obdach-Hilfe, Essen für Arme): -30-50 MP, +20-30 Faith

**Effekt auf unsichtbare Welt:**
- Zellen wo Materialien verteilt wurden: +3 Grün (sanfter Effekt)
- Symbolisiert: "praktischer Glaube reinigt Territorium"

**Missionen**
- bestimmte Missionen bei NPCS oder Häusern können deine Kapazität für Materials und Faith erhöhen

**Darstellung im HUD:**
```
MATERIALS: [██████░░░░] 42/100 MP
(Icon: Karton/Paket)
```

---

### 2.4 Loot Spawning on Streets (Issue #41)

**Spawn-Regeln:**
- 5–15 Material-Pakete gleichzeitig aktiv auf sichtbaren Straßen
- Spawn-Chance: 10 % pro Minute pro sichtbarer Straße
- Nur auf Straßen-Zellen (keine Gebäude, keine Parks)

**Pickup:**
- Pastor läuft nah heran (< 40 Einheiten Radius)
- Material wird highlighted (gelbes Glimmer / Pulsieren)
- Pickup via Aktionsbutton oder Auto-Pickup
- Reward: +5–15 Material Points
  - 60 % → small (+5 MP)
  - 30 % → normal (+10 MP)
  - 10 % → groß (+15 MP)

**Effekt auf Unsichtbare Welt:**
- Zelle: +1 Grün-Einfluss (symbolisiert praktische Hilfe / Nächstenliebe)

---

### 2.3 GLAUBE IN DER UNSICHTBAREN WELT – DUAL-CONTROL-COMBAT

**Zwei unabhängige Eingaben steuern den Gebetkampf:**

#### INPUT A – Faith-Button (rechter Daumen / Taste)
- Gedrückt halten → Faith-Ladebalken pulsiert zyklisch von 0 % → 100 % → 0 % → …
- Beim **Loslassen** wird der aktuelle %-Wert als Timing-Multiplikator eingefroren und der Angriff ausgelöst
- **Visuelle Stärke:** Farbintensität der Zone zeigt Größe/Kraft
- der Glaubenswert wird anteilig auf den über input b ausgewählten bereich verteilt...
- Spöter gibt es versch. modifier die den Effekt der Verteilung des Glaubenswertes modifiezieren umd stärker zu werden
- Biblische Basis: Jakobus 5,16 *„Das inbrünstige Gebet eines Gerechten vermag viel"* – Intensität ist steuerbar

#### INPUT B – Joystick (linker Daumen)
- **Nur gedrückt (ohne Richtung):** Ringförmige Zone wächst gleichmäßig um den Pastor (auch pulsierend görßer und kleiner werden max größe kann später durch modifier angepasst werden)
- **In Richtung gedrückt:** Ring beugt sich flammig in die gewählte Richtung aus (Apostelgeschichte 2,3: *„Zungen wie von Feuer, die sich verteilten"*)
- Zone wächst pulsiert auch... solange der Joystick gedrückt bleibt
- Beim Loslassen: Zone schrumpft langsam zurück auf minimal radius (wenn nix gedrückt dann wird alles Fait auf die minimal möglichstes Zelle fokusiert )
- **Wichtig:** Die Zone wird **erst** beim Loslassen von INPUT A aktiviert (beide Eingaben kombiniert)
- Josua 1,3: *„Jede Stätte, worauf eure Fußsohle tritt, habe ich euch gegeben"* – du wählst Richtung und Ausdehnung aktiv und kannst so stratgeisch dein befreiung der unsichtbaren welt auf berreiche fokusieren

**Szenario (Ablauf):**
1. Pastor in unsichtbarer Welt, z.B. **75 Faith**
2. Spieler drückt **Joystick** in Richtung Nordosten → Kreis  erweitert sich  flammig in diese Richtung
3. Gleichzeitig hält Spieler **Faith-Button** gedrückt → Ladebalken pulsiert
4. Beim **optimalen Moment** (z.B. 85 %) lässt Spieler den Faith-Button los → Angriff auf die geformte Zone

**Visuelle Darstellung:**
```
╔════════════════════════════════════════╗
║       PRAYER COMBAT MODE               ║
╠════════════════════════════════════════╣
║                                        ║
║             🔥🔥                       ║
║           🔥    🔥                    ║  ← Flamme beugt sich
║         🔥  Pastor  ○                 ║     nach Joystick-Richtung
║           ○        ○                  ║
║                                        ║
║ FAITH POWER: [████████░░░░░░] 65 %   ║  ← Pulst 0→100→0
║ ZONE SIZE:   [██████░░░░░░░░] 45 %   ║  ← Wächst mit Joystick
║                                        ║
║ 🟢 OPTIMAL WINDOW: 70-100%            ║
║ [A] LOSLASSEN → ANGRIFF AUSLÖSEN      ║
╚════════════════════════════════════════╝
```

**Timing-Fenster (Faith-Button):**
- **Optimal (70–100 %):** Timing-Multiplikator **1.0x**
- **Früh (<50 %):** Multiplikator **0.6x**
- **Zu spät (0–30 %):** Multiplikator **0.4x**

**Berechnungsformel bei Release:** 
```
timing_multiplier = {
  1.0 if faith_pulse in [70%, 100%],   // OPTIMAL
  0.6 if faith_pulse < 50%,            // EARLY
  0.4 if faith_pulse in [0%, 30%]      // LATE
}

zone_area   = joystick_held_duration * growth_rate    // Fläche der Zone
zone_shape  = ring | flame(direction)                 // je nach Joystick

faith_spent = faith_at_start * faith_pulse_percentage
impact_power = faith_spent * timing_multiplier * active_modifiers

// Alle Zellen in der Zone werden beeinflusst:
for each cell in zone_area:
  cell_influence += impact_power * (1 - distance_from_center)
```

**Wichtig:** 
- Je mehr Faith man investiert, desto größer der Effekt
- Aber: Optimal-Timing muss noch getroffen werden
- **Neue Spieler:** Vielleicht mit weniger Faith anfangen (20-30) um Timing zu lernen

---

## 3. SPIELFIGUR: PASTOR

### 3.1 Attribute
```
HEALTH:    [██████░░░░] 60/100
HUNGER:    [█████░░░░░] 50/100
FAITH:     [████████░░] 85/100    ← Primary Ressource
MATERIALS: [██████░░░░] 42/100    ← Sekundär-Ressource
```

### 3.2 Home Base: Pastorat/Wohnung
- **Funktion:**
  - Sicherer Ort zum Ausruhen
  - Bibellesen-Station
  - Essen & Trinken (regeneriert Health)
  - Sitzen im Gebet-Zimmer (Faith +1/Sek)

- **Visual:** Pixeliges Häuschen mit Fenster, "Home" markiert auf Minimap

---

## 4. KIRCHEN – SANCTUARY FÜR FAITH-REGENERATION

**Kirchen sind prozedural platziert** (Gebäude mit Kreuz-Symbol)

**Mögliche Aktionen in Kirchen:**

| Aktion | Dauer | Reward | Kosten |
|--------|-------|--------|--------|
| Bibellesen | 10 Min | +15 Faith | - |
| Mit Gemeinde beten | 15 Min | +20 Faith | - |
| Stilles Gebet | 10 Min | +10 Faith | - |
| Gottesdienst halten | 20 Min | +40 Faith, +30 MP | - |

**Bibellesen Mechanik (Teleprompter):**
```
┌──────────────────────────────────────┐
| Römer 10,17                          |
| "Glaube kommt durch Hören            |
|  des Wortes Gottes..."               |
|                                      |
| [Reflect 15s more] [Continue]        |
└──────────────────────────────────────┘
```
- Pro Vers: ~30 Sek Lesedauer
- Liste von 15-20 wichtigen Bibelversen
- Reward: +10-15 Faith

---

## 5. UNSICHTBARE WELT – TERRITORIUM-KONTROLLE

### 5.1 Visuelle Darstellung

**Transparenter Overlay über reale Welt:**

```
POSITIVE ZONEN (Grün):
- Hellgrün, funkelnd:    Milde Präsenz Gottes (+30..+60)
- Mittelgrün, leuchtend: Starke Präsenz Gottes (+60..+80)
- Dunkelgrün, satt:      Sehr stark für Gott eingenommen (+80..+100)
  → Dunkelgrün = maximale Einnahme, Psalm 23,2; Offb 22,1-2

NEGATIVE ZONEN (Rot):
- Dunkelrot, pulsend:    Milde Dunkelheit (-30..-60)
- Tiefrot, zähflüssig:   Starke dämonische Präsenz (-60..-80)
- Dunkelrot-Schwarz:     Dämonische Bastion (-80..-100)
  → Bewegt sich wie Lavalampe, Jes 1,18; Dan 10,13

NEUTRAL: Beige/Weiß (-30..+30, Unentschieden)
```

**Visueller Stil (organisch, Gaußisch):**
- **Kein harter Pixel-Look** – organischer look, die unsichtbare Welt ist das Gegenteil der realen Welt
- Jeder "cell" kann jede beliebige schattierung von dunkelgrün über grau bis dunkelrot-schwarz einnehen
- Zell-Farbwerte werden mit **Gaussian Blur** oder vergleich weichgezeichnet (organisch, fließend)
- Dunkle Zonen bekommen **animierte Perlin-Noise-Verschiebung** → Lavalampen-Effekt also dunkle punkte die sich durch die nicht so dunklen berreich durchbwegen... (viel Bewegung um organische / lebendes sytem darzustellen)
- Positive Zonen können **funkelnde Partikel** oder leichtes Pulsieren haben
- jeder Bereich hat unterschiedlich rote berreiche (also hotspots... diese "knubbeln" sich in ganz besonders dunklen Berreichen)

**Game-of-Life Dynamik:**
- Jede Spielstunde: Zellen beeinflussen ihre Nachbarn
- Positive Zellen verstärken nahegelegene positive Zellen
- Negative Zellen tun dasselbe mit Negativem
- Territorium "breitet sich aus" organisch
- der verstörkungseffekt bzw. einnahme Effekt bei den dunklen Berreichen ist allerdings größer..

### 5.2 Zell-Einfluss-Berechnung
[solten wir vlt noch mal überarbieten]
Dunkle Berreich in der unsichtbaren Welt beeinflussen die Bereichschaft Glauben "aufzubbauen" von NPCS
in der realen Welt... positiv und negativ
Glaubende NPCS beeinflussen die unsichtbare Welt...
entsprechend ihres Glaubens... wird immer ein kleiner Teil (12 Uhr nachmittags) von allen (über 0) NPCS
auf die unsichtbare Welt umgelegt... (keine Ahnung aber bei den NPC drain (also -) 0.000001* faith oder so.. und im unsichtbaren Welt
halt dann 0.001 * Faith der bereich ins positive umgewandelt...
die berechung klingt auch nicht schlecht wie beommen wir das zusammen 
```
cell_influence = (
    base_spiritual_state +          // Start: -100 bis +100
    (npc_faith_in_cell * 0.3) +    // Glaubende Menschen
    (recent_prayer_power * 0.5) +   // Frische Gebete
    (materials_distributed * 0.2) + // Sachspenden vor Ort
    (nearby_churches * 15) +        // Kirchen strahlen +15 pro Kirche
    (gol_neighbor_influence * 0.4)  // Game of Life Nachbar-Effekt
    - (crime_reports * 0.3)        // Kriminalität
    - daemon_residuum_strength * 0.5   // Daemon-Residuum-Stärke (0..10 nach Auflösung, klingt ab)
)

// Zelle zwischen -100 und +100 clamped
// Farbe basiert auf Intensität
```

### 5.3 Initiale Stadt-State

**Bei Spielstart – bewusst ungleichmäßig:**
- 80% der Stadt: ROT/Dunkelrot (Dunkelheit dominiert)
- es spanen nur in der unsichtbaren welt (dunkle Mächte[NPCs])
- **Verteilung ist absichtlich unregelmäßig:** Einige Bereiche sehr dunkel (-90), andere nur leicht negativ (-20)
- Dämonische Schwerpunkte (Bastion-Zellen) ziehen benachbarte Zellen stärker ins Negative
- Kirchen-Zellen: +50 Grün (isolierte positive Inseln)
- Pastorat: +20 Grün (schwach)
- Parks: Neutral (0)
- Arme Gegenden: etwas negativ (-20)
- Reiche Gegenden: neutral bis schwach positiv (+10)

**Animation (optional):**
- Beim ersten Betreten der unsichtbaren Welt: langsames „Einblenden" der roten Lavalampen-Bereiche
- Vermittelt dramatisch die Ausgangslage
- oder allgemein beim betren der unsichtbaren welt ein "überblednen über weiß" wie "aufblitzen. .oder so..
---

### 5.5 DAEMON NPC SYSTEM – WANDERNDE BÖSE MÄCHTE (Issue #31)
**Konzept:** Dämonen/böse Mächte als wandernde, negativ beeinflussende NPCs in der unsichtbaren Welt. Sie entstehen in dunkelroten Bereichen, wandern durch die Welt und hinterlassen überall dort Dunkelheit, wo sie durchziehen – bis ihre Kraft erschöpft ist.
**Biblische Basis:**
- Mt 12,43–45: *„Wenn der unreine Geist vom Menschen ausgefahren ist, durchwandert er wasserlose Stätten"* → Daemon-Bewegung als „ruhelos Wandern"
- Dämonen schwächen sich in gottgeweihten Bereichen: Lukas 10,17–19 (Jesu Autorität über böse Geister)
- Gebet zieht geistliche Aufmerksamkeit an: 1. Petrus 5,8; Daniel 10,12–13
#### Daemon-Lebenszyklus
```
SPAWN:
  - Nur in stark negativen Zonen (cell.value <= -70)
  - Basis-Spawn-Rate: 1 Daemon pro 60 Sekunden bei genug roten Zellen
  - Erhöhte Spawn-Rate durch aktive Gebets-Aktion (Kap. 2.3): +40%
BEWEGUNG:
  - Wandert "random-walk" (zufällig + leichte Tendenz zu positiven Zellen)
  - Geschwindigkeit: ~1 Zelle pro Tick
AUFLÖSUNG:
  - Wenn ihre_kraft <= 0: dissolve()
  - Hinterlässt "Daemon-Residuum"-Marker auf der Auflösungs-Zelle
```
#### Daemon-Mechanik (Pseudocode)
```python
class DaemonNPC:
    kraft: -1 bis -100   # Finsternis-Kraft (entspricht "Anti Faith")
    position: Vector2
    # Bewegung pro Tick:
    def on_enter_cell(self, cell):
        if cell.value <= -50:           # ROTE Zone
            cell.value -= 1             # Zelle minimal eindunkeln
            # (kein Kraft-Verlust: der Dämon ist in "heimischem Terrain")
        elif -30 <= cell.value <= 30:   # NEUTRALE Zone
            cell.value -= 2             # Zelle eindunkeln
            self.kraft -= 2             # Gegenwind kostet Kraft
        elif cell.value >= 50:          # GRÜNE Zone
            cell.value -= 3             # Höherer Widerstand!
            self.kraft -= 6             # 2× Verlust im "heiligen" Bereich!
            # Widerstandswert der Zelle erhöht den Kraft-Verlust zusätzlich:
            self.kraft -= cell.cell_resistance * 0.05
        if self.kraft <= 0:
            self.dissolve()
    def dissolve(self):
        current_cell.daemon_residuum = True   # Marker setzen
        current_cell.value -= 5               # Residuum-Dunkelheit
        self.destroy()
```
#### Daemon-Residuum-Marker
Nach der Auflösung eines Daemons:
- Die Zelle erhält einen **Daemon-Residuum-Marker** (visuell: spezielle Dunkelrot-Tönung, Perlin-Asche-Partikel)
- `daemon_residuum`-Wert fließt in die `cell_influence`-Berechnung ein (Kap. 5.2): `- (daemon_residuum * 0.5)`
- Marker klingt mit der Zeit ab (nach ~5 Spielminuten ohne negativen Einfluss)
- Kann durch gezieltes Prayer-Combat schneller beseitigt werden
#### Visuelle Darstellung der Daemon-NPCs
```
- Daemon-Gestalt:     Pulsierendes Dunkelrot mit düsterer Aura
- Bewegungsspur:      Schweif-Effekt (wie zähflüssige Tinte)
- Auf grüner Fläche:  Sichtbarer "Kampf" – Daemon flackert, schrumpft
- Auflösung:          Zerfalls-Partikel → hinterlässt "Asche" (Residuum-Marker)
- HUD-Warnung:        Kleines Symbol erscheint wenn Daemon in Nähe des Pastors
```
#### Gebets-Attraktion & Strategisches Risiko-Reward
| Spieler-Aktion | Konsequenz |
|---|---|
| **Kurz beten** | ✅ Sicherer; ❌ Weniger Gebets-Kraft |
| **Lang beten** | ✅ Stärkerer Gebets-Effekt; ❌ Daemon-Attraction +40 %, Spawn-Rate steigt |
| **Grüne Bereiche ausbauen** | ✅ Dämonen lösen sich schnell auf; ❌ Hohe Faith-Kosten |
| **Rote Zonen ignorieren** | ✅ Sicher; ❌ Mehr Daemon-Spawns dort |
| **Kirchen-Nähe nutzen** | ✅ Dämonen haben höheren Kraft-Verlust; ❌ Begrenzter Radius |
#### Balance-Parameter
```
DAEMON_SPAWN_THRESHOLD      = -70    // Zell-Mindestwert für Spawn
BASE_SPAWN_INTERVAL_SEC     = 60     // Basis-Spawn-Intervall
PRAYER_SPAWN_INCREASE_PCT   = 40     // % erhöhte Spawn-Rate beim Beten
PRAYER_ATTRACTION_MULT      = 2.5    // Anziehungsmultiplikator
ATTRACTION_DURATION_SEC     = 30     // Sekunden bis Attraktion abklingt
RESIDUUM_DECAY_MIN          = 5      // Minuten bis Residuum-Marker verblasst
```

### 5.6 Prayer Effects Visibility – Gebets-Effekte NUR in unsichtbarer Welt (Issue #31)

**Wichtig:** Alle visuellen Effekte von Gebet und Prayer Combat (Schockwellen, Farbänderungen, Territorienveränderungen) sind **NUR in der Unsichtbaren Welt sichtbar**. In der realen Welt gibt es **KEINE** visuellen Rückmeldungen auf Gebetsaktionen.

- Gebet in der realen Welt: Pastor führt Animation durch (z. B. Kniebeugen) – kein Effekt sichtbar auf Umgebung
- Territorium-Änderungen, Partikel, Lavalampen-Effekte: nur im Unsichtbaren-Welt-Overlay
- HUD zeigt Faith-Zuwachs, aber KEINE Zell-Änderung in realer Ansicht

---

## 6. NPC-SYSTEM MIT GEDÄCHTNIS

### 6.1 InteractableObject Framework

**Alles in der Welt, das interaktiv ist, erbt von InteractableObject:**

```dart
abstract class InteractableObject {
  String name;
  Vector2 position;
  List<InteractionAction> actions;
}

class InteractionAction {
  String title;          // "Sprich mit Maria"
  String description;
  int faithRequired;
  void Function() onExecute;
}
```

**Beispiele:**

| Object | Action 1 | Action 2 | Action 3 |
|--------|----------|----------|----------|
| **NPC** | "Sprich" | "Bete für ihn" | "Diene" |
| **Kirche** | "Bibellesen" | "Mit Gemeinde beten" | "Gottesdienst" |
| **Park** | "Für Park beten" | "Müll aufräumen" | - |
| **Haus (mit NPC)** | "Klopfen" | "Mit Familie beten" | - |
| **Gemeinde-Zentrum** | "Hilfe org." | "Spende sammeln" | - |

---

### 6.2 NPC-Memory System

```dart
class NPCProfile {
  String name;
  int faithLevel = 0;               // -100 bis +100
  int conversationCount = 0;        // Wie oft gesprochen?
  int prayerCount = 0;              // Wie oft für ihn gebetet?
  bool isConvertedChristian = false;
  DateTime lastInteraction;
}
```

**Konversions-Bedingungen:**
1. faithLevel ≥ 40
2. conversationCount ≥ 5 ODER prayerCount ≥ 3
4. Pastor wählt "Sprich über Glauben" Dialog-Option
5. → NPC konvertiert: isConvertedChristian = true, faithLevel wird automatisch auf wenn noch nicht auf über 50 gesetzt 

**Effekte nach Konversion:**
- NPC regeneriert +2 Grün pro Tag in der unsichtbaren welt ihrer Zelle wo sie gerade sind (oder schau mal oben die bobachtung
- NPC die auch christen sind (isConverted Christian) hilft anderen Christen in seineer unmittelbaren umgebung (welche entfernung?) im Glauben zu wachsen --> die anderen Christen +  0.0000001 (macht das sinn aber wenn viele chsiten in einem Bereich könnte das ja schnell viel werden?)
- +30 Faith Reward an Pastor

---

### 6.3 NPC-Einfluss auf Territorium

**Täglich (um 12:00 Uhr):**
(muss noch überarbeitet werden siehe Berechnung 5.2)
```
for each npc in city:
  cell = npc.position.toCell()
  
  if npc.isConvertedChristian:
    cell.influence += npc.faithLevel * 0.3  // Z.B. +24 (→ Grün)
  else if npc.faithLevel > 50:
    cell.influence += 5  // Schwach positiv (hellgrün)
  else if npc.faithLevel < -50:
    cell.influence -= npc.faithLevel * 0.2  // Negativ verstärken (roter)
andere NPCS in der Nähe auch mit glauben stärken
```

**Effekt:** 
- Ein konvertierter Christ in einer roten Zelle kann sie auf langezeit damit zu Grün kippen
- Viele Christen in Zelle = starkes Dunkelgrün mit sparkling effekt

---

### 6.4 NPC Faith Progressive Discovery System (Issue #38)

**Problem:** Der Glaube/die Geisteshaltung eines NPC ist aktuell sofort durch Emojis erkennbar ✝️ / 😠 / 👤 etc.

**Lösung:**
- Glauben wird **NICHT sofort offengelegt** – weder durch Emoji noch durch Farbe in der sichtbaren Welt
- Nur neutrales Symbol (❓) ohne geführte Gespräche – kein Rückschluss auf Glaube möglich
- Glauben wird auch **NICHT durch Farbe** in der sichtbaren Welt angezeigt, bevor Gespräche geführt wurden

**Enthüllungs-Timeline:**
- **0–2 Gespräche:** ❓ (komplett unbekannt, neutrales Grau/Weiß)
- **3–5 Gespräche:** 🤔 (vage Einschätzung, noch nicht die echte Emotion)
- **6+ Gespräche:** echtes Emoji (✝️ / 😠 / 👤) + klare Farbcodierung

---

### 6.5 Homebase (Pastorat) Visual Identification (Issue #39)

**Problem:** Das eigene Haus (Pastorat) des Pastors ist visuell nicht deutlich erkennbar.

**Lösung:**
- **Sprite:** Haus mit großem goldenem Kreuz / Leuchten auf dem Dach
- **Aura (reale Welt):** Goldenes Glimmer-Aura um das Haus
- **Minimap:** Goldenes Stern- / Haus-Icon
- **HUD:** „🏠 Home"-Label wenn Pastor sich in der Nähe befindet
- **Spawn-Animation:** Beim Spielstart fokussiert die Kamera kurz auf das Pastorat

---

## 7. MISSIONEN – VEREINFACHTES ACTION-SYSTEM

### 7.1 Standard-Missionen (gebunden an Objects)

**Jedes InteractableObject kann Missionen haben:**

```dart
class Mission extends InteractionAction {
  String missionId;
  MissionState state;  // NOT_STARTED, ACTIVE, COMPLETED
  
  void onAccept() { state = ACTIVE; }
  void onComplete() { 
    state = COMPLETED;
    giveRewards();
  }
}
```

### 7.2 Missionstypen (Einfach implementierbar)

#### A. Dialog-Missionen
- **Trigger:** Neben NPC, "Sprich"-Button
- **Flow:** Dialog-Optionen anzeigen
- **Reward:** +5-10 Faith, NPC-conversationCount +1
- **Scheitern:** Keine Strafe, einfach weniger Effekt

#### B. Dienst-Missionen
- **Trigger:** "Diene" Button bei NPC oder an Ort (evlt markiert mit springenden Pfeil über NPCs
- **Flow:** 2-3 Min Animation (helfen, reparieren, etc.)
- **Reward:** +10 Faith, +10 MP, NPC-faithLevel +5
- **Effekt:** Zelle +2 Grün-Einfluss

#### C. Gebets-Missionen (In unsichtbarer Welt)
- **Trigger:** Automatisch wenn Stadtteil >70% ROT
- **Mission:** "Bete für dieses Territorium"
- **Aufgabe:** Führe 3-5 Prayer-Combats in diesem Gebiet durch
- **Reward:** +50 Faith, Gebiet kippt +30 Grün
- **Beschreibung:** "Dieser Bereich braucht geistlichen Kampf"

#### D. Sammelmissionen
- **Beispiel:** "Sammle Lebensmittel für Bedürftige"
- **Flow:** Gehe zu 3 Haushalten, "Spende"-Option wählen
- **Reward:** +30 MP, +15 Faith
- **Segen-Effekt:** Diese 3 Zellen +3 Grün

#### E. Territoriums-Befreiung (Multi-Step)
- **Trigger:** Stadtteil >75% ROT
- **Steps:**
  1. Bete 5x im Gebiet (Prayer-Combat)
  2. Sprich mit 3+ NPCs im Gebiet
  3. Drücke "Bete Segen über Bereich" Button
- **Reward:** +100 Faith, +50 MP, Bereich wird +40 Grün, Missions unlocked
- **Dauer:** ~30 Min Spielzeit

---

### 7.4 Building Interior & House Interaction System (Issue #37)

**Ziel:** Häuser betreten, Innenräume sehen, mit NPCs interagieren.

#### A. Wohnhäuser (Residential)

**Zugang (Anklopfen):**
- Zugang ist grundsätzlich für **alle** möglich (auch Menschen ohne Glaube)
- **Hoher NPC-Glaube (faith > 30):** sehr wahrscheinlich (85 %)
- **Neutral (faith −30..+30):** wahrscheinlich (50 %)
- **Negativer Glaube (faith < −30):** unwahrscheinlich (15 %)
- **Nach 3+ Gesprächen:** +30 % Bonus auf Erfolgschance
- Bei niedriger Chance: Pastor kann es trotzdem versuchen – Ablehnung ist möglich

**Interior-Darstellung:**
- Zimmer mit Familie/Haushalt als **Bild/ASCII-Art** dargestellt
- NPCs sitzen im Raum (👨 👩 👧)
- Möbel/Einrichtung sichtbar

**Aktionen im Interior – KREIS-MENÜ (Radial Menu):**

Gleiche Mechanik wie der Prayer-Combat-Ring – vertrautes System für den Spieler:

```
     [Beten]
        |
[Sprechen] — [NPC] — [Hilfe]
        |
   [Bibellesen]
```

- **[A] Sprechen:** +5 Faith, conversationCount +1
- **[B] Beten:** +15 Faith, +5 Material-Einfluss auf Zelle, Familie wird beeinflusst
- **[C] Hilfe:** −10 MP, +10 Faith, NPC-faith +5
- **[D] Bibellesen:** +10 Faith, Family-faith +2 (schwacher Effekt)

**Verlassen:** X-Button oder Klick außerhalb

#### B. Geschäftsgebäude (Shop, Office, Factory)

**Zugang:** Immer offen (kein Anklopfen)

**Aktionen (Kreis-Menü):**

```
   [Spenden bitten]
        |
[Sprechen] — [Manager] — [Für Betrieb beten]
        |
   [Material verteilen]
```

- **[A] Um Spenden bitten:** +20–40 MP (abhängig von Manager-Glaube, 50 % Erfolgsrate)
- **[B] Mit Arbeiter sprechen:** +5 Faith pro Interaktion
- **[C] Für Betrieb beten:** +10 Faith, Zelle +2 Grün-Einfluss
- **[D] Material verteilen:** −5 MP, +15 Faith, Betrieb-Mitarbeiter +3 faith

#### C. Kirchliche Gebäude

- **Zugang:** Immer offen
- **Siehe Kapitel 4:** Bibellesen, Gottesdienst, Gemeindebeten

**Interior-Darstellung (Beispiel):**
```
┌──────────────────────────────┐
│ WOHNZIMMER - Familie Schmidt │
├──────────────────────────────┤
│                              │
│  👨 👩 👧 (Familie sitzt)    │
│                              │
│  Einfaches Zimmer mit Tisch  │
│  & Bildern an der Wand       │
│                              │
│        [Beten]               │
│           |                  │
│  [Sprechen]—[👨]—[Hilfe]    │  ← Radial Menu
│           |                  │
│     [Bibellesen]             │
│                              │
└──────────────────────────────┘
```

---

### 7.5 Street Names & House Numbers (Issue #40)

**Straßennamen (deterministisch generiert):**
- Prefixes: Main, Oak, Church, Grace, Hope, Faith, Light, …
- Suffixes: Street, Road, Avenue, Lane, Way, Place
- Beispiel: „Main Street", „Church Avenue", „Grace Road"

**Hausnummern:**
- Basierend auf Position in der Straße (deterministisch)
- Ungerade Nummern = linke Seite, Gerade Nummern = rechte Seite
- Beispiel: „Main Street 42", „Oak Road 127"

**HUD-Display:**
```
📍 Current Location: Main Street 42 (Wohnhaus)
```

---

### 7.3 Event-basierte Dynamik (Zufällige Incidents)

Objekte (Häuser, Parks, NPCS können "missionen" hinzugefügt bekommen)

**Jede Spielstunde: 5% Chance auf Incident**

```
incidents = [
  { name: "Crime Reported", zone: random_red_zone, 
    action: "Go & Pray", reward: "+15 Faith" },
  { name: "NPC in Distress", npc: random_unhappy_npc,
    action: "Visit & Help", reward: "+20 Faith, +npc.faithLevel +10" },
  { name: "Spiritual Breakthrough", npc: random_almost_converted,
    action: "Finish Dialog", reward: "+npc converts, +30 Faith" },
]
```

---

## 8. BELEBUNG DER REALEN WELT: VERKEHR

### 8.1 Fahrzeug-Sprites & Bewegung

**Einfache Auto-Implementierung:**
- 5-10 verschiedene Auto-Varianten (Farben/Stile)
- 8x8 oder 16x16 Pixel-Sprites
- Bewegen sich auf Straßen-Pfaden (super simpel .. .folge straße .. biege ab (zufällig) wenn keine Kreuzung da ist.. fahr gerade weiter)

### 8.2 Spawn & Despawn

- 30-50 Autos gleichzeitig im Speicher
- Spawnen zufällig an Straßen-Rändern
- Folgen Straßen-Pfaden
- Despawnen wenn außer Sicht

### 8.3 Pastor-Interaktion

- **Autos sind NICHT kollidierbar** (Pastor läuft durch)
- **Optional später:** "Carpool" – mit Auto fahren (MVP: nicht nötig)

### 8.4 Audio

- Leise Stadtgeräusche
- Leise Motor-Sounds
- Gelegentliche Hupen
- Ambient Verkehrslärm

**unsichtbare Welt**
- audio wechselt zu "spärisch"
- in der dunkelheit / dämoinschen gegend eher leicht beeunruhigende Geräuche
- in Grünen berreich... himmliche enspannde geräusche
---

## 9. HUD & UI

### 9.1 Haupt-HUD (Reale Welt)

```
┌─────────────────────────────────────────────┐
│ OBEN LINKS: RESOURCES                       │
│ ❤️ HEALTH: ██████░░░░ 60/100              │
│ 🍽️ HUNGER: █████░░░░░ 50/100              │
│ ⛪ FAITH: ████████░░ 85/100               │
│ 📦 MATERIALS: ██████░░░░ 42/100 MP        │
├─────────────────────────────────────────────┤
│ UNSICHTBARE WELT OVERLAY (transparent)     │
│ (Farbige Zellen zeigen Territorium)        │
├─────────────────────────────────────────────┤
│ UNTEN RECHTS: AKTIONS-BUTTONS              │
│ [A] Interact / [B] Prayer / [X] Menu       │
└─────────────────────────────────────────────┘
```

### 9.2 Prayer-Combat HUD (Unsichtbare Welt)

```
╔═══════════════════════════════════════════╗
║       PRAYER MODE – GEISTLICHER KAMPF     ║
╠═══════════════════════════════════════════╣
║                                           ║
║             🔥🔥🔥                        ║
║           🔥       🔥                    ║  ← Zone wächst/verformt
║         🔥   Pastor   ○                  ║    sich nach Joystick
║           ○         ○                    ║
║                                           ║
║ FAITH POWER: [████████░░░░░░░░░] 65 %   ║  ← Pulsiert 0→100→0
║ ZONE SIZE:   [██████░░░░░░░░░░░] 45 %   ║  ← Wächst mit Joystick
║                                           ║
║ 🟢 OPTIMAL WINDOW: 70-100 %             ║
║ [A] LOSLASSEN → ANGRIFF                  ║
║ [B] ABBRECHEN  (−5 Faith)               ║
╚═══════════════════════════════════════════╝
```

---

### 9.3 Chat Dialog UI Improvements (Issue #43)

**Fixes:**
- Chat-Icon Padding erhöhen (min. 4 px auf allen Seiten – kein abgeschnittenes Icon)
- Chip-Höhe auf mindestens 48 px (Touch-freundlich)
- Icon-Größe standardisieren auf 24 px
- Erste Nachricht im Dialog vollständig sichtbar (kein Cut-off am oberen Rand)

---

## 10. PROGRESSION & BALANCE

### 10.1 Keine klassischen "Level"

Stattdessen: Graduelle Modifier-Freischaltung basierend auf Spielfortschritt (siehe Kap. 5.4)

**Prinzip:** Einfach und managebar – Modifier sind passive Boni, kein aktives Ausrüsten.
[vlt könnten wir das noch ändern.. also durch Missionen "erreichbar" geistliche Missionen helfen z.b. im Glauben zu wachsen.. (glauben wird mehr al 100 .. usw.. somit steht mehr zur verfügung..]
[Evtl. modifier werden aquired durch geistliche Missionen??

```
Nach 10 Prayer Combats:
  → Unlock: Modifier "Inbrunst" (Timing-Fenster breiter)

Nach 5 Territorien teilweise eingenommen:
  → Unlock: Modifier "Ausdauer" (Zone wächst schneller)

Nach 1 vollständig eingenommenem Territorium:
  → Unlock: Modifier "Bewahrung" (Rückfall-Rate sinkt)

Nach 3 Konversionen:
  → Unlock: Modifier "Kraft" (Impact-Power +20%)

... (weitere Modifier aus Kap. 5.4)
```

### 10.2 Schwierigkeits-Anpassungen (Optional)

```
[EASY]
- Opposition in Prayer: -30% Häufigkeit
- Faith regeneriert schneller
- Ring-Fenster: größer (0.8-1.0 statt 0.7-1.0)

[NORMAL]
- Balanciert

[HARD]
- Opposition: +30% Häufigkeit
- NPC-Konversions-Weg: 2x länger
- Ring-Fenster: enger (0.85-1.0)
```

---

## 11. SOUND & ATMOSPHERE

### 11.1 Musik
- **Reale Welt:** Minimale Stadtgeräusche + sanfter Loop
- **Unsichtbare Welt:** Dunkel, ethereal, leicht beängstigend
- **Prayer-Combat:** Aufbauend, episch, orchestral

### 11.2 SFX
- Prayer-Impact: "Whoosh" + Glockenspiel-Ton
- Faith-Regeneration: Sanfter harmonischer Sound
- NPC-Konversion: Hoffnungs-voller melodischer Ton
- Opposition-Attack: Verzerrter Alarm-Sound

---

## 12. CORE LOOP (ZUSAMMENFASSUNG)

```
1. START im Pastorat
   ↓
2. Gehe zu Kirche
   ├─ Bibellesen: +15 Faith
   └─ Bete mit Gemeinde: +20 Faith
   ↓
3. Erkunde Stadt
   ├─ Sprich mit NPCs: +2-5 Faith pro Gespräch
   ├─ Hilfsaktionen: +5-10 Faith, +10 MP
   └─ Sammle Events: evtl. +5-30 Faith
   ↓
4. Gehe in UNSICHTBARE WELT
   ├─ Kosten: 10 Faith Eintritt
   ├─ Dual-Control Prayer-Combats: Faith-Button + Joystick-Zone kombinieren
   ↓
5. Territorium wird GRÜN
   ├─ NPCs in Grün-Zonen werden empfänglicher
   └─ Mehr Faith & MP in diesen Zellen verfügbar
   ↓
6. Wiederhole → Core Loop
```

---

## 13. IMPLEMENTIERUNGS-ROADMAP (VEREINFACHT)

### Phase 1 – MVP (Wochen 1-3)
- Stadt-Generierung
- Pastor-Bewegung
- Basic NPC-System (Gespräche)
- Simple Unsichtbare-Welt (Farb-Overlay)
- Prayer-Ring Mechanik (Wachsen/Schrumpfen)
- Kirche + Bibellesen
- HUD

### Phase 2 – Gameplay-Loop (Wochen 4-6)
- NPC-Memory-System
- Mission-Action-System
- Faith/Material-Regeneration
- Game-of-Life Territorium-Dynamik
- SFX + Musik

### Phase 3 – Polish & Content (Wochen 7+)
- Mehr NPC-Archetypen
- Mehr Missions-Varianten
- Opposition in Prayer (selten)
- Fahrzeug-Verkehr
- Balancing

---

## 14. ERFOLGSKRITERIEN

| Kriterium | Messung |
|-----------|---------|
| Neue Spieler verstehen Steuerung in <60s | Playtests |
| Prayer-Ring fühlt sich "skill-basiert" an | Spieler-Feedback |
| Territorium-Kontrolle ist visuell klar | Farb-Kontrast ausreichend |
| NPCs fühlen sich verschieden an (nicht repetitiv) | Dialog-Varianz |
| Faith-Loop ist motivierend | Spieler möchte weiterspielen |
| Biblische Mechaniken wirken authentisch | Keine negative Kritik zum Konzept |

---

## 15. ABGRENZUNG

**❌ NICHT IM SPIEL:**
- Gewalt/physische Kämpfe gegen Gegner
- Sexuelle oder unangemessene Inhalte
- Denominational-Kritik

**✅ IM SPIEL:**
- Fahrzeug-Verkehr (einfach, ambient)
- Dual-Control Gebets-Kampf-Mechanik (Button für Stärke + Joystick für Zone/Richtung mit Modiferen)
- Territorium-Kontrolle (Rot ↔ Grün, organisch-gaußisch)
- Mission-System (flexibel, nicht-linear)
- Modifier-System (passiv, progressiv, einfach)
- Sandbox mit optionalen Zielen

---
