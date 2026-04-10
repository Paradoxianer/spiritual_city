#!/usr/bin/env pwsh
# update-issues-v2.ps1
# Synchronisiert GitHub Issues mit dem Lastenheft v3 (Update: Farbe, Dual-Combat, Modifier).
# Ausfuehren: pwsh scripts/update-issues-v2.ps1
# Voraussetzung: gh auth login abgeschlossen

$REPO = "Paradoxianer/spiritual_city"

Write-Host "=== GitHub Issues sync v2 ===" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 1. BESTEHENDE ISSUES AKTUALISIEREN
# ---------------------------------------------------------------------------
Write-Host "`n[1/3] Aktualisiere bestehende Issues..." -ForegroundColor Yellow

# #3 – Geistliche Welt: Farbe + organischer Stil + ungleichmaessige Startverteilung
gh issue edit 3 --repo $REPO `
  --title "feat: Die Geistliche Welt (The Invisible Realm)" `
  --body @"
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

**Game-of-Life Dynamik:** Zellen beeinflussen Nachbarn stündlich.

Kap. 5.1, 5.3 Lastenheft.
"@
Write-Host "  ✓ #3 aktualisiert (Farbe Gruen/Rot, Lavalampe, Gauss)"

# #6 – UI-Layer & HUD: Prayer-Combat HUD anpassen
gh issue edit 6 --repo $REPO `
  --body @"
HUD mit 4 Ressourcen-Balken (Health, Hunger, Faith, Materials) oben links und kontext-sensitivem Aktions-Button unten rechts.

**Prayer-Combat HUD (Unsichtbare Welt):**
- Zeigt zwei unabhaengige Balken: FAITH POWER (pulsiert 0->100%) und ZONE SIZE (waechst mit Joystick)
- Visuell: flammige Zone um den Pastor formt sich je nach Joystick-Richtung
- Timing-Fenster-Indikator (gruen wenn 70-100%)
- Abort-Button (-5 Faith)

Kap. 9 Lastenheft. Depends on #2, #4.
"@
Write-Host "  ✓ #6 aktualisiert (Dual-Control HUD)"

# ---------------------------------------------------------------------------
# 2. PRAYER RING COMBAT -> DUAL-CONTROL COMBAT
# ---------------------------------------------------------------------------
Write-Host "`n[2/3] Aktualisiere oder erstelle Prayer Combat Issue..." -ForegroundColor Yellow

$existingPrayer = gh issue list --repo $REPO --search "Prayer" --state open --json number,title `
  | ConvertFrom-Json | Where-Object { $_.title -match "Prayer" } | Select-Object -First 1

if ($existingPrayer) {
    $prayerNum = $existingPrayer.number
    gh issue edit $prayerNum --repo $REPO `
      --title "feat: Dual-Control Prayer Combat Mechanics" `
      --body @"
Skill-basierter Gebet-Mechanismus in der unsichtbaren Welt mit zwei unabhaengigen Eingaben:

**INPUT A – Faith-Button (rechter Daumen):**
- Gedrückt halten: Faith-Ladebalken pulsiert zyklisch 0% -> 100% -> 0%
- Loslassen: loest den Angriff aus; aktueller %-Wert = Timing-Multiplikator
- OPTIMAL (70-100%): 1.0x | FRUEH (<50%): 0.6x | SPAET (<30%): 0.4x

**INPUT B – Joystick (linker Daumen):**
- Nur gedrückt (keine Richtung): Ringfoermige Zone waechst gleichmaessig um Pastor
- In Richtung gedrueckt: Ring beugt sich flammig in Joystick-Richtung (Apg 2,3)
- Zone waechst solange Joystick gedrückt; schrumpft langsam beim Loslassen
- Farbintensitaet der Zone zeigt Groesse/Kraft

**Ausloesung:**
- Zone wird erst aktiviert wenn INPUT A losgelassen wird
- Groessere Zone = mehr Flaeche, aber weniger Kraft pro Zelle
- Mehr Faith = staerkerer Gesamteffekt

Kap. 2.3 & 9.2 Lastenheft. Depends on #3, #6.
"@
    Write-Host "  ✓ #$prayerNum aktualisiert (Dual-Control Prayer Combat)"
} else {
    gh issue create --repo $REPO `
      --title "feat: Dual-Control Prayer Combat Mechanics" `
      --label "feature,prio: 1" `
      --body @"
Skill-basierter Gebet-Mechanismus in der unsichtbaren Welt mit zwei unabhaengigen Eingaben:

**INPUT A – Faith-Button (rechter Daumen):**
- Gedrückt halten: Faith-Ladebalken pulsiert zyklisch 0% -> 100% -> 0%
- Loslassen: loest den Angriff aus; aktueller %-Wert = Timing-Multiplikator
- OPTIMAL (70-100%): 1.0x | FRUEH (<50%): 0.6x | SPAET (<30%): 0.4x

**INPUT B – Joystick (linker Daumen):**
- Nur gedrückt (keine Richtung): Ringfoermige Zone waechst gleichmaessig um Pastor
- In Richtung gedrueckt: Ring beugt sich flammig in Joystick-Richtung (Apg 2,3)
- Zone waechst solange Joystick gedrückt; schrumpft langsam beim Loslassen
- Farbintensitaet der Zone zeigt Groesse/Kraft

**Ausloesung:**
- Zone wird erst aktiviert wenn INPUT A losgelassen wird
- Groessere Zone = mehr Flaeche, aber weniger Kraft pro Zelle
- Mehr Faith = staerkerer Gesamteffekt

Kap. 2.3 & 9.2 Lastenheft. Depends on #3, #6.
"@
    Write-Host "  ✓ 'Dual-Control Prayer Combat' erstellt"
}

# ---------------------------------------------------------------------------
# 3. NEUE ISSUES ANLEGEN
# ---------------------------------------------------------------------------
Write-Host "`n[3/3] Lege neue Issues an..." -ForegroundColor Yellow

# Modifier-System
$existingModifier = gh issue list --repo $REPO --search "Modifier" --state open --json number `
  | ConvertFrom-Json | Select-Object -First 1

if (-not $existingModifier) {
    gh issue create --repo $REPO `
      --title "feat: Modifier-System (Progressive Kampf- & Territoriums-Verstaerker)" `
      --label "feature,prio: 2" `
      --body @"
Einfaches, passives Modifier-System das durch Spielfortschritt freigeschaltet wird.
Kein aktives Ausruesten noetig - einmal freigeschaltet immer aktiv.

**COMBAT-MODIFIER (Kampfring):**
| Modifier | Unlock | Effekt |
|---|---|---|
| Inbrunst | 10x Prayer Combat | Timing-Fenster +5% breiter |
| Ausdauer | 5 Territorien teilweise eingenommen | Zone waechst 20% schneller |
| Konzentration | 10x Bibellesen | Faith-Pulse 15% langsamer |
| Kraft | 3 NPCs konvertiert | Impact-Power +20% |
| Weisheit | 20 Gespraeche | Faith-Kosten -10% |

**TERRITORIUMS-MODIFIER (Eingenommene Bereiche):**
| Modifier | Unlock | Effekt |
|---|---|---|
| Bewahrung | 1 Territorium vollstaendig eingenommen | Rueckfall-Rate -15% |
| Gemeinde | 5 Christen in einer Zelle | Zelle verliert weniger Einfluss/Tag |
| Wachstum | 30 Gespraeche | Grüne Zellen beeinflussen Nachbarn +10% |
| Fundament | Kirche in eingenommenem Gebiet | Zellen um Kirche resistent gegen Rueckfall |

Kap. 5.4 & 10.1 Lastenheft. Depends on #3, Prayer-Combat Issue.
"@
    Write-Host "  ✓ 'Modifier-System' erstellt"
} else {
    Write-Host "  ~ 'Modifier-System' existiert bereits (#$($existingModifier.number))"
}

# Invisible World Visual Renderer (Gauss + Perlin)
$existingRenderer = gh issue list --repo $REPO --search "Gaussian Renderer" --state open --json number `
  | ConvertFrom-Json | Select-Object -First 1

if (-not $existingRenderer) {
    gh issue create --repo $REPO `
      --title "feat: Invisible World Visual Renderer (Gaussian Blur + Perlin Lava)" `
      --label "feature,prio: 1" `
      --body @"
Technische Implementierung des organischen Looks fuer die unsichtbare Welt.

**Anforderungen:**
- Zell-Farbwerte (-100..+100) werden mit Gaussian Blur weichgezeichnet (kein Pixellook)
- Negative Zellen (-60..-100): animierte Perlin-Noise-Verschiebung (Lavalampen-Effekt, 'daemonisch')
- Positive Zellen (+60..+100): funkelnde Partikel-Effekte oder leichtes Pulsieren
- Farbskala: Dunkelrot/Schwarz (negativ) <-> Beige/Weiss (neutral) <-> Hellgruen/Dunkelgruen (positiv)
- Transparenter Overlay ueber die reale Pixel-Welt

**Performance:**
- Gaussian Blur nur auf aendernde Bereiche anwenden (dirty-rect Optimierung)
- Perlin-Noise vorab berechnen und pro Frame interpolieren

Kap. 5.1 Lastenheft. Depends on #3.
"@
    Write-Host "  ✓ 'Invisible World Renderer' erstellt"
} else {
    Write-Host "  ~ 'Invisible World Renderer' existiert bereits (#$($existingRenderer.number))"
}

Write-Host "`n=== Fertig! ===" -ForegroundColor Green
Write-Host "Aktuelle Issues: gh issue list --repo $REPO" -ForegroundColor DarkGray
