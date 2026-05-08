import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../domain/menu_service.dart';
import 'widgets/language_toggle.dart';
import 'widgets/menu_button.dart';

/// Main Menu Screen — the entry point of the app.
///
/// Accessible via GoRouter route `/menu`.
/// Provides: New Game, Load Game, Settings (placeholder), Quit.
class MenuScreen extends StatefulWidget {
  final MenuService menuService;

  const MenuScreen({super.key, required this.menuService});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    // Rebuild when the language changes so button labels update.
    return ValueListenableBuilder<String>(
      valueListenable: widget.menuService.languageNotifier,
      builder: (context, _, __) => _buildMenu(context),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Stack(
          children: [
            // Background cross symbol (decorative)
            const Center(
              child: Opacity(
                opacity: 0.04,
                child: Icon(
                  Icons.add,
                  size: 500,
                  color: Colors.white,
                ),
              ),
            ),
            // Content
            LayoutBuilder(
              builder: (context, constraints) {
                const contentPadding =
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12);
                final minContentHeight =
                    constraints.maxHeight - contentPadding.vertical;
                return SingleChildScrollView(
                  padding: contentPadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minContentHeight),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildMenuButtons(context),
                          const SizedBox(height: 24),
                          LanguageToggle(
                            languageNotifier:
                                widget.menuService.languageNotifier,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          '✝️',
          style: TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.get('menu.title').toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.get('menu.subtitle'),
          style: TextStyle(
            color: Colors.blueGrey.shade400,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButtons(BuildContext context) {
    return Column(
      children: [
        MenuButton(
          icon: Icons.sports_esports,
          label: AppStrings.get('menu.newGame'),
          onPressed: () => context.go('/difficulty'),
        ),
        MenuButton(
          icon: Icons.folder_open,
          label: AppStrings.get('menu.loadGame'),
          onPressed: () => context.go('/load'),
        ),
        MenuButton(
          icon: Icons.settings,
          label: AppStrings.get('menu.settings'),
          onPressed: () => _showSettingsPlaceholder(context),
          color: Colors.blueGrey.shade500,
        ),
        MenuButton(
          icon: Icons.exit_to_app,
          label: AppStrings.get('menu.quit'),
          onPressed: () => SystemNavigator.pop(),
          color: Colors.redAccent.shade100,
        ),
      ],
    );
  }

  void _showSettingsPlaceholder(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A3A),
        title: Text(
          AppStrings.get('settings.title'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          AppStrings.get('settings.placeholder'),
          style: TextStyle(color: Colors.blueGrey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.get('settings.back'),
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }
}
