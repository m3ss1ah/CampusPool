import 'package:hive_flutter/hive_flutter.dart';

class HiveSetup {
  static const String conversationsBoxName = 'conversationsBox';
  static const String messagesBoxName = 'messagesBox';

  static Future<void> init() async {
    await Hive.openBox<String>(conversationsBoxName);
    await Hive.openBox<String>(messagesBoxName);
  }
}
