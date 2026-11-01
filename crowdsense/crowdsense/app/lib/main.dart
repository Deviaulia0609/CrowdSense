import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'state/app_state.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = AppState();
  await app.init();
  runApp(ChangeNotifierProvider.value(value: app, child: const CrowdSenseApp()));
}

class CrowdSenseApp extends StatelessWidget {
  const CrowdSenseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CrowdSense',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: navy),
          scaffoldBackgroundColor: bgColor,
        ),
        home: const DashboardScreen(),
      );
}
