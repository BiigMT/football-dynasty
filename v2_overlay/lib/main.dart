import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/portrait_lock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PortraitLock.apply();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF08111D),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1928),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const FootballDynastyApp());
}
