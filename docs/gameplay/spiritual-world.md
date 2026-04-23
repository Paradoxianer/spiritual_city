# 🌌 The Spiritual World — SpiritWorld City

> **[🇩🇪 Deutsche Version weiter unten](#-die-geistliche-welt--deutsche-version)**

---

## 🇬🇧 English

The **Spiritual World** (also called the Invisible World) is a transparent overlay that reveals the
hidden spiritual state of every part of the city. As a pastor, your goal is to turn the city from
**red** (darkness) to **green** (light) through prayer combat, service, and faith-building.

### Entering the Spiritual World

- Press **`Q`** to toggle between the Real World and the Spiritual World.
- **Cost:** 7 Faith to enter.
- Your **pastor figure** remains in the same position — you just perceive the spiritual layer.

### The Territory Colour Scale

Every cell (area) of the city has a spiritual value from **−100** (pure darkness) to **+100** (pure light):

| Colour | Value range | Meaning |
|--------|------------|---------|
| 🟢 Sparkling light-green | +30 … +60 | Mild presence of good |
| 🟢 Bright mid-green | +60 … +80 | Strong presence of good |
| 🟢 Deep rich green ✨ | +80 … +100 | Territory fully claimed; Psalm 23:2 |
| ⬜ Beige / white | −30 … +30 | Neutral, contested |
| 🔴 Dark red, pulsing | −30 … −60 | Mild spiritual darkness |
| 🔴 Deep red, thick | −60 … −80 | Strong darkness |
| ⬛ Black-red (lava-lamp) | −80 … −100 | Demonic stronghold; Dan 10:13 |

> At game start, **~80 % of the city is red**. Your long-term goal is to claim it all for good.

### Prayer Combat

Prayer combat is how you directly brighten territory in the spiritual world.

#### Step-by-Step

1. Enter the spiritual world (`Q`).
2. Move near the territory you want to pray over.
3. **Hold `Space`** — the faith-pulse bar starts cycling 0 → 100 → 0 → …
4. **Hold `Shift`** (or move with `W`/`A`/`S`/`D`) to shape and grow the prayer zone.
5. **Release `Space`** at the right moment (70–100 % = optimal window, shown in HUD).
6. Your faith is spent and the cells inside the zone brighten.

#### Timing Matters

| Release timing | Multiplier | Tip |
|---------------|------------|-----|
| 70 – 100 % ✅ | **1.0×** | Wait for the HUD green indicator |
| 50 – 69 % | 0.8× | A bit early — still useful |
| < 50 % | 0.6× | Too early — weak effect |
| 0 – 30 % | 0.4× | Too late — very weak |

#### Zone Shape

- **`Shift` held (no direction):** Zone grows as a circle around the pastor.
- **`W`/`A`/`S`/`D` held:** Zone flares in that direction like a flame.
  *(Acts 2:3 — "tongues of fire distributing themselves")*
- **Nothing held:** Zone stays minimal, focused on the single cell under the pastor.

#### Formula (simplified)

```
faith_spent   = current_faith × pulse_percentage
impact_power  = faith_spent × timing_multiplier × active_modifiers
each cell in zone: cell_value += impact_power × (1 - distance_from_center)
```

### What Influences Territory

Territory value changes from multiple sources:

| Source | Effect |
|--------|--------|
| Prayer combat | Major positive boost (your main tool) |
| Converted NPC present | +2 green per game-day for their cell |
| High-faith NPC (faith > 50) | Small positive pull |
| Distributed Materials at a location | Small +3 green boost |
| Church proximity (+15 per church) | Permanent mild positive field |
| Crime / negative events | Slowly darkens nearby cells |
| Dark NPCs (faith < −50) | Actively darken their cell |
| Daemon entities (wandering) | Drag cells toward darkness as they pass |

### Game of Life Dynamics

Every **in-game hour**, cells influence their neighbours:
- Positive cells nudge adjacent positive cells further toward the light.
- Negative cells pull adjacent cells toward darkness (and the pull is stronger in dark zones).

This means **clusters matter** — a group of green cells is far more resilient than isolated ones.

### Daemon Entities

In the spiritual world you may see **dark pulsing figures** drifting through the city.
These are Daemon entities — they spawn in heavily negative zones (value ≤ −70) and wander,
darkening everything they pass through.

| Zone type | Daemon behaviour |
|-----------|-----------------|
| Dark red zone | Comfortable; no power loss |
| Neutral zone | Darkens cells by 2; daemon loses 2 power |
| Green zone | Darkens cells by 3; daemon loses **6 power** |

> 💡 **Strategy:** Build up green zones to act as barriers — daemons dissolve quickly in them.

**Prayer attracts daemons:** Long prayer sessions increase the daemon spawn rate by +40 %.
This is the risk-reward trade-off — big prayers are powerful but draw attention.

### Progression Modifiers

As you play, you unlock passive modifiers that improve your prayer-combat effectiveness:

| Modifier | Unlock condition | Effect |
|----------|-----------------|--------|
| Inbrunst (Fervour) | 10 prayer combats | Optimal timing window +5 % wider |
| Kraft (Strength) | 3 NPC conversions | Impact power +20 % |
| Weisheit (Wisdom) | 20 NPC conversations | Faith cost −10 % per combat |
| Bewahrung (Preservation) | 1 full territory claimed | Green cell fallback rate −15 % |
| Wachstum (Growth) | 30 NPC conversations | Green cells influence neighbours +10 % |

### Tips

- 💡 **Start near churches** — the +15 passive boost means less prayer combat needed around them.
- 💡 **Claim territory in clusters** — isolated green cells will slowly fade back to neutral.
- 💡 **Watch the daemon warning** in the HUD — a small icon appears when a daemon is nearby.
- 💡 **Short prayers are safer** than long ones when many dark zones surround you.

---

## 🇩🇪 Die Geistliche Welt – Deutsche Version

Die **Geistliche Welt** (auch Unsichtbare Welt) ist ein transparentes Overlay, das den
verborgenen spirituellen Zustand jeden Stadtteils zeigt. Als Pastor ist dein Ziel, die Stadt
durch Gebetskampf, Dienst und Glaubensaufbau von **Rot** (Dunkelheit) zu **Grün** (Licht) zu wandeln.

### Die Geistliche Welt betreten

- **`Q`** drücken zum Wechsel zwischen Realer und Geistlicher Welt.
- **Kosten:** 7 Glaube zum Betreten.
- Der **Pastor** bleibt an derselben Position — du nimmst nur die geistliche Schicht wahr.

### Die Territoriums-Farbskala

Jede Zelle (Bereich) der Stadt hat einen spirituellen Wert von **−100** (reine Dunkelheit) bis **+100** (reines Licht):

| Farbe | Wertebereich | Bedeutung |
|-------|-------------|-----------|
| 🟢 Funkelndes Hellgrün | +30 … +60 | Milde Präsenz des Guten |
| 🟢 Leuchtendes Mittelgrün | +60 … +80 | Starke Präsenz des Guten |
| 🟢 Sattes Dunkelgrün ✨ | +80 … +100 | Territorium vollständig eingenommen; Ps 23,2 |
| ⬜ Beige / Weiß | −30 … +30 | Neutral, umkämpft |
| 🔴 Dunkelrot, pulsierend | −30 … −60 | Milde geistliche Dunkelheit |
| 🔴 Tiefrot, zähflüssig | −60 … −80 | Starke Dunkelheit |
| ⬛ Schwarz-Rot (Lavalampenstil) | −80 … −100 | Dämonische Bastion; Dan 10,13 |

> Beim Spielstart sind **~80 % der Stadt rot**. Dein langfristiges Ziel: alles für das Gute gewinnen.

### Gebetskampf

Gebetskampf ist dein direktes Werkzeug, um Territorium in der geistlichen Welt aufzuhellen.

#### Schritt für Schritt

1. Geistliche Welt betreten (`Q`).
2. In Richtung des gewünschten Territoriums bewegen.
3. **`Leertaste` halten** — der Glaubenspuls-Balken zykliert 0 → 100 → 0 → …
4. **`Shift` halten** (oder `W`/`A`/`S`/`D`) um die Gebetszone zu formen und zu vergrößern.
5. **`Leertaste` loslassen** zum richtigen Zeitpunkt (70–100 % = optimales Fenster, im HUD sichtbar).
6. Glaube wird ausgegeben und die Zellen in der Zone erhellen sich.

#### Timing ist entscheidend

| Zeitpunkt des Loslassens | Multiplikator | Tipp |
|--------------------------|---------------|------|
| 70 – 100 % ✅ | **1,0×** | Auf den grünen HUD-Indikator warten |
| 50 – 69 % | 0,8× | Etwas früh — immer noch nützlich |
| < 50 % | 0,6× | Zu früh — schwacher Effekt |
| 0 – 30 % | 0,4× | Zu spät — sehr schwacher Effekt |

#### Zonenform

- **`Shift` gehalten (ohne Richtung):** Zone wächst als Kreis um den Pastor.
- **`W`/`A`/`S`/`D` gehalten:** Zone flammt in diese Richtung aus.
  *(Apg 2,3 — „Zungen wie von Feuer, die sich verteilten")*
- **Nichts gehalten:** Zone bleibt minimal, fokussiert auf die einzelne Zelle unter dem Pastor.

#### Formel (vereinfacht)

```
Glaube_verbraucht  = aktueller_Glaube × Puls-Prozent
Impact-Kraft        = Glaube_verbraucht × Timing-Multiplikator × aktive_Modifier
pro Zelle in Zone:  Zellwert += Impact-Kraft × (1 - Abstand_vom_Zentrum)
```

### Was das Territorium beeinflusst

| Quelle | Effekt |
|--------|--------|
| Gebetskampf | Großer positiver Boost (dein Hauptwerkzeug) |
| Bekehrter NPC anwesend | +2 Grün pro Spieltag für seine Zelle |
| NPC mit hohem Glauben (> 50) | Kleiner positiver Einfluss |
| Verteilte Materialien an einem Ort | Kleiner +3-Grün-Boost |
| Kirchennähe (+15 pro Kirche) | Dauerhaftes mildes positives Feld |
| Kriminalität / negative Ereignisse | Verdunkelt benachbarte Zellen langsam |
| Dunkle NPCs (Glaube < −50) | Verdunkeln ihre Zelle aktiv |
| Dämonen (wandernd) | Ziehen Zellen auf ihrem Weg in die Dunkelheit |

### Game-of-Life-Dynamik

Jede **Spielstunde** beeinflussen Zellen ihre Nachbarn:
- Positive Zellen treiben benachbarte positive Zellen weiter ins Licht.
- Negative Zellen ziehen benachbarte Zellen in die Dunkelheit (Effekt in dunklen Zonen stärker).

Das bedeutet: **Cluster sind wichtig** — eine Gruppe grüner Zellen ist viel stabiler als einzelne.

### Dämonen

In der geistlichen Welt sind manchmal **pulsierend dunkle Gestalten** zu sehen.
Das sind Dämonen — sie entstehen in stark negativen Zonen (Wert ≤ −70) und wandern,
verdunkeln dabei alles, was sie berühren.

| Zonentyp | Dämonen-Verhalten |
|----------|------------------|
| Dunkelrot | Vertraut; kein Kraftverlust |
| Neutral | Verdunkelt Zelle um 2; Dämon verliert 2 Kraft |
| Grün | Verdunkelt Zelle um 3; Dämon verliert **6 Kraft** |

> 💡 **Strategie:** Grüne Zonen als Barrieren aufbauen — Dämonen lösen sich dort schnell auf.

**Gebet zieht Dämonen an:** Lange Gebetssessions erhöhen die Spawn-Rate um +40 %.
Das ist das Risiko-Belohnungs-Gleichgewicht — starke Gebete sind kraftvoll, erregen aber Aufmerksamkeit.

### Fortschritts-Modifier

Im Laufe des Spiels werden passive Modifier freigeschaltet, die den Gebetskampf verbessern:

| Modifier | Freischalt-Bedingung | Effekt |
|----------|---------------------|--------|
| Inbrunst | 10 Gebetskämpfe | Optimales Timing-Fenster +5 % breiter |
| Kraft | 3 NPC-Bekehrungen | Impact-Kraft +20 % |
| Weisheit | 20 NPC-Gespräche | Glaubenskosten −10 % pro Kampf |
| Bewahrung | 1 vollständig eingenommenes Territorium | Rückfall-Rate grüner Zellen −15 % |
| Wachstum | 30 NPC-Gespräche | Grüne Zellen beeinflussen Nachbarn +10 % stärker |

### Tipps

- 💡 **In der Nähe von Kirchen beginnen** — der passive +15-Bonus bedeutet weniger Gebetskampf nötig.
- 💡 **Territorium in Clustern einnahmen** — isolierte grüne Zellen verblassen langsam zurück zu Neutral.
- 💡 **Dämonen-Warnung im HUD beachten** — ein kleines Symbol erscheint, wenn ein Dämon in der Nähe ist.
- 💡 **Kurze Gebete sind sicherer** als lange, wenn viele dunkle Zonen umgeben.
