import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'theme.dart';
import '../screens/auth_gate.dart';

class HireMeSQLApp extends StatelessWidget {
  const HireMeSQLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()
        ..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HireMeSQL',
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}