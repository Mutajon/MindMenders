import 'package:flutter/material.dart';
import '../models/level_model.dart';

class CreateLevelDialog extends StatefulWidget {
  const CreateLevelDialog({super.key});

  @override
  State<CreateLevelDialog> createState() => _CreateLevelDialogState();
}

class _CreateLevelDialogState extends State<CreateLevelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _gridSize = 5;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState!.validate()) {
      final level = LevelModel.createEmpty(
        name: _nameController.text.trim(),
        gridSize: _gridSize,
      );
      Navigator.of(context).pop(level);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Level'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name Input
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Level Name',
                hintText: 'Enter level name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a level name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Grid Size Dropdown
            DropdownButtonFormField<int>(
              initialValue: _gridSize,
              decoration: const InputDecoration(labelText: 'Grid Size'),
              items: List.generate(6, (index) => index + 5)
                  .map(
                    (size) => DropdownMenuItem(
                      value: size,
                      child: Text('${size}x$size'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _gridSize = value!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}
