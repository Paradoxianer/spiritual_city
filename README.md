# 🏙️ SpiritWorld City

> **[🇩🇪 Deutsche Version weiter unten](#-deutsche-version)**

---

## 🇬🇧 English

A 2D procedural top-down open-world game with a spiritual twist — built with Flutter & Flame.

You play as a **pastor** who influences a procedurally generated city in two simultaneous worlds:
the **real world** (talk to people, serve, collect resources) and the **invisible spiritual world**
(prayer-combat to claim territory for good).

### ✨ Features

- 🗺️ **Procedural city generation** – every game world is unique
- 🧑‍🤝‍🧑 **NPC system with memory** – residents remember your actions and grow in faith over time
- ⚔️ **Dual-world gameplay** – switch between the real city and the spiritual overlay
- 🔥 **Prayer-combat mechanic** – timing-based skill system (faith pulse × zone size)
- 🏠 **Building interaction** – churches, homes, shops, civic buildings, each with unique actions
- 📖 **Mission system** – procedural objectives tied to NPCs and locations
- 🌍 **Multilingual UI** – German & English out of the box (easily extensible)
- 💾 **Save / Load** – multiple save slots with per-world state persistence

### 🖥️ Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ Supported |
| iOS      | ✅ Supported |
| Web      | ✅ Supported |
| Linux    | ✅ Supported |
| macOS    | ✅ Supported |
| Windows  | ✅ Supported |

### 🚀 Getting Started

**Prerequisites:** Flutter SDK ≥ 3.0.0 · Dart ≥ 3.0.0

```bash
# 1. Clone the repository
git clone https://github.com/Paradoxianer/spiritual_city.git
cd spiritual_city

# 2. Install dependencies
flutter pub get

# 3. Run (choose your target platform)
flutter run                    # default device
flutter run -d chrome          # web
flutter run -d linux           # desktop
```

### 🗂️ Project Structure

```
lib/
├── main.dart
└── src/
    ├── core/
    │   └── i18n/              # Multilingual string system (AppStrings)
    └── features/
        ├── menu/              # Main menu, difficulty selection, save/load screens
        └── game/
            ├── domain/
            │   ├── models/    # NPCModel, BuildingModel, BaseInteractableEntity …
            │   └── services/  # BuildingInteractionService, MissionService …
            └── presentation/
                ├── components/ # Flame components (PlayerComponent, NpcComponent …)
                └── game_screen.dart  # Flutter UI overlay (HUD, dialogs)
```

### 🌍 Multilingual Support

The app ships with a lightweight custom i18n system (`lib/src/core/i18n/app_strings.dart`).

- **Supported languages:** `de` (German, default) · `en` (English)
- Language can be changed at runtime via `AppStrings.setLanguage('en')`.
- All UI strings are retrieved with `AppStrings.get('key')` — never hard-coded.
- Adding a new language: add a new locale map entry in `AppStrings._translations`.

See [`docs/i18n.md`](docs/i18n.md) for the full guide.

### 🤝 Contributing

We welcome contributions! Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a PR.

Key rules (also in [`docs/engineering/rules.md`](docs/engineering/rules.md)):

- Follow **Conventional Commits** (`feat:`, `fix:`, `chore:`, `doc:` …)
- Reference the related GitHub Issue in every commit/PR
- Keep UI and logic strictly separated
- Use `AppStrings.get()` for **every** user-visible string — no hard-coded text

### 📄 License

This project is source-available for educational and personal use.
See [LICENSE](LICENSE) for details (if present), or contact the repository owner.

---

## 🇩🇪 Deutsche Version

Ein prozedurales 2D-Top-Down-Open-World-Spiel mit spiritueller Handlung — entwickelt mit Flutter & Flame.

Du spielst einen **Pastor**, der eine prozedural generierte Stadt in zwei gleichzeitigen Welten beeinflusst:
der **realen Welt** (mit Menschen reden, dienen, Ressourcen sammeln) und der **unsichtbaren spirituellen Welt**
(Gebetskampf, um Territorium zu gewinnen).

### ✨ Features

- 🗺️ **Prozedurale Stadtgenerierung** – jede Spielwelt ist einzigartig
- 🧑‍🤝‍🧑 **NPC-System mit Gedächtnis** – Bewohner erinnern sich an deine Handlungen
- ⚔️ **Dual-World-Gameplay** – wechsle zwischen realer Stadt und spirituellem Overlay
- 🔥 **Gebetskampf-Mechanik** – Timing-basiertes Skillsystem (Glaubenspuls × Zonengröße)
- 🏠 **Gebäude-Interaktion** – Kirchen, Häuser, Läden, Behörden – jedes mit eigenen Aktionen
- 📖 **Missionssystem** – prozedurale Aufgaben für NPCs und Orte
- 🌍 **Mehrsprachige Benutzeroberfläche** – Deutsch & Englisch von Haus aus (leicht erweiterbar)
- 💾 **Speichern / Laden** – mehrere Speicherslots mit vollständiger Zustandspersistenz

### 🖥️ Plattformen

| Plattform | Status |
|-----------|--------|
| Android   | ✅ Unterstützt |
| iOS       | ✅ Unterstützt |
| Web       | ✅ Unterstützt |
| Linux     | ✅ Unterstützt |
| macOS     | ✅ Unterstützt |
| Windows   | ✅ Unterstützt |

### 🚀 Schnellstart

**Voraussetzungen:** Flutter SDK ≥ 3.0.0 · Dart ≥ 3.0.0

```bash
# 1. Repository klonen
git clone https://github.com/Paradoxianer/spiritual_city.git
cd spiritual_city

# 2. Abhängigkeiten installieren
flutter pub get

# 3. Starten (gewünschte Zielplattform wählen)
flutter run                    # Standardgerät
flutter run -d chrome          # Web
flutter run -d linux           # Desktop
```

### 🌍 Mehrsprachigkeit (i18n)

Die App verwendet ein schlankes, paketfreies i18n-System (`lib/src/core/i18n/app_strings.dart`).

- **Unterstützte Sprachen:** `de` (Deutsch, Standard) · `en` (Englisch)
- Sprache zur Laufzeit wechseln: `AppStrings.setLanguage('en')`
- Alle UI-Texte werden über `AppStrings.get('key')` abgerufen – niemals hart kodiert
- Neue Sprache hinzufügen: neuen Locale-Eintrag in `AppStrings._translations` ergänzen

Vollständige Anleitung: [`docs/i18n.md`](docs/i18n.md)

### 🤝 Mitmachen

Beiträge sind herzlich willkommen! Bitte lies [`CONTRIBUTING.md`](CONTRIBUTING.md), bevor du einen PR öffnest.

Wichtige Regeln (auch in [`docs/engineering/rules.md`](docs/engineering/rules.md)):

- **Conventional Commits** verwenden (`feat:`, `fix:`, `chore:`, `doc:` …)
- In jedem Commit/PR das zugehörige GitHub-Issue referenzieren
- UI und Logik strikt trennen
- `AppStrings.get()` für **jeden** sichtbaren Text verwenden – kein Hard-Coding

### 📄 Lizenz

Dieses Projekt ist für Bildungs- und persönliche Nutzung quelloffen verfügbar.
Details siehe [LICENSE](LICENSE) (falls vorhanden) oder Kontakt mit dem Repository-Inhaber aufnehmen.
