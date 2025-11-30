import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game.dart';
import 'main_menu.dart';
import 'models/tile_model.dart';
import 'overlays/tile_info_overlay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Flame Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenu(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  TileModel? hoveredTile;
  late MyGame game;

  @override
  void initState() {
    super.initState();
    game = MyGame(
      onTileHoverChange: (tile) {
        setState(() {
          hoveredTile = tile;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MouseRegion(
            onHover: (details) {
              game.handleMouseMove(Vector2(
                details.localPosition.dx,
                details.localPosition.dy,
              ));
            },
            child: GameWidget(game: game),
          ),
          TileInfoOverlay(hoveredTile: hoveredTile),
        ],
      ),
    );
  }
}
