# Contributing to SpiritWorld City

> **[🇩🇪 Deutsche Version weiter unten](#-mitmachen--deutsche-version)**

---

## 🇬🇧 Contributing (English)

Thank you for considering a contribution to **SpiritWorld City**!
Please read these guidelines to keep the codebase consistent and the review process smooth.

### 1. Before You Start

- Check the [open issues](https://github.com/Paradoxianer/spiritual_city/issues) to avoid
  duplicating work.
- For larger features, open a discussion issue first so we can agree on the design.
- Fork the repository and create a feature branch from `main`:

  ```bash
  git checkout -b feat/my-feature
  ```

### 2. Commit Messages (Conventional Commits)

Use the format `type: short description` — always in lowercase:

| Type | When to use |
|------|-------------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `refactor:` | Code restructuring without behaviour change |
| `chore:` | Build, tooling, dependency updates |
| `doc:` | Documentation only |
| `test:` | Tests only |

Reference the related issue in every commit or PR description:

```
feat: add building faith bar widget  fixes #42
```

### 3. Code Style

- Follow all rules in [`docs/engineering/rules.md`](docs/engineering/rules.md).
- Run the linter before pushing:

  ```bash
  flutter analyze
  ```

- Run the test suite before pushing:

  ```bash
  flutter test
  ```

### 4. Multilingual Strings (i18n) — Important!

**Never hard-code user-visible text.** Always use the i18n system:

```dart
// ✅ Correct
Text(AppStrings.get('dialog.talk'))

// ❌ Wrong
Text('Talk')
```

When adding or changing any UI string:

1. Add the key **and** its translation to **both** `'de'` and `'en'` maps in
   `lib/src/core/i18n/app_strings.dart`.
2. If you are adding support for an additional language, add a new locale map with
   the same keys.
3. See [`docs/i18n.md`](docs/i18n.md) for the full i18n guide.

### 5. Pull Requests

- Keep PRs focused — one issue per PR.
- Provide a clear description of *what* changed and *why*.
- Screenshots or screen recordings are appreciated for UI changes.
- Ensure `flutter analyze` and `flutter test` pass before requesting review.

---

## 🇩🇪 Mitmachen – Deutsche Version

Danke, dass du zu **SpiritWorld City** beitragen möchtest!
Bitte lies diese Richtlinien, damit der Code konsistent bleibt und Reviews schnell ablaufen.

### 1. Vor dem Start

- Schau dir die [offenen Issues](https://github.com/Paradoxianer/spiritual_city/issues) an,
  um Doppelarbeit zu vermeiden.
- Bei größeren Features zuerst ein Diskussions-Issue öffnen, um das Design abzustimmen.
- Forke das Repository und erstelle einen Feature-Branch aus `main`:

  ```bash
  git checkout -b feat/mein-feature
  ```

### 2. Commit-Nachrichten (Conventional Commits)

Format: `type: kurze Beschreibung` – immer in Kleinbuchstaben:

| Typ | Wann verwenden |
|-----|----------------|
| `feat:` | Neues Feature |
| `fix:` | Fehlerbehebung |
| `refactor:` | Code-Umstrukturierung ohne Verhaltensänderung |
| `chore:` | Build, Tooling, Abhängigkeiten |
| `doc:` | Nur Dokumentation |
| `test:` | Nur Tests |

Das zugehörige Issue in jedem Commit oder in der PR-Beschreibung referenzieren:

```
feat: Glaubensbalken-Widget für Gebäude hinzugefügt  fixes #42
```

### 3. Code-Stil

- Alle Regeln in [`docs/engineering/rules.md`](docs/engineering/rules.md) einhalten.
- Vor dem Push den Linter ausführen:

  ```bash
  flutter analyze
  ```

- Vor dem Push die Tests ausführen:

  ```bash
  flutter test
  ```

### 4. Mehrsprachige Texte (i18n) — Wichtig!

**Niemals UI-Texte hart kodieren.** Immer das i18n-System verwenden:

```dart
// ✅ Richtig
Text(AppStrings.get('dialog.talk'))

// ❌ Falsch
Text('Sprich')
```

Beim Hinzufügen oder Ändern eines UI-Textes:

1. Den Schlüssel **und** die Übersetzung in **beide** Maps (`'de'` und `'en'`) in
   `lib/src/core/i18n/app_strings.dart` eintragen.
2. Beim Hinzufügen einer weiteren Sprache: neue Locale-Map mit denselben Schlüsseln anlegen.
3. Vollständige Anleitung: [`docs/i18n.md`](docs/i18n.md)

### 5. Pull Requests

- PRs fokussiert halten – ein Issue pro PR.
- Klare Beschreibung, *was* geändert wurde und *warum*.
- Screenshots oder Screen-Recordings sind bei UI-Änderungen willkommen.
- Sicherstellen, dass `flutter analyze` und `flutter test` erfolgreich durchlaufen.
