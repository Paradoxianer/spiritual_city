#!/usr/bin/env pwsh
# update-issues.ps1
# Synchronisiert GitHub Issues mit dem Lastenheft v3.
# Ausfuehren: .\update-issues.ps1
# Voraussetzung: gh auth login abgeschlossen

$REPO = "Paradoxianer/spiritual_city"

Write-Host "=== GitHub Issues sync ===" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 1. DUPLIKAT SCHLIESSEN
# ---------------------------------------------------------------------------
Write-Host "`n[1/3] Schliesse Duplikate..." -ForegroundColor Yellow

# #22 ist Duplikat von #21 (gleicher Titel, gleicher Inhalt)
gh issue close 22 --repo $REPO --comment "Duplicate of #21." 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ #22 geschlossen (Duplikat von #21)"
} else {
    Write-Host "  ~ #22 war bereits geschlossen oder nicht gefunden"
}

# ---------------------------------------------------------------------------
# 2. BESTEHENDE ISSUES AKTUALISIEREN (kurze Beschreibungen)
# ---------------------------------------------------------------------------
Write-Host "`n[2/3] Aktualisiere bestehende Issues..." -ForegroundColor Yellow

# #1 – Prozedurale Stadt-Generierung
gh issue edit 1 --repo $REPO `
  --title "feat: Prozedurale Stadt-Generierung" `
  --body "Grid-basiertes Stadtsystem mit Noise-basierter Zell-Generierung (Strassen, Gebaeude, Parks, POIs). Chunk-Rendering und Spatial Grid fuer Performance. Kap. 2 & 6 Lastenheft."
Write-Host "  ✓ #1 aktualisiert"

# #3 – Geistliche Welt
gh issue edit 3 --repo $REPO `
  --body "Toggle-Mechanik fuer Weltenwechsel (Kosten: 10 Faith). Transparenter, organisch-lebendiger Overlay ueber die reale Welt nach Game-of-Life-Prinzip. Zellen: Blau/Gold = Licht, Grau/Rot = Dunkelheit (-100..+100). Kap. 5 Lastenheft."
Write-Host "  ✓ #3 aktualisiert"

# #4 – InteractableObject Framework & Missionen
gh issue edit 4 --repo $REPO `
  --title "feat: InteractableObject Framework & Mission System" `
  --body "Abstrakte Basis-Klasse fuer alle interaktiven Objekte (NPCs, Kirchen, Haeuser, Parks). Darauf aufbauend: 5 Mission-Typen (Dialog, Dienst, Gebet, Sammlung, Territoriums-Befreiung). Kap. 6.1 & 7 Lastenheft. Depends on #2, #20."
Write-Host "  ✓ #4 aktualisiert"

# #5 – NPC-System
gh issue edit 5 --repo $REPO `
  --body "NPC-Basisklasse mit faithLevel (-100..+100), Konversations-/Gebets-Zaehler und Memory (letztes Gespraech). Konversions-Logik: conversationCount >= 5 oder prayerCount >= 3 + faithLevel >= 40. Taeglicher Territoriums-Einfluss. Kap. 5.3 & 6.2 Lastenheft. Blocked by #24."
Write-Host "  ✓ #5 aktualisiert"

# #6 – UI-Layer & HUD
gh issue edit 6 --repo $REPO `
  --body "HUD mit 4 Ressourcen-Balken (Health, Hunger, Faith, Materials) oben links und kontext-sensitivem Aktions-Button unten rechts. Separates Prayer-Combat HUD (Ring-Groesse, Faith-Countdown, Timing-Fenster-Indikator) fuer die unsichtbare Welt. Kap. 9 Lastenheft. Depends on #2, #4."
Write-Host "  ✓ #6 aktualisiert"

# #13 – Asset Management
gh issue edit 13 --repo $REPO `
  --body "Sprite-Loading, Asset-Caching und Lazy-Loading fuer alle Entities. Benoetigt werden: Pastor (4 Richtungen + Gebet), NPCs (3-5 Typen), Gebaeude-Sprites, UI-Icons. Kap. 11 Lastenheft."
Write-Host "  ✓ #13 aktualisiert"

# ---------------------------------------------------------------------------
# 3. FEHLENDE ISSUES ANLEGEN
# ---------------------------------------------------------------------------
Write-Host "`n[3/3] Lege fehlende Issues an..." -ForegroundColor Yellow

# Resource System
$existingResource = gh issue list --repo $REPO --search "Resource System Faith" --json number --jq ".[0].number" 2>$null
if (-not $existingResource) {
    gh issue create --repo $REPO `
      --title "feat: Resource System (Faith & Materials)" `
      --label "feature,prio: 1" `
      --body "Faith als Primär-Ressource (generiert durch Beten, Gespräche, Gottesdienste; verbraucht bei Weltenwechsel und Prayer-Combat). Materials als Sekundär-Ressource (aus Kirchensammlungen; verbraucht bei Hilfsprojekten, gibt Faith-Bonus). Kap. 2.1 & 2.2 Lastenheft. Blocks #6."
    Write-Host "  ✓ 'Resource System' erstellt"
} else {
    Write-Host "  ~ 'Resource System' existiert bereits (#$existingResource)"
}

# Prayer Ring Combat
$existingPrayer = gh issue list --repo $REPO --search "Prayer Ring Combat" --json number --jq ".[0].number" 2>$null
if (-not $existingPrayer) {
    gh issue create --repo $REPO `
      --title "feat: Prayer Ring Combat Mechanics" `
      --label "feature,prio: 1" `
      --body "Skill-basierter Gebet-Mechanismus in der unsichtbaren Welt: Ring waechst (0->max), Faith-Zaehler laeuft herunter. Spieler muss im richtigen Timing-Fenster loslassen (OPTIMAL 70-100% = 1.0x, FRUEH <50% = 0.6x, SPAET <30% = 0.4x). Impact-Radius = faith_spent * 3. Kap. 2.3 & 9.2 Lastenheft. Depends on #3, #6."
    Write-Host "  ✓ 'Prayer Ring Combat' erstellt"
} else {
    Write-Host "  ~ 'Prayer Ring Combat' existiert bereits (#$existingPrayer)"
}

# Church Mechanic
$existingChurch = gh issue list --repo $REPO --search "Church Mechanic Faith" --json number --jq ".[0].number" 2>$null
if (-not $existingChurch) {
    gh issue create --repo $REPO `
      --title "feat: Church Mechanic & Faith Regeneration" `
      --label "feature,prio: 2" `
      --body "Kirche als zentraler Faith-Hub: Bibellesen (+15 Faith), Gemeinde-Gebet (+20 Faith), Gottesdienst (+40 Faith, +30 Materials). Pastorat als Home-Base mit passiver Faith-Regeneration (+1/Sek). Kap. 3.2 & 4 Lastenheft. Depends on #1, #4."
    Write-Host "  ✓ 'Church Mechanic' erstellt"
} else {
    Write-Host "  ~ 'Church Mechanic' existiert bereits (#$existingChurch)"
}

Write-Host "`n=== Fertig! ===" -ForegroundColor Green
Write-Host "Aktuelle Issues pruefen: gh issue list --repo $REPO" -ForegroundColor DarkGray
