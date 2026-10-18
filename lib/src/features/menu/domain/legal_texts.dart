import '../../../core/i18n/app_strings.dart';

/// Legal and info texts (#93, #150, #151, #153), German and English.
///
/// They describe only what the app really does: saves stay on the device,
/// no account, no analytics, no ads, no in-app purchases, no network
/// requests by the game itself.
///
/// ⚠️ The imprint contains PLACEHOLDERS (marked with ⟨…⟩) that the publisher
/// must fill in with their real details before a store release – they are
/// deliberately not invented here.
abstract final class LegalTexts {
  /// Bump when the privacy notice changes materially: the first-start
  /// notice (#153) is then shown again.
  static const int consentVersion = 1;

  static String get(String key) =>
      (_texts[AppStrings.currentLanguage] ?? _texts['de']!)[key] ?? _texts['de']![key] ?? key;

  static const Map<String, Map<String, String>> _texts = {
    'de': {
      'imprint.title': 'Impressum',
      'imprint.body': '''Angaben gemäß § 5 DDG

⟨Vor- und Nachname / Verein⟩
⟨Straße Hausnummer⟩
⟨PLZ Ort⟩
⟨Land⟩

Kontakt
E-Mail: ⟨E-Mail-Adresse⟩

Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV:
⟨Name, Anschrift wie oben⟩

⚠️ Diese Angaben müssen vor der Veröffentlichung im Store vom Herausgeber ausgefüllt werden.''',
      'privacy.title': 'Datenschutz',
      'privacy.body': '''Kurz gesagt: SpiritWorld City sammelt keine persönlichen Daten.

• Spielstände und Einstellungen (Sprache, Ton, Schwierigkeit) werden nur auf deinem Gerät gespeichert. Sie verlassen das Gerät nicht.
• Es gibt kein Benutzerkonto, keine Anmeldung, keine Werbung, keine In-App-Käufe und keine Analyse- oder Tracking-Dienste.
• Die App selbst stellt keine Verbindungen ins Internet her (zur Web-Version siehe unten).
• Web-Version: Sie wird über GitHub Pages ausgeliefert. Beim Laden der Seite verarbeitet GitHub technisch notwendige Daten (z. B. IP-Adresse) nach seiner eigenen Datenschutzerklärung. Außerdem lädt die Web-Version die Grafik-Engine und Schriften (für Emojis) von Servern von Google (www.gstatic.com, fonts.gstatic.com); dabei wird deine IP-Adresse an Google übertragen. Wir erhalten diese Daten nicht. Die Android-/iOS-App lädt nichts nach.
• Löschen: Deinstalliere die App oder lösche die Spielstände im Menü „Spiel laden“; in der Web-Version die Website-Daten im Browser.

Verantwortlicher: siehe Impressum. Du hast das Recht auf Auskunft, Berichtigung, Löschung und Beschwerde bei einer Aufsichtsbehörde; da wir keine Daten von dir speichern, liegen bei uns keine vor.''',
      'terms.title': 'Nutzungsbedingungen',
      'terms.body': '''• SpiritWorld City ist ein kostenloses Spiel. Es wird ohne Gewähr bereitgestellt; für Datenverlust (z. B. verlorene Spielstände) wird nicht gehaftet, soweit gesetzlich zulässig.
• Das Spiel stellt geistliche Themen vereinfacht und spielerisch dar. Es ersetzt keine Seelsorge, Beratung oder Therapie. Wenn es dir nicht gut geht, sprich mit Menschen, denen du vertraust.
• Bibelzitate: Lutherbibel 1912 (deutsch) und King James Version (englisch), beide gemeinfrei.
• Grafiken und Töne: siehe Credits.''',
      'parents.title': 'Hinweis für Eltern',
      'parents.body': '''Liebe Eltern,

SpiritWorld City ist ein Spiel über einen Pastor, der in einer Stadt Menschen hilft und für sie betet. Es zeigt dabei auch eine „unsichtbare Welt“ mit Dämonen, die durch Gebet besiegt werden – ohne Blut und ohne Gewaltdarstellung.

• Es werden keine Daten Ihres Kindes gesammelt; alles bleibt auf dem Gerät.
• Keine Werbung, keine Käufe, kein Chat mit Fremden.
• Lebensgeschichten der Spielfiguren können schwierige Themen andeuten (z. B. Trennung der Eltern, Sucht, Trauer), immer nur als Symbole und mit dem Ziel der Heilung.

Fragen? Kontakt siehe Impressum.''',
      'consent.title': 'Willkommen!',
      'consent.body': '''Schön, dass du da bist! 😊

Deine Spielstände bleiben nur auf deinem Gerät. Wir sammeln keine Daten, zeigen keine Werbung und es gibt nichts zu kaufen.

Eltern finden alle Infos unter Einstellungen → Hinweis für Eltern, Datenschutz und Impressum.''',
      'consent.accept': 'Los geht\'s',
      'consent.leave': 'Verlassen',
      'credits.title': 'Credits & Lizenzen',
      'credits.body': '''SpiritWorld City
Idee und Entwicklung: Matthias Lindner

Grafik und Töne
• Kenney (kenney.nl): Roguelike Modern City, Roguelike Indoors, Roguelike RPG Pack, RPG Urban Pack, Interface Sounds, UI Audio, Impact Sounds, RPG Audio – CC0 1.0 (gemeinfrei). Danke, Kenney!
• Pixabay: „Reverbed Worship Tambourine“ von yaboi_dandg, „Sacral Chant“ von samuelfjohanns – Pixabay-Inhaltslizenz.

Bibeltexte
• Lutherbibel 1912 – gemeinfrei
• King James Version – gemeinfrei

Technik
• Flutter und Flame sowie die Pakete in „Lizenzen der Bibliotheken“.''',
      'credits.licenses': 'Lizenzen der Bibliotheken',
      'settings.sound': 'Töne',
      'settings.language': 'Sprache',
      'settings.info': 'Info',
    },
    'en': {
      'imprint.title': 'Imprint',
      'imprint.body': '''Information according to § 5 DDG (German law)

⟨Full name / organisation⟩
⟨Street and number⟩
⟨Postcode City⟩
⟨Country⟩

Contact
Email: ⟨email address⟩

⚠️ The publisher must fill in these details before a store release.''',
      'privacy.title': 'Privacy',
      'privacy.body': '''In short: SpiritWorld City collects no personal data.

• Saves and settings (language, sound, difficulty) are stored only on your device. They never leave it.
• No account, no sign-in, no ads, no in-app purchases, no analytics or tracking.
• The app itself makes no internet connections (for the web version see below).
• Web version: it is served by GitHub Pages. When the page loads, GitHub processes technically necessary data (e.g. IP address) under its own privacy policy. The web version also loads its graphics engine and fonts (for emoji) from Google servers (www.gstatic.com, fonts.gstatic.com), which transfers your IP address to Google. We do not receive this data. The Android/iOS app loads nothing from the internet.
• Deleting: uninstall the app or delete saves in "Load Game"; on the web, clear the site data in your browser.

Controller: see imprint. You have the right to access, rectification, erasure and to complain to a supervisory authority; since we store no data about you, we hold none.''',
      'terms.title': 'Terms of use',
      'terms.body': '''• SpiritWorld City is a free game, provided as is; to the extent permitted by law there is no liability for data loss (e.g. lost saves).
• The game presents spiritual topics in a simplified, playful way. It does not replace pastoral care, counselling or therapy. If you are not doing well, talk to people you trust.
• Bible quotes: King James Version (English) and Luther Bible 1912 (German), both in the public domain.
• Graphics and sounds: see credits.''',
      'parents.title': 'For parents',
      'parents.body': '''Dear parents,

SpiritWorld City is a game about a pastor who helps people in a city and prays for them. It also shows an "invisible world" with demons that are overcome by prayer – without blood or depictions of violence.

• No data about your child is collected; everything stays on the device.
• No ads, no purchases, no chat with strangers.
• The characters' life stories can hint at difficult topics (e.g. parents separating, addiction, grief), only as symbols and always aimed at healing.

Questions? See the imprint for contact details.''',
      'consent.title': 'Welcome!',
      'consent.body': '''Great to have you here! 😊

Your saves stay on your device only. We collect no data, show no ads and there is nothing to buy.

Parents find everything under Settings → For parents, Privacy and Imprint.''',
      'consent.accept': 'Let\'s go',
      'consent.leave': 'Leave',
      'credits.title': 'Credits & licences',
      'credits.body': '''SpiritWorld City
Idea and development: Matthias Lindner

Graphics and sounds
• Kenney (kenney.nl): Roguelike Modern City, Roguelike Indoors, Roguelike RPG Pack, RPG Urban Pack, Interface Sounds, UI Audio, Impact Sounds, RPG Audio – CC0 1.0 (public domain). Thank you, Kenney!
• Pixabay: "Reverbed Worship Tambourine" by yaboi_dandg, "Sacral Chant" by samuelfjohanns – Pixabay Content License.

Bible texts
• King James Version – public domain
• Luther Bible 1912 – public domain

Technology
• Flutter and Flame and the packages listed under "Library licences".''',
      'credits.licenses': 'Library licences',
      'settings.sound': 'Sound',
      'settings.language': 'Language',
      'settings.info': 'Info',
    },
  };
}
