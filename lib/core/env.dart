import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

Future<void> loadEnv() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv Error: $e");
  }
}
