part of '../game_screen.dart';

/// The explanation box at the bottom (playtest 2026-10-31): what the
/// chosen action will do, before it happens – ▶ do it, 🔕 do it and don't
/// explain this action again, ✕ cancel.
class _ExplanationBox extends StatelessWidget {
  final PendingExplanation e;
  const _ExplanationBox({required this.e});

  @override
  Widget build(BuildContext context) {
    const labels = HelpContent.labels;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              color: const Color(0xF2122236),
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(e.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.title,
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: labels['cancel']!.text,
                          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                          onPressed: Explanations.cancel,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        e.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => Explanations.confirm(mute: true),
                          child: Text('🔕 ${labels['muteAndDo']!.text}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: Explanations.confirm,
                          child: Text('▶ ${labels['doIt']!.text}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
