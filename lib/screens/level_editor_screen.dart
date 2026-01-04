import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../models/level_model.dart';
import '../data/level_repository.dart';
import '../editor/level_editor_game.dart';

class LevelEditorScreen extends StatefulWidget {
  final LevelModel level;

  const LevelEditorScreen({super.key, required this.level});

  @override
  State<LevelEditorScreen> createState() => _LevelEditorScreenState();
}

class _LevelEditorScreenState extends State<LevelEditorScreen> {
  late LevelEditorGame _game;
  final LevelRepository _repository = LevelRepository();

  @override
  void initState() {
    super.initState();
    _game = LevelEditorGame(level: widget.level);
  }

  Future<void> _saveLevel() async {
    final updatedLevel = _game.getUpdatedLevel();
    await _repository.saveLevel(updatedLevel);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Level saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editing: ${widget.level.name}'),
        actions: [
          IconButton(
            onPressed: _saveLevel,
            icon: const Icon(Icons.save),
            tooltip: 'Save Level',
          ),
        ],
      ),
      body: GameWidget(game: _game),
    );
  }
}
