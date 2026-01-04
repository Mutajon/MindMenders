import 'package:flutter/material.dart';
import '../data/level_repository.dart';
import '../models/level_model.dart';
import 'create_level_dialog.dart';

class LevelCreatorMenu extends StatefulWidget {
  const LevelCreatorMenu({super.key});

  @override
  State<LevelCreatorMenu> createState() => _LevelCreatorMenuState();
}

class _LevelCreatorMenuState extends State<LevelCreatorMenu> {
  final LevelRepository _repository = LevelRepository();
  List<LevelModel> _levels = [];
  LevelModel? _selectedLevel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() => _isLoading = true);
    final levels = await _repository.getAllLevels();

    setState(() {
      _levels = levels;
      _isLoading = false;

      // Try to keep selection if it still exists
      if (_selectedLevel != null) {
        final exists = levels.any((l) => l.id == _selectedLevel!.id);
        if (!exists) {
          _selectedLevel = levels.isNotEmpty ? levels.first : null;
        } else {
          // Update the selected level reference (in case name changed)
          _selectedLevel = levels.firstWhere((l) => l.id == _selectedLevel!.id);
        }
      } else if (levels.isNotEmpty) {
        _selectedLevel = levels.first;
      }
    });
  }

  void _playLevel() {
    if (_selectedLevel != null) {
      Navigator.of(context).pushNamed('/game', arguments: _selectedLevel);
    }
  }

  void _createNewLevel() async {
    final result = await showDialog<LevelModel>(
      context: context,
      builder: (context) => const CreateLevelDialog(),
    );

    if (result != null) {
      // Save it immediately so it persists even if the user doesn't hit save in editor
      await _repository.saveLevel(result);

      // Navigate to editor with new level
      if (mounted) {
        await Navigator.of(
          context,
        ).pushNamed('/levelEditor', arguments: result);
        _loadLevels(); // Refresh when coming back
      }
    }
  }

  void _editLevel() async {
    if (_selectedLevel != null) {
      await Navigator.of(
        context,
      ).pushNamed('/levelEditor', arguments: _selectedLevel);
      _loadLevels(); // Refresh when coming back
    }
  }

  void _deleteLevel() async {
    if (_selectedLevel == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Level'),
        content: Text(
          'Are you sure you want to delete "${_selectedLevel!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _repository.deleteLevel(_selectedLevel!.id);
      _loadLevels();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level Creator')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Create New Level Button
                    ElevatedButton.icon(
                      onPressed: _createNewLevel,
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Level'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),

                    // Existing Levels Section
                    const Text(
                      'Select Level',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Level Dropdown
                    DropdownButton<LevelModel>(
                      value: _selectedLevel,
                      isExpanded: true,
                      items: _levels.map((level) {
                        final typeLabel = level.category == 'custom'
                            ? ' (Custom)'
                            : ' (Built-in)';
                        return DropdownMenuItem(
                          value: level,
                          child: Text(
                            '${level.name}$typeLabel [${level.gridSize}x${level.gridSize}]',
                          ),
                        );
                      }).toList(),
                      onChanged: (level) {
                        setState(() => _selectedLevel = level);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _selectedLevel != null
                                ? _playLevel
                                : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedLevel != null
                                ? _editLevel
                                : null,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Delete Button (only for custom levels)
                    if (_selectedLevel != null &&
                        _selectedLevel!.category == 'custom')
                      OutlinedButton.icon(
                        onPressed: _deleteLevel,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Custom Level'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
