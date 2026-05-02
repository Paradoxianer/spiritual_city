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

  Future<void> _rename(GameSave save) async {
    final String? newName = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameDialog(initialName: save.name),
    );
    if (newName != null && newName.isNotEmpty) {
      await widget.menuService.renameSave(save.id, newName);
      _reload();
    }
  }

  void _load(GameSave save) {
    context.go('/game', extra: save);
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
                      onRename: () => _rename(saves[i]),
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

/// Dialog that lets the player rename a save slot.
///
/// The [TextEditingController] is created and disposed as part of the
/// [State] lifecycle, which avoids the "used after disposed" crash that
/// occurred when the controller was disposed in a `finally` block while
/// Flutter's dialog exit-animation was still running (Issue #135).
class _RenameDialog extends StatefulWidget {
  final String initialName;

  const _RenameDialog({required this.initialName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2E3F),
      title: Text(
        AppStrings.get('loadGame.rename.title'),
        style: const TextStyle(color: Colors.white70),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: AppStrings.get('loadGame.rename.hint'),
          hintStyle: TextStyle(color: Colors.blueGrey.shade400),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blueGrey.shade600),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlueAccent),
          ),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppStrings.get('loadGame.rename.cancel'),
            style: const TextStyle(color: Colors.blueGrey),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(
            AppStrings.get('loadGame.rename.confirm'),
            style: const TextStyle(color: Colors.lightBlueAccent),
          ),
        ),
      ],
    );
  }
}

class _SaveTile extends StatelessWidget {
  final GameSave save;
  final VoidCallback onLoad;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _SaveTile({
    required this.save,
    required this.onLoad,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final diffLabel = switch (save.difficulty) {
      Difficulty.easy => AppStrings.get('difficulty.easy'),
      Difficulty.normal => AppStrings.get('difficulty.normal'),
      Difficulty.hard => AppStrings.get('difficulty.hard'),
    };
    final d = save.lastPlayed;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final hasState = save.gameState.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade700),
      ),
      child: ListTile(
        onTap: onLoad,
        leading: Icon(
          hasState ? Icons.save : Icons.save_outlined,
          color: hasState ? Colors.lightBlueAccent : Colors.blueGrey,
        ),
        title: Text(
          save.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '$diffLabel · ${AppStrings.get('loadGame.lastPlayed')}: $dateStr',
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.lightBlueAccent),
              tooltip: AppStrings.get('loadGame.rename'),
              onPressed: onRename,
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
