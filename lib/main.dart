import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'core/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) => const MovieScoutApp(),
    ),
  );
}
