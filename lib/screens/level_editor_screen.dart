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
  String _currentBrushMode = 'tile';
  String _currentBrushOption = 'Dendrite';

  // Define available options for each brush mode
  final Map<String, List<String>> _brushOptions = {
    'tile': ['Dendrite', 'Neuron', 'Memory', 'Brain Damage'],
    'control': ['Neutral', 'Hive', 'Menders'],
    'enemy': ['Terminator 1.0', 'Sweeper 1.0'],
    'mender': ['Manipulator', 'Crazy Nina'],
  };

  @override
  void initState() {
    super.initState();
    _game = LevelEditorGame(level: widget.level);
  }

  void _onBrushModeChanged(String? mode) {
    if (mode != null) {
      setState(() {
        _currentBrushMode = mode;
        // Set first option of the new mode
        _currentBrushOption = _brushOptions[mode]!.first;
        _game.currentBrushMode = mode;
        _game.currentBrushOption = _currentBrushOption;
      });
    }
  }

  void _onBrushOptionChanged(String? option) {
    if (option != null) {
      setState(() {
        _currentBrushOption = option;
        _game.currentBrushOption = option;
      });
    }
  }

  String _getBrushModeLabel(String mode) {
    switch (mode) {
      case 'tile':
        return 'Tile Type';
      case 'control':
        return 'Control';
      case 'enemy':
        return 'Enemy Unit';
      case 'mender':
        return 'Mender Unit';
      default:
        return mode;
    }
  }

  Color _getBrushModeColor(String mode) {
    switch (mode) {
      case 'tile':
        return Colors.green;
      case 'control':
        return Colors.blue;
      case 'enemy':
        return Colors.red;
      case 'mender':
        return Colors.cyan;
      default:
        return Colors.white;
    }
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
                color: Colors.black.withValues(alpha: 0.8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
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
                              color: _isBrushActive
                                  ? _getBrushModeColor(_currentBrushMode)
                                  : Colors.white,
                              size: 28,
                            ),
                            tooltip:
                                'Toggle Brush (${_isBrushActive ? "ON" : "OFF"})',
                          ),
                          const SizedBox(width: 16),

                          // Brush Mode Selector
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Brush Mode',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _currentBrushMode,
                                dropdownColor: Colors.grey[900],
                                style: TextStyle(
                                  color: _getBrushModeColor(_currentBrushMode),
                                  fontWeight: FontWeight.bold,
                                ),
                                underline: Container(),
                                items: _brushOptions.keys.map((mode) {
                                  return DropdownMenuItem(
                                    value: mode,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getBrushModeIcon(mode),
                                          color: _getBrushModeColor(mode),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_getBrushModeLabel(mode)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onBrushModeChanged,
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),

                          // Brush Option Selector
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Option',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _currentBrushOption,
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                underline: Container(),
                                items: _brushOptions[_currentBrushMode]!.map((
                                  option,
                                ) {
                                  return DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                                onChanged: _onBrushOptionChanged,
                              ),
                            ],
                          ),
                        ],
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

  IconData _getBrushModeIcon(String mode) {
    switch (mode) {
      case 'tile':
        return Icons.grid_on;
      case 'control':
        return Icons.flag;
      case 'enemy':
        return Icons.bug_report;
      case 'mender':
        return Icons.healing;
      default:
        return Icons.brush;
    }
  }
}
