import 'package:flutter/material.dart';
import '../../../../core/i18n/app_language.dart';

/// Language choice: one flag per supported language ([AppLanguages]).
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
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final l in AppLanguages.all)
              Tooltip(
                message: l.name,
                child: _LangButton(
                  flag: l.flag,
                  selected: lang == l.code,
                  onTap: () {
                    languageNotifier.setLanguage(l.code);
                    onChanged?.call(l.code);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LangButton extends StatelessWidget {
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton({
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueGrey.shade700
              : Colors.blueGrey.shade900.withAlpha(180),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
          ),
        ),
        child: Opacity(
          opacity: selected ? 1.0 : 0.6,
          child: Text(flag, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
