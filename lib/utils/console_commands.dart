@JS()
library console_commands;

import 'package:js/js.dart';

@JS('console.log')
external void consoleLog(String message);

// Global function to expose game commands
@JS('window.gameCommands')
external set gameCommands(Object commands);
