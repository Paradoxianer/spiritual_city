# Flutter Development Rules & Best Practices

## 1. Code-Architektur & Qualität
* **Modularität:** UI-Elemente konsequent in eigene Widgets auslagern. Keine "Monster-Build-Methoden".
* **Simple but Elegant:** Strebe nach maximaler Einfachheit und Eleganz. Komplexität soll in einfache, wartbare Strukturen übersetzt werden, ohne jemals die geforderte Funktionalität zu verringern.
* **DRY & KISS:** Vermeide Duplikate, aber verhindere Over-Engineering. Nutze Flutter-Standards vor Eigenlösungen.
* **Logic Separation:** UI (Widgets) strikt von der Logik trennen. Die `build`-Methode bleibt rein deklarativ.
* **Immutability:** Nutze `final` und `const` konsequent für Performance und Vorhersehbarkeit.

## 2. GitHub Workflow & Issue Tracking
* **Issue:** Editiere niemals issues.md die Datei wird per script erzeugt. Nutze die GitHub CLI (`gh`), um Issues zu verwalten, zu listen oder zu erstellen, falls eine Aufgabe noch nicht dokumentiert ist.
* **Referenzierung:** Verknüpfe Code-Änderungen immer mit der entsprechenden Issue-Nummer.
* **Automatisches Schließen:** Nutze in Commits oder PR-Beschreibungen Closing-Keywords (z.B. `fixes #123`), um den Workflow zu automatisieren.

## 3. Git- & Commit-Disziplin
* **Branching** Wenn du ein neues Feature einsetzt, erstelle ein Branch.
* **Conventional Commits:** Nutze strikt das Format `type: description` (z.B. `feat:`, `fix:`, `refactor:`, `chore:`).
* **Issue-Integration:**  Wenn ein Issue durch einen commit geschlossen wird füge fixe: #issuenr hinzu
* **Scope-Reinheit:** Ein Commit sollte nur Änderungen enthalten, die zum referenzierten Issue gehören.

## 4. Sicherheit & Fehlerbehandlung
* **Null Safety:** Vermeide Force-Unwraps (`!`). Nutze Type-Checks oder Default-Werte.
* **Async-Stabilität:** Verpflichtendes Error-Handling (`try-catch`) bei allen asynchronen Operationen und API-Calls.
* **Logging:** Nutze professionelle Logging-Lösungen statt `print()` im Produktivcode.

## 5. Coding Style & Dokumentation
* **Semantisches Naming:** Variablen und Methoden müssen ihre Funktion präzise beschreiben.
* **Intents dokumentieren:** Kommentiere das "Warum" hinter komplexen Entscheidungen, nicht das offensichtliche "Was".
* **Dateistruktur:** "One Class Per File"-Prinzip zur Wahrung der Übersichtlichkeit.

## 6. Mehrsprachigkeit & i18n
* **Kein Hard-Coding:** Jeder sichtbare UI-Text muss über `AppStrings.get('key')` abgerufen werden – niemals direkt als String-Literal in Widgets schreiben.
* **Vollständigkeit:** Beim Hinzufügen oder Ändern eines Strings diesen in **allen** Locales (`de`, `en`, …) in `lib/src/core/i18n/app_strings.dart` pflegen.
* **Namenskonvention:** Schlüssel folgen dem Punkt-getrennten Schema `<screen>.<element>[.<variante>]` (z. B. `dialog.talk`, `difficulty.easy.desc`).
* **Neue Sprachen:** Vollständige Locale-Map mit allen vorhandenen Schlüsseln anlegen; fehlende Schlüssel fallen auf den Rohschlüssel zurück.
* **Dokumentation:** Vollständige i18n-Anleitung unter `docs/i18n.md`.
