# Release-Checkliste 1.0

Was der Code schon liefert und was **nur der Herausgeber** erledigen kann (Konten, rechtliche Angaben, Entscheidungen, die sich später kaum ändern lassen).

## ✅ Im Code erledigt (M4)
- App-Name „SpiritWorld City“ (Android, Web), vorläufiges App-Icon (`assets/icon/app_icon_1024.png`, Android-Mipmaps, Web-Icons)
- Einstellungen mit Datenschutz, Nutzungsbedingungen, Hinweis für Eltern, Credits & Lizenzen, Impressum (Platzhalter)
- Hinweis beim ersten Start (versioniert über `LegalTexts.consentVersion`)
- Datenschutz-Seite für die Store-URL: `web/privacy.html` → nach dem Deploy unter `https://paradoxianer.github.io/spiritual_city/privacy.html`
- Store-Texte de/en: `docs/release/store_listing.md`
- Version `1.0.0+1` in `pubspec.yaml`

## ⚠️ Vom Herausgeber zu erledigen
1. **Impressum ausfüllen** – `lib/src/features/menu/domain/legal_texts.dart`, alle Stellen mit ⟨…⟩ (Name/Verein, Anschrift, E-Mail). Pflicht in DE.
2. **App-ID festlegen** – heute `com.example.spiritual_city`; Google Play lehnt `com.example` ab. Vorschlag: `de.<deinname>.spiritworldcity`. Ändern in `android/app/build.gradle.kts` (`namespace`, `applicationId`) und im Kotlin-Paket. **Nach dem ersten Store-Upload nicht mehr änderbar.**
3. **Signatur-Schlüssel** – Upload-Keystore erzeugen (`keytool`), `android/key.properties` anlegen (nicht einchecken), `signingConfig` für `release` statt `debug` setzen. Schlüssel sicher aufbewahren; Play App Signing aktivieren.
4. **Konten** – Google Play Console (einmalig 25 $), ggf. Apple Developer Program (99 $/Jahr).
5. **Altersfreigabe (IARC)** im Play-Console-Fragebogen. Vorschlag für die Antworten:
   - Gewalt: Fantasy, ohne Blut, ohne realistische Darstellung (Dämonen werden durch Gebet aufgelöst) → voraussichtlich USK 6 / PEGI 7
   - Religiöse Inhalte: ja
   - Nutzerinteraktion, Standort, Käufe, Werbung: nein
   - Glücksspiel, Drogen, Sexualität, Schimpfwörter: nein (Lebensgeschichten deuten Sucht/Trauer nur als Symbole an)
6. **Datensicherheit (Play „Data safety“)**: „Es werden keine Daten erhoben oder geteilt“.
7. **Zielgruppe**: Wenn Kinder unter 13 angesprochen werden, gelten die „Families“-Richtlinien (keine Werbe-SDKs – erfüllt).
8. **Screenshots** erstellen (siehe `store_listing.md`) und ggf. ein finales Icon von einer Grafikerin/einem Grafiker.
9. **iOS** (optional): Icons im Xcode-Asset-Katalog, Bundle-ID, Signierung über Xcode.
10. **Testlauf**: interner Test-Track in der Play Console, mindestens 1 Woche mit echten Testern.

## Bekannte offene Punkte
- Ambient-Musik/Stadtgeräusche (#10): Kenney-Pakete enthalten keine Musik; Stücke müssten einzeln (z. B. Pixabay) ausgewählt werden.
- Tiles der Stadt sind weiterhin gezeichnet; die Kenney-Stadt-Tiles (#18) sind vorhanden, aber noch nicht zugeordnet.
- 2 alte Testfehler (SpatialGrid mit negativen Koordinaten, `widget_test` setUpAll).
