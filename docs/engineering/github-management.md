# 🛠 Development & Workflow Guidelines

## 🏷 GitHub Labels
Diese Labels werden offiziell im Repository verwendet.

| Name | Beschreibung | Farbe | Icon |
| :--- | :--- | :--- | :--- |
| `critical` | Kritisches Problem, das den Fortschritt blockiert | #b60205 | 🔥 |
| `bug` | Etwas funktioniert nicht | #d73a4a | 🔴 |
| `prio: 1` | Hohe Priorität - sofortige Aufmerksamkeit erforderlich | #d73a4a | 🔥 |
| `prio: 2` | Mittlere Priorität | #e99695 | ⚡ |
| `prio: 3` | Niedrige Priorität | #c5def5 | ☕ |
| `feature` | Neue Funktion | #a2eeef | ✨ |
| `enhancement` | Verbesserung einer bestehenden Funktion | #a2eeef | ⚡ |
| `documentation` | Dokumentation | #0075ca | ☕ |
| `question` | Weitere Informationen angefordert | #d876e3 | ❓ |
| `help wanted` | Hilfe benötigt | #008672 | 🙋‍♂️ |
| `invalid` | Ungültig / Kein Fehler | #e4e669 | 🚫 |
| `duplicate` | Duplikat eines anderen Issues | #cfd3d7 | 👯 |
| `wontfix` | Wird nicht bearbeitet | #ffffff | 🙅 |

## 🏁 Milestones (Release Cycles)
Um alle Milestones via CLI aufzulisten:
`gh api repos/Paradoxianer/design_for_life/milestones --jq ".[] | {title: .title, number: .number, state: .state}"`

| ID | Title | Strategic Goal                      |
| :--- | :--- |:------------------------------------|
| **1** | **Release 1 (MVP)** | **MVP - The Multi-Platform Launch** |
| **2** | **Release 2** | **Enhanced Coordination & Selection** |
| **3** | **Release 3** | **Scalability & Polish** |

## 🛠 Useful Commands
- `.\scripts\init_store_metadata.ps1`: Syncs Android & iOS metadata.
- `fastlane supply init`: Fetch metadata from Google Play.
- `gh issue list --milestone 1`: List all issues for Release 1.
- `gh issue list --milestone 2`: List all issues for Release 2.
