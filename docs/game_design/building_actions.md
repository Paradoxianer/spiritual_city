# Gebäudetypen und Interaktions-Modell

Dieses Dokument definiert die Aktionen, Kosten und Auswirkungen für die verschiedenen Gebäudetypen in *SpiritWorld City*. 
**Prinzip:** "Keep it simple but elegant".

---

## Globale Mechaniken

### Zugang & Interaktion (Access Logic)
- **Wohngebäude (Residential):** Hier muss der Pastor **"Klingeln"** 🔔.
    - Erfolgswahrscheinlichkeit: Basis (Grüne Zelle = einfacher, Rote Zelle = schwieriger) + `(Interaktions-Count * 2%)`.
    - Ab **20 Interaktionen**: Erfolg ist garantiert (100%).
- **Alle anderen Gebäude:** Sind **frei zugänglich** 🚪🔓. Der Pastor kann jederzeit eintreten und das Aktions-Menü öffnen.

### Gebäude-Statistiken (AoE & Power)
| Kategorie | Radius (Zellen) | Power (Spirituell) | Beschreibung |
| :--- | :--- | :--- | :--- |
| **Small (House, Shop)** | 1 | 1.0x | Privater Bereich. |
| **Medium (Apartment, School)** | 3 | 1.5x | Lokaler Einfluss. |
| **Large (Hospital, Mall, Stadium)** | 5 | 2.5x | Regionaler Knotenpunkt. |
| **Spiritual (Church, Cathedral)** | 8-15 | 5.0x | Geistliche Festung. |

> **Hinweis:** AoE-Radius und Power beziehen sich auf Gebäude- und NPC-Einfluss in der unsichtbaren Welt, **nicht** auf den Pastor-Kampf-Radius (der wird über das Upgrade-System in #4 gesteuert).

### Gebäude-Glaube und Bewohner (Issue #168)

**Soll:**
- Der **Gesamt-Glaube eines Hauses** setzt sich aus dem Glauben des Gebäudes **und** dem Glauben seiner registrierten Bewohner zusammen. Bekehrt oder stärkt der Pastor einen Bewohner, steigt der Haus-Glaube spürbar; ein Haus mit Christen ist "heller".
- **Jede erfolgreiche Aktion** in jedem Gebäudetyp erhöht den Interaktionszähler des Gebäudes (mindestens +1; Aktionen mit größerem Aufwand mehr).
- **Jeder Gebäudetyp** hat mindestens eine Aktion, die den Glauben des Gebäudes bzw. der Bewohner erhöht (Prüfung der Tabellen unten, Lücken gehören in die Issue #168).

**Ist-Stand (Code):**
- `BuildingModel.combinedFaith` (Gebäude + Summe der Bewohner) existiert, wird aber **nirgends benutzt**: Der Glaube der Bewohner wirkt derzeit **nicht** auf den Haus-Glauben.
- Wohngebäude (`_residentialAction`): Alle Aktionen erhöhen den Zähler, ggf. mit Bedingungen; die übrigen Typen sind noch zu prüfen.
- Kirchen starten mit 50 % Glauben, das Pastorenhaus mit 100 %; Kirchen/Kathedralen-NPCs sind zu 25 % vorbekehrt, alle anderen zu 3 %.

### Offene Anpassungen (Issues #144, #129)

- **Kirche (#144) — teilweise behoben:** Die Emoji-Folgen im Spiel (`⛪🎹🔥🙌🕊️` für Gottesdienst, `🤲🙏🕊️🙌` für Anbetung) entsprachen bereits dieser Tabelle; das war beim Anlegen des Issues wohl schon anders. Zwei echte Abweichungen behoben:
  - `SpiritWorldGame._buildingMultiplier` behandelte `church` wie ein normales Gebäude (1,5×) statt wie in dieser Tabelle als "Spiritual" (5×, wie Cathedral) — die AoE-Wirkung von Gottesdienst/Anbetung auf die umliegenden Zellen war dadurch 3,3× schwächer als vorgesehen.
  - *Anbetung* stärkte die Kirche selbst nur um +20 (Bewohner +15) — bei einem Startwert von 50 kaum spürbar. Jetzt +60 / +45 ("massiv mehr", wie im Issue gefordert).
  - Die Pastor-Regeneration (+3/Sek) entsprach schon der Spezifikation und wurde nicht verändert.
  - **Nicht geklärt:** ob "AoE-Effekt ist eher negativ" noch etwas anderes meinte als die schwächere Wirkung durch den falschen Multiplikator — dafür bräuchte es einen konkreten Repro-Fall.
- **Balancing (#129):** Gebet im Pastorenhaus mehr Glauben/Befreiungs-AoE (+20 bis +25); Spende auf Aufforderung (NPC-Gespräch) mehr Glauben und mindestens 4 Interaktionen; Gebet im Wohngebäude erhöht auch den Gebäude-Glauben; Bibellesen in Gebäuden je nach Größe 0,2–0,3 Erkenntnis statt 0,5; *Jüngerschaftsgruppe* dauert 1–2 s und wirkt nur positiv, deutlich stärker auf die unsichtbare Welt; jede Bekehrung 0,2 Erkenntnis.
- **Erkunden (#182):** Innenräume können diese Aktionen kontextuell anbieten (siehe `exploration.md`).

---

## 1. Wohngebäude (Residential) 🏘️

### 1.1 Gemeinsame Aktionen
| Aktion | Voraussetzung | Kosten | Auswirkung (Outcome) |
| :--- | :--- | :--- | :--- |
| **Praktische Hilfe** 🛠️🤝📦 | Keine | 10 Materials | **+5 Interaktionen**. Kleiner grüner Impuls in unsichtbarer Welt. |
| **Gebet** 🙏🕊️🙌 | Keine | 10 Faith | Geringe Erfolgswahrscheinlichkeit. Bei Erfolg: +2 Interaktionen, Haus-Zelle wird grüner. |
| **Hausbesuch** ☕🍰🏠 | Interaktionen > 5 | Zeit (Dauer) | **Hunger/Health Refill**. Chance auf Materials-Spenden (`x · Interaktionen`). Bei Spende: **+5 Faith & +4 Interaktionen** (zusätzlich zum Material). |
| **Jüngerschaftsgruppe** 📖👥🔥🧑‍🤝‍🧑 | Interaktionen > 20 + 1 Bekehrter | 50 Faith | **Permanentes Grünfärben** (12:00 Uhr Effekt). Haus wird zum "Lichtpunkt". **+0.5 Geistliche Erkenntnis.** |

### 1.2 Haustyp-Spezifisch
- **House (Einfamilienhaus):** Höhere Spenden-Wahrscheinlichkeit beim Hausbesuch. Fokus: Seelsorge.
- **Apartment (Hochhaus):** **Aktion "Hausgemeinschaft segnen"** 🏢🏘️🙏🕊️: +1 Interaktion bei allen Bewohnern gleichzeitig.

---

## 2. Kommerzielle Gebäude (Commercial) 🛒

Diese Aktionen gelten für Shop, Supermarkt und Mall. Die Mall skaliert die Erträge massiv.

| Aktion | Voraussetzung | Kosten | Auswirkung (Outcome) |
| :--- | :--- | :--- | :--- |
| **Gespräch mit Chef** 💼🤝🗣️👂 | Keine | Zeit | **+3 Interaktionen**. Faith des Gebäudes steigt minimal. |
| **Einkaufen** 🛒🍎📦🥯 | Keine | 5 Materials | **+1 Interaktion**. Pastor erhält +20 Hunger/Health (Versorgung). |
| **Segnen** 🕊️🙌🙏🍞 | Keine | 15 Faith | **+2 Interaktionen**. Bereich in der unsichtbaren Welt wird grüner. |
| **Um Spenden bitten** 🤲📦❤️🩹 | Interaktionen > 2 | **10 Health/Hunger** (Überwindung) | Erfolg basiert auf: `BuildingFaith + Interaktionen`. **Viel Materials bei Erfolg. +5 Faith & +4 Interaktionen bei Erfolg.** |

---

## 3. Öffentliche Einrichtungen (Public) 🏛️

### 3.1 Hospital (Krankenhaus) 🏥
| Aktion | Voraussetzung | Kosten | Auswirkung (Outcome) |
| :--- | :--- | :--- | :--- |
| **Medizinische Hilfe** 🏥💊❤️🩹🩹 | Keine | 15 Materials | **Health/Hunger auf 100% auffüllen.** |
| **Seelsorge (Station)** 👂🤝❤️🩹🩹 | Interaktionen > 3 | Zeit | Ein zufälliger NPC erhält **+15 Interaktionen**. (Fokus auf Zuhören). |
| **Gottesdienst (Kapelle)** ⛪🙏🎶🕊️ | Interaktionen > 10 | 30 Faith | Alle NPCs in Reichweite erhalten **+15 Faith**. |

### 3.2 School / University (Bildung) 🏫
| Aktion | Voraussetzung | Kosten | Auswirkung (Outcome) |
| :--- | :--- | :--- | :--- |
| **Brief an Schulleitung** ✉️🏫✍️📖 | Keine | 5 Materials | **+2 Interaktionen** (Fernwirkung). |
| **Gespräch mit Direktor** 🏫🤝🗣️👂 | Interaktionen > 5 | Zeit | **+5 Interaktionen**. Schaltet "Vortrag" frei. |
| **Werte-Vortrag halten** 🎤📖🎓🏫 | Interaktionen > 15 | Zeit | Viele Interaktionen bei NPCs. Faith steigt minimal. |
| **Gebetskreis gründen** ⭕🙏🔥👥 | Interaktionen > 30 | 60 Faith | Boostet Faith aller NPCs im Viertel täglich um 12:00 Uhr. **+0.5 Geistliche Erkenntnis.** |

### 3.3 Polizei (Police) 👮‍♂️
- **Aktion "Polizei segnen"** 👮‍♂️🛡️🙏🕊️: Verlangsamt das Auftauchen von Dämonen in diesem Distrikt für einen Tag.

---

## 4. Infrastruktur & Verwaltung 🏙️

### 4.1 City Hall (Rathaus) 🏛️
| Aktion | Voraussetzung | Kosten | Auswirkung (Outcome) |
| :--- | :--- | :--- | :--- |
| **Audienz Bürgermeister** 🏛️🤝🗣️👂 | Keine | Zeit | **+3 Interaktionen**. Voraussetzung für Stadt-Gebet. |
| **Für Politiker beten** 🏛️🙏🙌🕊️ | Interaktionen > 20 | **Max Faith & 50 Health/Hunger** | **Stadtweites Gebet:** Gesamte Stadt wird um **0.05 Punkte heller**. (1x pro Woche). |

### 4.2 Train Station (Bahnhof) 🚂
- **Aktion "Reise"** 🚂🛤️🗺️🚆: Öffnet einen Dialog mit allen **bereits besuchten Bahnhöfen in der Stadt**. Der Pastor wird direkt zur gewählten Station teleportiert. Kosten: **10 Materials** (Pauschale, unabhängig von der Entfernung). Nur bekannte (bereits besuchte) Stationen sind auswählbar.

### 4.3 Post Office (Post) ✉️
- **Aktion "Ermutigung schicken"** ✉️🕊️💌📬 | Keine | 5 Materials | Das Spiel wählt **10 zufällige NPCs aus der gesamten Stadt** (aus der globalen NPC-Liste, auch wenn deren Chunk gerade nicht geladen ist). Diese NPCs erhalten **+10 Faith & +2 Interaktionen**, die beim nächsten Betreten ihres Chunks angewendet werden. Effekt steigt, wenn die Absender-Zelle grün ist.

---

## 5. Religiöse Kraftzentren (Spiritual) ⛪

### 5.1 Church / Cathedral ⛪
| Aktion | Voraussetzung | Kosten | Auswirkung (Outcome) |
| :--- | :--- | :--- | :--- |
| **Gottesdienst** ⛪🎹🔥🙌🕊️ | Sonntag | **Fast alle Versorgung (80% Materials) & viel Kraft (60% Health)** | Massiver AOE-Impact auf unsichtbare Welt & NPCs. (Basiert auf aktuellem Zustand der Gemeinde.) |
| **Anbetung / Gebet** 🤲🙏🕊️🙌 | Keine | Zeit | **Regeneriert Faith** beim Pastor (+3/Sek). |

### 5.2 Cemetery (Friedhof) ⚰️
| Aktion | Voraussetzung | Kosten | Auswirkung (Outcome) |
| :--- | :--- | :--- | :--- |
| **Beerdigung** ⚰️🙏🕊️🤝 | Keine | Zeit | **Massive Interaktionsgewinne** bei allen NPCs in der Umgebung. Schaltet "Trost" für diese Session frei. |
| **Trost** 🤝❤️🕊️🩹 | Nur direkt nach "Beerdigung" (wird danach wieder ausgeblendet) | **75% Health & 75% Hunger** | Ein NPC in der Nähe **bekehrt sich sofort**. Aktion verschwindet nach einmaliger Nutzung bis zur nächsten Beerdigung. |

---

## 6. Weitere Spezialgebäude 🏢

### 6.1 Library (Bibliothek) 📚
- **Aktion "Bibelstudium"** 📖📚🧐🙏: Zeitaufwand. Erhöht temporär die Faith-Generierung beim Bibellesen.

### 6.2 Stadium (Stadion) 🏟️
- **Aktion "Großveranstaltung"** 🏟️🙌🔥🎶🕊️: Benötigt Interaktionen > 50, 100 Faith & 100 Materials. Macht Bezirk der unsichtbaren Welt grün. **+0.5 Geistliche Erkenntnis.**
