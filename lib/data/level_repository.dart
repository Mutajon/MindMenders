import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_model.dart';
import 'level_database.dart';

class LevelRepository {
  static const String _levelsKey = 'custom_levels';

  // Get all levels (built-in + custom)
  Future<List<LevelModel>> getAllLevels() async {
    final custom = await getCustomLevels();
    final builtin = LevelDatabase.levels;
    return [...builtin, ...custom];
  }

  // Get only custom levels
  Future<List<LevelModel>> getCustomLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_levelsKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => LevelModel.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error loading custom levels: $e');
      return [];
    }
  }

  // Save a level
  Future<void> saveLevel(LevelModel level) async {
    final levels = await getCustomLevels();

    // Update existing or add new
    final index = levels.indexWhere((l) => l.id == level.id);
    if (index != -1) {
      levels[index] = level;
    } else {
      levels.add(level);
    }

    // Persist
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(levels.map((l) => l.toJson()).toList());
    await prefs.setString(_levelsKey, jsonString);
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
