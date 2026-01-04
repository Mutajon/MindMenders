import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
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
  bool _isBrushActive = false;
  String _currentBrushType = 'Dendrite';

  @override
  void initState() {
    super.initState();
    _game = LevelEditorGame(level: widget.level);
  }

  Future<void> _saveLevel({bool exit = false}) async {
    final updatedLevel = _game.getUpdatedLevel();
    await _repository.saveLevel(updatedLevel);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Level saved successfully!')),
      );
      if (exit) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editing: ${widget.level.name}'),
        actions: [
          IconButton(
            onPressed: () => _saveLevel(),
            icon: const Icon(Icons.save),
            tooltip: 'Save Level',
          ),
        ],
      ),
      body: Stack(
        children: [
          // The Game
          MouseRegion(
            onHover: (details) {
              _game.handleMouseMove(
                Vector2(details.localPosition.dx, details.localPosition.dy),
              );
            },
            child: GestureDetector(
              onTapDown: (details) {
                _game.handleTapAt(
                  Vector2(details.localPosition.dx, details.localPosition.dy),
                );
              },
              child: GameWidget(game: _game),
            ),
          ),

          // Toolbar (Top Center)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                elevation: 4,
                color: Colors.black.withValues(alpha: 0.7),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brush Toggle Button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isBrushActive = !_isBrushActive;
                            _game.isBrushActive = _isBrushActive;
                          });
                        },
                        icon: Icon(
                          Icons.brush,
                          color: _isBrushActive ? Colors.blue : Colors.white,
                        ),
                        tooltip: 'Tile Brush',
                      ),
                      const SizedBox(width: 8),

                      // Tile Type Dropdown
                      DropdownButton<String>(
                        value: _currentBrushType,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        items: ['Dendrite', 'Neuron', 'Memory', 'Brain Damage']
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _currentBrushType = value;
                              _game.currentBrushType = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Save and Exit Button (Bottom Center)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _saveLevel(exit: true),
                icon: const Icon(Icons.check_circle),
                label: const Text('Save and Exit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
