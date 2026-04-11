import 'package:flutter/material.dart';
import '../../../../core/i18n/app_language.dart';

/// A DE / EN language toggle with flag-style buttons.
class LanguageToggle extends StatelessWidget {
  final LanguageNotifier languageNotifier;
  final void Function(String lang)? onChanged;

  const LanguageToggle({
    super.key,
    required this.languageNotifier,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (_, lang, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangButton(
              flag: '🇩🇪',
              code: 'de',
              selected: lang == 'de',
              onTap: () {
                languageNotifier.setLanguage('de');
                onChanged?.call('de');
              },
            ),
            const SizedBox(width: 8),
            _LangButton(
              flag: '🇬🇧',
              code: 'EN',
              selected: lang == 'en',
              onTap: () {
                languageNotifier.setLanguage('en');
                onChanged?.call('en');
              },
            ),
          ],
        );
      },
    );
  }
}

class _LangButton extends StatelessWidget {
  final String flag;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({
    required this.flag,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueGrey.shade700
              : Colors.blueGrey.shade900.withAlpha(180),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
          ),
        ),
        child: Text(
          '$flag $code',
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.white : Colors.blueGrey.shade400,
          ),
        ),
      ),
    );
  }
}
