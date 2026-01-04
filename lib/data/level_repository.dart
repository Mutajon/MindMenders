import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_model.dart';
import 'level_database.dart';

class LevelRepository {
  static const String _levelsKey = 'custom_levels';

  // Get all levels (built-in + custom)
  Future<List<LevelModel>> getAllLevels() async {
    final custom = await getCustomLevels();
    final builtin = LevelDatabase.levels;

    // Filter out built-in levels that have a custom override
    final customIds = custom.map((l) => l.id).toSet();
    final filteredBuiltin = builtin.where((l) => !customIds.contains(l.id));

    return [...filteredBuiltin, ...custom];
  }

  // Get only custom levels
  Future<List<LevelModel>> getCustomLevels() async {
    print('🟢 LevelRepository.getCustomLevels called');
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_levelsKey);

    if (jsonString == null) {
      print('🟢 No custom levels found in storage');
      return [];
    }

    print('🟢 Found JSON data, length: ${jsonString.length}');

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<LevelModel> levels = [];

      for (final j in jsonList) {
        try {
          levels.add(LevelModel.fromJson(j as Map<String, dynamic>));
        } catch (e) {
          print('🟢 Error parsing individual level: $e');
          // Skip corrupt levels instead of failing entirely
        }
      }

      print('🟢 Loaded ${levels.length} custom levels');
      return levels;
    } catch (e) {
      print('🟢 Error decoding JSON: $e');
      return [];
    }
  }

  // Save a level
  Future<void> saveLevel(LevelModel level) async {
    print(
      '🔵 LevelRepository.saveLevel called for: ${level.name} (${level.id})',
    );
    final levels = await getCustomLevels();
    print('🔵 Current custom levels count: ${levels.length}');

    // Update existing or add new
    final index = levels.indexWhere((l) => l.id == level.id);
    if (index != -1) {
      print('🔵 Updating existing level at index $index');
      levels[index] = level;
    } else {
      print('🔵 Adding new level');
      levels.add(level);
    }

    // Persist
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(levels.map((l) => l.toJson()).toList());
    print(
      '🔵 Saving ${levels.length} levels, JSON length: ${jsonString.length}',
    );
    final success = await prefs.setString(_levelsKey, jsonString);
    print('🔵 Save result: $success');

    // Verify it was saved
    final verification = prefs.getString(_levelsKey);
    print('🔵 Verification read length: ${verification?.length ?? 0}');
  }

  // Delete a level
  Future<void> deleteLevel(String id) async {
    final levels = await getCustomLevels();
    levels.removeWhere((l) => l.id == id);

    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(levels.map((l) => l.toJson()).toList());
    await prefs.setString(_levelsKey, jsonString);
  }

  // Get a specific level
  Future<LevelModel?> getLevel(String id) async {
    final all = await getAllLevels();
    try {
      return all.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
}
