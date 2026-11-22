import '../../../core/i18n/app_strings.dart';

/// Legal and info texts (#93, #150, #151, #153) in all game languages.
///
/// They describe only what the app really does: saves stay on the device,
/// no account, no analytics, no ads, no in-app purchases, no network
/// requests by the game itself.
///
/// The imprint names the person responsible, c/o the Salvation Army corps
/// Chemnitz, which is responsible for the game (2026-11-22).
abstract final class LegalTexts {
  /// Bump when the privacy notice changes materially: the first-start
  /// notice (#153) is then shown again.
  static const int consentVersion = 1;

  static String get(String key) =>
      _texts[AppStrings.currentLanguage]?[key] ?? _texts['en']![key] ?? _texts['de']![key] ?? key;

  static const Map<String, Map<String, String>> _texts = {
    'de': {
      'imprint.title': 'Impressum',
      'imprint.body': '''Angaben gemäß § 5 DDG

Matthias Lindner
c/o Die Heilsarmee in Chemnitz
Horst-Menzel-Str. 5
09112 Chemnitz
Deutschland

Kontakt
E-Mail: matthias.lindner@heilsarmee.de

Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV:
Matthias Lindner, Anschrift wie oben''',
      'privacy.title': 'Datenschutz',
      'privacy.body': '''Kurz gesagt: Spiritual City sammelt keine persönlichen Daten.

• Spielstände und Einstellungen (Sprache, Ton, Schwierigkeit) werden nur auf deinem Gerät gespeichert. Sie verlassen das Gerät nicht.
• Es gibt kein Benutzerkonto, keine Anmeldung, keine Werbung, keine In-App-Käufe und keine Analyse- oder Tracking-Dienste.
• Die App selbst stellt keine Verbindungen ins Internet her (zur Web-Version siehe unten).
• Web-Version: Sie wird unter spiritual-city.org von hosting.de ausgeliefert (dazu als Kopie über GitHub Pages). Beim Laden der Seite verarbeitet der Anbieter technisch notwendige Daten (z. B. die IP-Adresse in Server-Protokollen). Der Spenden-Knopf öffnet die Spendenseite der Heilsarmee; dort gilt deren Datenschutzerklärung. Außerdem lädt die Web-Version die Grafik-Engine und Schriften (für Emojis) von Servern von Google (www.gstatic.com, fonts.gstatic.com); dabei wird deine IP-Adresse an Google übertragen. Wir erhalten diese Daten nicht. Die Android-/iOS-App lädt nichts nach.
• Löschen: Deinstalliere die App oder lösche die Spielstände im Menü „Spiel laden“; in der Web-Version die Website-Daten im Browser.

Verantwortlicher: siehe Impressum. Du hast das Recht auf Auskunft, Berichtigung, Löschung und Beschwerde bei einer Aufsichtsbehörde; da wir keine Daten von dir speichern, liegen bei uns keine vor.''',
      'terms.title': 'Nutzungsbedingungen',
      'terms.body': '''• Spiritual City ist ein kostenloses Spiel. Es wird ohne Gewähr bereitgestellt; für Datenverlust (z. B. verlorene Spielstände) wird nicht gehaftet, soweit gesetzlich zulässig.
• Das Spiel stellt geistliche Themen vereinfacht und spielerisch dar. Es ersetzt keine Seelsorge, Beratung oder Therapie. Wenn es dir nicht gut geht, sprich mit Menschen, denen du vertraust.
• Bibelzitate: Lutherbibel 1912 (deutsch), King James Version (englisch), Reina-Valera 1909 (spanisch), Louis Segond 1910 (französisch) und Almeida Revista e Corrigida (portugiesisch), alle gemeinfrei.
• Grafiken und Töne: siehe Credits.''',
      'parents.title': 'Hinweis für Eltern',
      'parents.body': '''Liebe Eltern,

Spiritual City ist ein Spiel über einen Pastor, der in einer Stadt Menschen hilft und für sie betet. Es zeigt dabei auch eine „unsichtbare Welt“ mit Dämonen, die durch Gebet besiegt werden – ohne Blut und ohne Gewaltdarstellung.

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
      'credits.body': '''Spiritual City
Idee und Entwicklung: Matthias Lindner

Grafik und Töne
• Kenney (kenney.nl): Roguelike Modern City, Roguelike Indoors, Roguelike RPG Pack, RPG Urban Pack, Interface Sounds, UI Audio, Impact Sounds, RPG Audio – CC0 1.0 (gemeinfrei). Danke, Kenney!
• Pixabay: „Reverbed Worship Tambourine“ von yaboi_dandg, „Sacral Chant“ von samuelfjohanns, „Bass Drop“ von youssefmizani, „High Battery Charge“ von snorcon – Pixabay-Inhaltslizenz.

Bibeltexte (gemeinfrei)
• Lutherbibel 1912 · King James Version · Reina-Valera 1909 · Louis Segond 1910 · Almeida Revista e Corrigida

Technik
• Flutter und Flame sowie die Pakete in „Lizenzen der Bibliotheken“.''',
      'credits.licenses': 'Lizenzen der Bibliotheken',
      'settings.sound': 'Töne',
      'settings.music': 'Musik',
      'settings.language': 'Sprache',
      'settings.texts': 'Erzähler',
      'settings.texts.hint': 'Eine Sprechblase erklärt, was du siehst und tust – aus: nur Emojis',
      'settings.info': 'Info',
    },
    'en': {
      'imprint.title': 'Imprint',
      'imprint.body': '''Information according to § 5 DDG (German law)

Matthias Lindner
c/o Die Heilsarmee in Chemnitz
Horst-Menzel-Str. 5
09112 Chemnitz
Germany

Contact
Email: matthias.lindner@heilsarmee.de''',
      'privacy.title': 'Privacy',
      'privacy.body': '''In short: Spiritual City collects no personal data.

• Saves and settings (language, sound, difficulty) are stored only on your device. They never leave it.
• No account, no sign-in, no ads, no in-app purchases, no analytics or tracking.
• The app itself makes no internet connections (for the web version see below).
• Web version: it is served at spiritual-city.org by hosting.de (with a copy on GitHub Pages). When the page loads, the provider processes technically necessary data (e.g. your IP address in server logs). The donate button opens The Salvation Army's donation page, where its own privacy policy applies. The web version also loads its graphics engine and fonts (for emoji) from Google servers (www.gstatic.com, fonts.gstatic.com), which transfers your IP address to Google. We do not receive this data. The Android/iOS app loads nothing from the internet.
• Deleting: uninstall the app or delete saves in "Load Game"; on the web, clear the site data in your browser.

Controller: see imprint. You have the right to access, rectification, erasure and to complain to a supervisory authority; since we store no data about you, we hold none.''',
      'terms.title': 'Terms of use',
      'terms.body': '''• Spiritual City is a free game, provided as is; to the extent permitted by law there is no liability for data loss (e.g. lost saves).
• The game presents spiritual topics in a simplified, playful way. It does not replace pastoral care, counselling or therapy. If you are not doing well, talk to people you trust.
• Bible quotes: King James Version (English), Luther Bible 1912 (German), Reina-Valera 1909 (Spanish), Louis Segond 1910 (French) and Almeida Revista e Corrigida (Portuguese), all in the public domain.
• Graphics and sounds: see credits.''',
      'parents.title': 'For parents',
      'parents.body': '''Dear parents,

Spiritual City is a game about a pastor who helps people in a city and prays for them. It also shows an "invisible world" with demons that are overcome by prayer – without blood or depictions of violence.

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
      'credits.body': '''Spiritual City
Idea and development: Matthias Lindner

Graphics and sounds
• Kenney (kenney.nl): Roguelike Modern City, Roguelike Indoors, Roguelike RPG Pack, RPG Urban Pack, Interface Sounds, UI Audio, Impact Sounds, RPG Audio – CC0 1.0 (public domain). Thank you, Kenney!
• Pixabay: "Reverbed Worship Tambourine" by yaboi_dandg, "Sacral Chant" by samuelfjohanns, "Bass Drop" by youssefmizani, "High Battery Charge" by snorcon – Pixabay Content License.

Bible texts (public domain)
• King James Version · Luther Bible 1912 · Reina-Valera 1909 · Louis Segond 1910 · Almeida Revista e Corrigida

Technology
• Flutter and Flame and the packages listed under "Library licences".''',
      'credits.licenses': 'Library licences',
      'settings.sound': 'Sound',
      'settings.music': 'Music',
      'settings.language': 'Language',
      'settings.texts': 'Narrator',
      'settings.texts.hint': 'A speech bubble explains what you see and do – off: emoji only',
      'settings.info': 'Info',
    },
    'es': {
      'imprint.title': 'Aviso legal',
      'imprint.body': '''Información según el § 5 DDG (ley alemana)

Matthias Lindner
c/o Die Heilsarmee in Chemnitz
Horst-Menzel-Str. 5
09112 Chemnitz
Alemania

Contacto
Correo: matthias.lindner@heilsarmee.de''',
      'privacy.title': 'Privacidad',
      'privacy.body': '''En resumen: Spiritual City no recoge datos personales.

• Las partidas y los ajustes (idioma, sonido, dificultad) se guardan solo en tu dispositivo. Nunca salen de él.
• Sin cuenta, sin inicio de sesión, sin anuncios, sin compras dentro de la app, sin analítica ni seguimiento.
• La app no se conecta a internet (para la versión web, ver abajo).
• Versión web: la sirve hosting.de en spiritual-city.org (con una copia en GitHub Pages). Al cargar la página, el proveedor procesa datos técnicamente necesarios (p. ej. tu dirección IP en los registros del servidor). El botón de donar abre la página de donativos del Ejército de Salvación, donde rige su propia política de privacidad. La versión web también carga su motor gráfico y fuentes (para los emojis) desde servidores de Google (www.gstatic.com, fonts.gstatic.com), lo que transmite tu dirección IP a Google. Nosotros no recibimos esos datos. La app de Android/iOS no carga nada de internet.
• Borrar: desinstala la app o borra las partidas en «Cargar partida»; en la web, borra los datos del sitio en tu navegador.

Responsable: ver el aviso legal. Tienes derecho de acceso, rectificación, supresión y a reclamar ante una autoridad de control; como no guardamos datos sobre ti, no tenemos ninguno.''',
      'terms.title': 'Condiciones de uso',
      'terms.body': '''• Spiritual City es un juego gratuito, ofrecido tal cual; en la medida que permita la ley, no hay responsabilidad por pérdida de datos (p. ej. partidas perdidas).
• El juego presenta temas espirituales de forma simplificada y lúdica. No sustituye el acompañamiento pastoral, el asesoramiento ni la terapia. Si no estás bien, habla con personas de confianza.
• Citas bíblicas: Reina-Valera 1909, Louis Segond 1910, Almeida Revista e Corrigida, King James Version y Biblia de Lutero 1912, todas de dominio público.
• Gráficos y sonidos: ver créditos.''',
      'parents.title': 'Para padres',
      'parents.body': '''Queridos padres:

Spiritual City es un juego sobre un pastor que ayuda a las personas de una ciudad y ora por ellas. También muestra un «mundo invisible» con demonios que se vencen con la oración, sin sangre ni escenas de violencia.

• No se recoge ningún dato de su hijo; todo queda en el dispositivo.
• Sin anuncios, sin compras, sin chat con desconocidos.
• Las historias de vida de los personajes pueden aludir a temas difíciles (p. ej. separación de los padres, adicciones, duelo), solo con símbolos y siempre orientadas a la sanidad.

¿Preguntas? Encontrará el contacto en el aviso legal.''',
      'consent.title': '¡Bienvenido!',
      'consent.body': '''¡Qué bien que estés aquí! 😊

Tus partidas se quedan solo en tu dispositivo. No recogemos datos, no mostramos anuncios y no hay nada que comprar.

Los padres encuentran todo en Ajustes → Para padres, Privacidad y Aviso legal.''',
      'consent.accept': '¡Vamos!',
      'consent.leave': 'Salir',
      'credits.title': 'Créditos y licencias',
      'credits.body': '''Spiritual City
Idea y desarrollo: Matthias Lindner

Gráficos y sonidos
• Kenney (kenney.nl): Roguelike Modern City, Roguelike Indoors, Roguelike RPG Pack, RPG Urban Pack, Interface Sounds, UI Audio, Impact Sounds, RPG Audio – CC0 1.0 (dominio público). ¡Gracias, Kenney!
• Pixabay: «Reverbed Worship Tambourine» de yaboi_dandg, «Sacral Chant» de samuelfjohanns, «Bass Drop» de youssefmizani, «High Battery Charge» de snorcon – Pixabay Content License.

Textos bíblicos (dominio público)
• Reina-Valera 1909 · Louis Segond 1910 · Almeida Revista e Corrigida · King James Version · Biblia de Lutero 1912

Tecnología
• Flutter y Flame y los paquetes indicados en «Licencias de bibliotecas».''',
      'credits.licenses': 'Licencias de bibliotecas',
      'settings.sound': 'Sonido',
      'settings.music': 'Música',
      'settings.language': 'Idioma',
      'settings.texts': 'Narrador',
      'settings.texts.hint': 'Un bocadillo explica lo que ves y haces – desactivado: solo emojis',
      'settings.info': 'Información',
    },
    'fr': {
      'imprint.title': 'Mentions légales',
      'imprint.body': '''Informations selon le § 5 DDG (droit allemand)

Matthias Lindner
c/o Die Heilsarmee in Chemnitz
Horst-Menzel-Str. 5
09112 Chemnitz
Allemagne

Contact
E-mail : matthias.lindner@heilsarmee.de''',
      'privacy.title': 'Confidentialité',
      'privacy.body': '''En bref : Spiritual City ne collecte aucune donnée personnelle.

• Les sauvegardes et les paramètres (langue, son, difficulté) sont enregistrés uniquement sur ton appareil. Ils ne le quittent jamais.
• Pas de compte, pas de connexion, pas de publicité, pas d’achats intégrés, pas d’analyse ni de suivi.
• L’application elle-même n’établit aucune connexion Internet (pour la version web, voir ci-dessous).
• Version web : elle est hébergée par hosting.de sur spiritual-city.org (avec une copie sur GitHub Pages). Au chargement de la page, l’hébergeur traite des données techniquement nécessaires (p. ex. ton adresse IP dans les journaux du serveur). Le bouton de don ouvre la page de dons de l’Armée du Salut, où s’applique sa propre politique de confidentialité. La version web charge aussi son moteur graphique et des polices (pour les emojis) depuis des serveurs de Google (www.gstatic.com, fonts.gstatic.com), ce qui transmet ton adresse IP à Google. Nous ne recevons pas ces données. L’application Android/iOS ne charge rien depuis Internet.
• Suppression : désinstalle l’application ou supprime les sauvegardes dans « Charger une partie » ; sur le web, efface les données du site dans ton navigateur.

Responsable : voir les mentions légales. Tu as un droit d’accès, de rectification, d’effacement et de réclamation auprès d’une autorité de contrôle ; comme nous ne conservons aucune donnée sur toi, nous n’en détenons aucune.''',
      'terms.title': 'Conditions d’utilisation',
      'terms.body': '''• Spiritual City est un jeu gratuit, fourni tel quel ; dans la mesure permise par la loi, aucune responsabilité n’est assumée pour la perte de données (p. ex. sauvegardes perdues).
• Le jeu présente des thèmes spirituels de manière simplifiée et ludique. Il ne remplace ni l’accompagnement pastoral, ni le conseil, ni la thérapie. Si tu ne vas pas bien, parle à des personnes de confiance.
• Citations bibliques : Louis Segond 1910, Reina-Valera 1909, Almeida Revista e Corrigida, King James Version et Bible de Luther 1912, toutes dans le domaine public.
• Graphismes et sons : voir les crédits.''',
      'parents.title': 'Pour les parents',
      'parents.body': '''Chers parents,

Spiritual City est un jeu sur un pasteur qui aide les habitants d’une ville et prie pour eux. Il montre aussi un « monde invisible » avec des démons vaincus par la prière – sans sang ni scènes de violence.

• Aucune donnée sur votre enfant n’est collectée ; tout reste sur l’appareil.
• Pas de publicité, pas d’achats, pas de discussion avec des inconnus.
• Les histoires de vie des personnages peuvent évoquer des sujets difficiles (p. ex. séparation des parents, addiction, deuil), uniquement sous forme de symboles et toujours dans une perspective de guérison.

Des questions ? Les coordonnées se trouvent dans les mentions légales.''',
      'consent.title': 'Bienvenue !',
      'consent.body': '''Super que tu sois là ! 😊

Tes sauvegardes restent uniquement sur ton appareil. Nous ne collectons aucune donnée, n’affichons aucune publicité et il n’y a rien à acheter.

Les parents trouvent tout sous Paramètres → Pour les parents, Confidentialité et Mentions légales.''',
      'consent.accept': 'C’est parti',
      'consent.leave': 'Quitter',
      'credits.title': 'Crédits et licences',
      'credits.body': '''Spiritual City
Idée et développement : Matthias Lindner

Graphismes et sons
• Kenney (kenney.nl) : Roguelike Modern City, Roguelike Indoors, Roguelike RPG Pack, RPG Urban Pack, Interface Sounds, UI Audio, Impact Sounds, RPG Audio – CC0 1.0 (domaine public). Merci, Kenney !
• Pixabay : « Reverbed Worship Tambourine » par yaboi_dandg, « Sacral Chant » par samuelfjohanns, « Bass Drop » par youssefmizani, « High Battery Charge » par snorcon – Pixabay Content License.

Textes bibliques (domaine public)
• Louis Segond 1910 · Reina-Valera 1909 · Almeida Revista e Corrigida · King James Version · Bible de Luther 1912

Technique
• Flutter et Flame ainsi que les paquets listés sous « Licences des bibliothèques ».''',
      'credits.licenses': 'Licences des bibliothèques',
      'settings.sound': 'Son',
      'settings.music': 'Musique',
      'settings.language': 'Langue',
      'settings.texts': 'Narrateur',
      'settings.texts.hint': 'Une bulle explique ce que tu vois et fais – désactivé : emojis seulement',
      'settings.info': 'Infos',
    },
    'pt': {
      'imprint.title': 'Informações legais',
      'imprint.body': '''Informações conforme o § 5 DDG (lei alemã)

Matthias Lindner
c/o Die Heilsarmee in Chemnitz
Horst-Menzel-Str. 5
09112 Chemnitz
Alemanha

Contato
E-mail: matthias.lindner@heilsarmee.de''',
      'privacy.title': 'Privacidade',
      'privacy.body': '''Resumindo: Spiritual City não coleta dados pessoais.

• Jogos salvos e configurações (idioma, som, dificuldade) ficam apenas no seu aparelho. Nunca saem dele.
• Sem conta, sem login, sem anúncios, sem compras no app, sem análise ou rastreamento.
• O app em si não faz conexões com a internet (para a versão web, veja abaixo).
• Versão web: é hospedada pela hosting.de em spiritual-city.org (com uma cópia no GitHub Pages). Ao carregar a página, o provedor processa dados tecnicamente necessários (p. ex. seu endereço IP nos registros do servidor). O botão de doação abre a página de doações do Exército de Salvação, onde vale a política de privacidade dela. A versão web também carrega seu motor gráfico e fontes (para os emojis) de servidores do Google (www.gstatic.com, fonts.gstatic.com), o que transmite seu endereço IP ao Google. Nós não recebemos esses dados. O app Android/iOS não carrega nada da internet.
• Apagar: desinstale o app ou apague os jogos salvos em "Carregar jogo"; na web, limpe os dados do site no navegador.

Responsável: veja as informações legais. Você tem direito de acesso, retificação, exclusão e de reclamar a uma autoridade de controle; como não guardamos dados sobre você, não temos nenhum.''',
      'terms.title': 'Termos de uso',
      'terms.body': '''• Spiritual City é um jogo gratuito, oferecido como está; na medida permitida por lei, não há responsabilidade por perda de dados (p. ex. jogos salvos perdidos).
• O jogo apresenta temas espirituais de forma simplificada e lúdica. Não substitui o cuidado pastoral, o aconselhamento ou a terapia. Se você não estiver bem, converse com pessoas de confiança.
• Citações bíblicas: Almeida Revista e Corrigida, Reina-Valera 1909, Louis Segond 1910, King James Version e Bíblia de Lutero 1912, todas em domínio público.
• Gráficos e sons: veja os créditos.''',
      'parents.title': 'Para os pais',
      'parents.body': '''Queridos pais,

Spiritual City é um jogo sobre um pastor que ajuda as pessoas de uma cidade e ora por elas. Ele também mostra um "mundo invisível" com demônios vencidos pela oração – sem sangue nem cenas de violência.

• Nenhum dado sobre seu filho é coletado; tudo fica no aparelho.
• Sem anúncios, sem compras, sem chat com estranhos.
• As histórias de vida dos personagens podem mencionar temas difíceis (p. ex. separação dos pais, vícios, luto), apenas com símbolos e sempre visando a cura.

Dúvidas? O contato está nas informações legais.''',
      'consent.title': 'Bem-vindo!',
      'consent.body': '''Que bom que você está aqui! 😊

Seus jogos salvos ficam só no seu aparelho. Não coletamos dados, não mostramos anúncios e não há nada para comprar.

Os pais encontram tudo em Configurações → Para os pais, Privacidade e Informações legais.''',
      'consent.accept': 'Vamos lá',
      'consent.leave': 'Sair',
      'credits.title': 'Créditos e licenças',
      'credits.body': '''Spiritual City
Ideia e desenvolvimento: Matthias Lindner

Gráficos e sons
• Kenney (kenney.nl): Roguelike Modern City, Roguelike Indoors, Roguelike RPG Pack, RPG Urban Pack, Interface Sounds, UI Audio, Impact Sounds, RPG Audio – CC0 1.0 (domínio público). Obrigado, Kenney!
• Pixabay: "Reverbed Worship Tambourine" de yaboi_dandg, "Sacral Chant" de samuelfjohanns, "Bass Drop" de youssefmizani, "High Battery Charge" de snorcon – Pixabay Content License.

Textos bíblicos (domínio público)
• Almeida Revista e Corrigida · Reina-Valera 1909 · Louis Segond 1910 · King James Version · Bíblia de Lutero 1912

Tecnologia
• Flutter e Flame e os pacotes listados em "Licenças das bibliotecas".''',
      'credits.licenses': 'Licenças das bibliotecas',
      'settings.sound': 'Som',
      'settings.music': 'Música',
      'settings.language': 'Idioma',
      'settings.texts': 'Narrador',
      'settings.texts.hint': 'Um balão explica o que você vê e faz – desligado: só emojis',
      'settings.info': 'Informações',
    },
  };
}
