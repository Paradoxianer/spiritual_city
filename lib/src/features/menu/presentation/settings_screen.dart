import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/game_sound.dart';
import '../domain/legal_texts.dart';
import '../domain/menu_service.dart';
import 'widgets/language_toggle.dart';

/// Settings (#150–#153): sound, language and the info pages – imprint,
/// privacy, terms, parents' note and credits.
class SettingsScreen extends StatefulWidget {
  final MenuService menuService;
  const SettingsScreen({super.key, required this.menuService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.menuService.languageNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          leading: BackButton(onPressed: () => context.go('/menu')),
          title: const Text('⚙️'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    secondary: Text(GameSound.enabled ? '🔊' : '🔇', style: const TextStyle(fontSize: 24)),
                    title: Text(LegalTexts.get('settings.sound')),
                    value: GameSound.enabled,
                    onChanged: (on) async {
                      await widget.menuService.setSoundOn(on);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Text('🌐', style: TextStyle(fontSize: 24)),
                    title: Text(LegalTexts.get('settings.language')),
                    trailing: LanguageToggle(
                      languageNotifier: widget.menuService.languageNotifier,
                      onChanged: widget.menuService.setLanguage,
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      LegalTexts.get('settings.info'),
                      style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12),
                    ),
                  ),
                  for (final (emoji, page) in const [
                    ('👪', 'parents'),
                    ('🔒', 'privacy'),
                    ('📄', 'terms'),
                    ('🏷️', 'imprint'),
                    ('🙏', 'credits'),
                  ])
                    ListTile(
                      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
                      title: Text(LegalTexts.get('$page.title')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/info/$page'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One info page (imprint, privacy, terms, parents, credits).
class InfoScreen extends StatelessWidget {
  final String page;
  const InfoScreen({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        leading: BackButton(onPressed: () => context.go('/settings')),
        title: Text(LegalTexts.get('$page.title')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SelectableText(
                  LegalTexts.get('$page.body'),
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                ),
                if (page == 'credits') ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: 'SpiritWorld City',
                      applicationIcon: const Text('✝️', style: TextStyle(fontSize: 40)),
                    ),
                    child: Text(LegalTexts.get('credits.licenses')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
