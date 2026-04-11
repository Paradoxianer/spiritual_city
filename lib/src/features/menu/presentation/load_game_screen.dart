import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../domain/menu_service.dart';

/// Screen that lists saved games loaded from Hive.
class LoadGameScreen extends StatefulWidget {
  final MenuService menuService;

  const LoadGameScreen({super.key, required this.menuService});

  @override
  State<LoadGameScreen> createState() => _LoadGameScreenState();
}

class _LoadGameScreenState extends State<LoadGameScreen> {
  late Future<List<GameSave>> _savesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _savesFuture = widget.menuService.loadSaves();
    });
  }

  Future<void> _delete(String id) async {
    await widget.menuService.deleteSave(id);
    _reload();
  }

  void _load(GameSave save) {
    context.go('/game', extra: save.difficulty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              AppStrings.get('loadGame.title'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 22,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<GameSave>>(
                future: _savesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final saves = snapshot.data ?? [];
                  if (saves.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.get('loadGame.empty'),
                        style: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: saves.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _SaveTile(
                      save: saves[i],
                      onLoad: () => _load(saves[i]),
                      onDelete: () => _delete(saves[i].id),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: () => context.go('/menu'),
                icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                label: Text(
                  AppStrings.get('loadGame.back'),
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveTile extends StatelessWidget {
  final GameSave save;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _SaveTile({
    required this.save,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final diffLabel = switch (save.difficulty) {
      Difficulty.easy => AppStrings.get('difficulty.easy'),
      Difficulty.normal => AppStrings.get('difficulty.normal'),
      Difficulty.hard => AppStrings.get('difficulty.hard'),
    };
    final d = save.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade700),
      ),
      child: ListTile(
        leading: const Icon(Icons.save, color: Colors.blueGrey),
        title: Text(
          save.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '$diffLabel · $dateStr',
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.greenAccent),
              tooltip: AppStrings.get('loadGame.load'),
              onPressed: onLoad,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: AppStrings.get('loadGame.delete'),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
