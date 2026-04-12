#!/usr/bin/env pwsh
# create_new_issues.ps1
#
# Legt die Issues #37–#48 (ohne #42) im Repository an.
# Voraussetzung: gh auth login abgeschlossen
# Ausfuehren:  pwsh scripts/create_new_issues.ps1
#
# Hinweis: gh issue create gibt nicht immer die gewuenschte Nummer zurueck.
# Die Nummern entstehen sequenziell – stelle sicher, dass das Repo keine
# offenen Draft-Issues oder anderweitig belegten Nummern hat.

$REPO = "Paradoxianer/spiritual_city"

Write-Host "=== Erstelle neue Issues fuer spiritual_city ===" -ForegroundColor Cyan
Write-Host "Repo: $REPO" -ForegroundColor DarkGray
Write-Host ""

# ---------------------------------------------------------------------------
# Hilfsfunktion
# ---------------------------------------------------------------------------
function New-Issue {
    param(
        [string]$Title,
        [string]$Body,
        [string]$Labels
    )
    $url = gh issue create `
        --repo $REPO `
        --title $Title `
        --body $Body `
        --label $Labels
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] $Title" -ForegroundColor Green
        Write-Host "       $url" -ForegroundColor DarkGray
    } else {
        Write-Host "  [FEHLER] $Title" -ForegroundColor Red
    }
    return $url
}

# ---------------------------------------------------------------------------
# #37 – feat: Building Interior & House Interaction System  (prio: 1)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "feat: Building Interior & House Interaction System (Betreten von Haeusern)" `
    -Labels "feature,prio: 1" `
    -Body @"
## Beschreibung

Haeuser betreten, Innenraeume erleben und mit NPCs interagieren – ueber das bekannte **Kreis-Menue (Radial Menu)**.

---

## A. Wohnhaeuser (Residential)

**Zugang (Anklopfen):**
- Zugang grundsaetzlich fuer **alle** moeglich (auch fuer Menschen ohne Glauben, nur unwahrscheinlicher)
- Hoher NPC-Glaube (faith > 30): 85 % Erfolgschance
- Neutral (faith -30..+30): 50 % Erfolgschance
- Negativer Glaube (faith < -30): 15 % Erfolgschance
- Nach 3+ Gespraechen: +30 % Bonus auf Erfolgschance

**Interior:**
- Zimmer als Bild/ASCII-Art mit NPCs (Familie sitzt im Raum)
- Moebeldarstellung sichtbar

**Aktionen (Kreis-Menue):**
```
     [Beten]
        |
[Sprechen] -- [NPC] -- [Hilfe]
        |
   [Bibellesen]
```
- [A] Sprechen: +5 Faith, conversationCount +1
- [B] Beten: +15 Faith, +5 Material-Einfluss, Familie beeinflusst
- [C] Hilfe: -10 MP, +10 Faith, NPC-faith +5
- [D] Bibellesen: +10 Faith, Family-faith +2

---

## B. Geschaeftsgebaeude

**Zugang:** Immer offen (kein Anklopfen)

**Aktionen (Kreis-Menue):**
- [A] Um Spenden bitten: +20-40 MP (50 % Erfolgsrate, abhaengig von Manager-Glaube)
- [B] Mit Arbeiter sprechen: +5 Faith
- [C] Fuer Betrieb beten: +10 Faith, Zelle +2 Gruen-Einfluss
- [D] Material verteilen: -5 MP, +15 Faith, Betrieb-Mitarbeiter +3 faith

---

## C. Kirchliche Gebaeude

Zugang immer offen – siehe Lastenheft Kap. 4.

---

Lastenheft Kap. 7.4
"@

# ---------------------------------------------------------------------------
# #38 – feat: NPC Faith Visibility Refinement  (prio: 1)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "feat: NPC Faith Visibility Refinement (Glauben erst nach Gespraechen sichtbar)" `
    -Labels "feature,prio: 1" `
    -Body @"
## Beschreibung

Der Glaube eines NPCs soll **nicht sofort** sichtbar sein – weder durch Emoji noch durch Farbe in der sichtbaren Welt. Erst nach mehreren Gespraechen wird die Geisteshaltung enthuellt.

---

## Enthuellungs-Timeline

| Gespraeche | Anzeige | Bedeutung |
|------------|---------|-----------|
| 0-2 | ? | Komplett unbekannt, neutrales Grau/Weiss |
| 3-5 | (nachdenklich) | Vage Einschaetzung, keine echte Emotion |
| 6+ | Echtes Emoji (Kreuz / wuetend / neutral) | Klare Farbcodierung |

## Wichtig

- **Glaube wird NICHT durch Farbe** in der sichtbaren Welt angezeigt, bevor Gespraeche gefuehrt wurden
- **Glaube wird NICHT durch Emoji** sichtbar, solange conversationCount < 3

## Acceptance Criteria

- [ ] NPCs ohne Gespraeche zeigen neutrales Symbol und neutrale Farbe
- [ ] Nach 3-5 Gespraechen: vages Symbol angezeigt
- [ ] Nach 6+ Gespraechen: korrektes Emoji und Farbcodierung
- [ ] Keine Farb-Vorschau in der realen Welt vor ersten Gespraechen

---

Lastenheft Kap. 6.4
"@

# ---------------------------------------------------------------------------
# #39 – feat: Homebase (Pastorat) Visual Identification  (prio: 1)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "feat: Homebase (Pastorat) Visual Identification" `
    -Labels "feature,prio: 1" `
    -Body @"
## Beschreibung

Das Pastorat (Heimatgebaeude des Pastors) soll visuell klar erkennbar sein – auf der Karte, im HUD und im Spiel.

---

## Anforderungen

- **Sprite:** Haus mit grossem goldenem Kreuz / Leuchten auf dem Dach
- **Aura (reale Welt):** Goldenes Glimmer-Aura um das Gebaeude
- **Minimap-Icon:** Goldenes Stern- / Haus-Icon
- **HUD-Label:** "Home" erscheint, wenn Pastor in der Naehe ist
- **Spawn-Animation:** Kamera fokussiert kurz auf Pastorat beim Spielstart

## Acceptance Criteria

- [ ] Pastorat ist durch Sprite klar vom normalen Wohnhaus unterscheidbar
- [ ] Goldene Aura um Pastorat sichtbar (reale Welt)
- [ ] Minimap zeigt eindeutiges Pastorat-Icon
- [ ] HUD zeigt "Home"-Label wenn Pastor < 100 Einheiten vom Pastorat entfernt ist
- [ ] Kamera-Intro beim Spielstart zeigt Pastorat

---

Lastenheft Kap. 6.5
"@

# ---------------------------------------------------------------------------
# #40 – feat: Street Names & House Numbers  (prio: 2)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "feat: Street Names & House Numbers (Strassennamen & Hausnummern)" `
    -Labels "feature,prio: 2" `
    -Body @"
## Beschreibung

Deterministische Generierung von Strassennamen und Hausnummern fuer alle Gebaeude in der Stadt.

---

## Generierungs-Logik

**Strassennamen:**
- Prefixes: Main, Oak, Church, Grace, Hope, Faith, Light, ...
- Suffixes: Street, Road, Avenue, Lane, Way, Place
- Beispiele: "Main Street", "Church Avenue", "Grace Road"

**Hausnummern:**
- Basierend auf deterministischer Position in der Strasse
- Ungerade Nummern = linke Strassenseite
- Gerade Nummern = rechte Strassenseite
- Beispiel: "Main Street 42", "Oak Road 127"

**HUD-Anzeige:**
```
Current Location: Main Street 42 (Wohnhaus)
```

## Acceptance Criteria

- [ ] Jede Strasse hat einen eindeutigen deterministischen Namen
- [ ] Jedes Gebaeude hat eine eindeutige Hausnummer
- [ ] Selbes Seed = selbe Namen (deterministisch)
- [ ] HUD zeigt aktuellen Strassennamen + Hausnummer
- [ ] Missionen koennen Adressen referenzieren

---

Lastenheft Kap. 7.5
"@

# ---------------------------------------------------------------------------
# #41 – feat: Loot Spawn on Streets  (prio: 2)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "feat: Loot Spawn on Streets (Materialien & Items auf Strassen)" `
    -Labels "feature,prio: 2" `
    -Body @"
## Beschreibung

Material-Pakete spawnen zufaellig auf Strassen und koennen vom Pastor aufgesammelt werden.

---

## Spawn-Regeln

- 5-15 Material-Pakete gleichzeitig aktiv auf sichtbaren Strassen
- Spawn-Chance: 10 % pro Minute pro sichtbarer Strasse
- Nur auf Strassen-Zellen (keine Gebaeude, keine Parks)

## Pickup-Mechanik

- Pastor laeuft nah heran (< 40 Einheiten Radius)
- Material wird highlighted (gelbes Glimmer / Pulsieren)
- Pickup via Aktionsbutton oder Auto-Pickup

## Belohnungen

| Typ    | Chance | Reward |
|--------|--------|--------|
| Klein  | 60 %   | +5 MP  |
| Normal | 30 %   | +10 MP |
| Gross  | 10 %   | +15 MP |

## Effekt auf Unsichtbare Welt

- Zelle: +1 Gruen-Einfluss (symbolisiert praktische Hilfe / Naechstenliebe)

## Acceptance Criteria

- [ ] Material-Pakete spawnen auf Strassen mit korrekter Rate
- [ ] Maximal 15 Pakete gleichzeitig aktiv
- [ ] Highlight-Effekt wenn Pastor in der Naehe
- [ ] Pickup gibt korrekte MP-Belohnung
- [ ] Pickup beeinflusst Unsichtbare Welt (+1 Gruen)

---

Lastenheft Kap. 2.4
"@

# ---------------------------------------------------------------------------
# #43 – fix: Chat Dialog UI  (prio: 2)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "fix: Chat Dialog UI - Abgeschnittenes Icon & Chip-Groesse" `
    -Labels "bug,prio: 2" `
    -Body @"
## Beschreibung

Im Chat-Dialog werden Icons abgeschnitten dargestellt und die Chip-Elemente sind zu klein fuer Touch-Bedienung.

---

## Zu behebende Probleme

1. **Chat-Icon abgeschnitten:** Padding zu gering, Icon wird an Raendern geclippt
2. **Chip-Hoehe zu klein:** Chips sind nicht Touch-freundlich (< 48 px)
3. **Icon-Groesse inkonsistent:** Verschiedene Groessen in verschiedenen Dialog-Zustaenden
4. **Erste Nachricht cut-off:** Erste Chat-Nachricht wird oben abgeschnitten

## Fixes

- Chat-Icon Padding: mind. 4 px auf allen Seiten
- Chip-Hoehe: mind. 48 px (Touch-freundlich nach Material Design Guidelines)
- Icon-Groesse: einheitlich 24 px
- ScrollView/ListView startet korrekt am Anfang (keine verdeckte erste Nachricht)

## Acceptance Criteria

- [ ] Chat-Icon ist vollstaendig sichtbar (kein Clipping)
- [ ] Chip-Hoehe >= 48 px
- [ ] Alle Icons im Dialog haben einheitlich 24 px
- [ ] Erste Nachricht beim Oeffnen des Dialogs vollstaendig sichtbar

---

Lastenheft Kap. 9.3
"@

# ---------------------------------------------------------------------------
# #44 – feat: Expanded NPC Name Database  (prio: 2)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "feat: Expanded NPC Name Database" `
    -Labels "feature,prio: 2" `
    -Body @"
## Beschreibung

Die aktuelle NPC-Namen-Datenbank ist zu klein und fuehrt zu repetitiven Namen. Eine deutlich groessere und vielfaeltigere Namens-Datenbank soll erstellt werden.

---

## Anforderungen

- Mindestens 100 neue Vornamen (maennlich + weiblich)
- Mindestens 50 neue Nachnamen
- Kulturelle/regionale Vielfalt (deutsch, englisch, weitere)
- Namen werden deterministisch per Seed zugewiesen

## Acceptance Criteria

- [ ] NPC-Namen-Pool enthaelt >= 100 Vornamen
- [ ] NPC-Namen-Pool enthaelt >= 50 Nachnamen
- [ ] Keine offensichtlichen Namens-Wiederholungen in einer Stadt
- [ ] Namen sind kulturell divers
"@

# ---------------------------------------------------------------------------
# #45 – feat: Running/Sprint Mechanic  (prio: 3)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "feat: Future - Running/Sprint Mechanic (Doppeltap oder Doppeltaste)" `
    -Labels "feature,prio: 3" `
    -Body @"
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
"@

# ---------------------------------------------------------------------------
# #46 – feat: Universal Keyboard Shortcuts & Keymap Display  (prio: 3)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "feat: Universal Keyboard Shortcuts & Keymap Display" `
    -Labels "feature,prio: 3" `
    -Body @"
## Beschreibung

Ein konsistentes Tastenkuerzel-System fuer Desktop-Spieler sowie eine In-Game Keymap-Anzeige.

---

## Anforderungen

- Definierte Standardtasten fuer alle Aktionen (Bewegen, Interagieren, Beten, Menue, ...)
- In-Game Keymap-Overlay (Taste: z. B. "?" oder "F1")
- Tastenbelegung muss konsistent ueber alle Spielzustaende sein

## Acceptance Criteria

- [ ] Alle Aktionen haben definierte Standardtasten
- [ ] In-Game Keymap-Overlay ist via Taste aufrufbar
- [ ] Overlay zeigt alle Tastenbelegungen uebersichtlich
- [ ] Tastenbelegung funktioniert in realer Welt, unsichtbarer Welt und Dialog
"@

# ---------------------------------------------------------------------------
# #47 – question: Design – Health & Hunger System  (prio: 3)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "question: Design - Health & Hunger System (Keep it Simple?)" `
    -Labels "question,prio: 3" `
    -Body @"
## Frage

Sollen Health und Hunger als vollwertige Mechaniken implementiert werden oder vereinfacht werden?

---

## Optionen

**Option A - Vollwertig:**
- Health & Hunger als eigene Balken im HUD
- Essen/Trinken noetig (im Pastorat oder unterwegs)
- Hunger fuehrt zu Faith-Malus bei 0 %

**Option B - Vereinfacht (Keep it Simple):**
- Nur ein "Energie"-Balken
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
"@

# ---------------------------------------------------------------------------
# #48 – question: Design – Eye Action in Action Ring  (prio: 3)
# ---------------------------------------------------------------------------
New-Issue `
    -Title "question: Design - Eye Action in Action Ring (Augenaktion?)" `
    -Labels "question,prio: 3" `
    -Body @"
## Frage

Soll eine "Auge/Beobachten"-Aktion in den Aktionsring (Radial Menu) aufgenommen werden?

---

## Konzept

- **Augenaktion:** Pastor beobachtet einen NPC oder eine Umgebung genauer
- Moegliche Effekte:
  - Enthuellt mehr Informationen ueber NPC (faith level, Beruf, etc.)
  - Pastorat-Zustand anzeigen
  - Territorium-Info in der unsichtbaren Welt

## Ueberlegungen

- Passt das thematisch? (Pastor beobachtet/erkennt vs. handelt)
- Brauchen wir eine separate Aktion oder reicht der bestehende Dialog?
- Moegliche biblische Basis: "Seht die Menschen an, wie Gott sie sieht"

## Entscheidung gesucht

Soll die Augenaktion in den Aktionsring? Wenn ja: welchen Slot und welchen Effekt?
"@

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Fertig! ===" -ForegroundColor Green
Write-Host "Issues pruefen: gh issue list --repo $REPO --limit 20" -ForegroundColor DarkGray
