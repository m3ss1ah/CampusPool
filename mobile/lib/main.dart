import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'core/cache/hive_setup.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Dark status bar for our dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  try {
    await Hive.initFlutter();
    await HiveSetup.init();
  } catch (e) {
    debugPrint('Hive init failed: $e');
  }

  // Initialize Map Tile Caching
  try {
    await FMTCObjectBoxBackend().initialise();
    await const FMTCStore('campuspool_map_cache').manage.create();
  } catch (e) {
    debugPrint('FMTC init failed: $e');
  }

  runApp(const ProviderScope(child: CampusPoolApp()));
}
