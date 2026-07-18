import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/firebase_options.dart';
import 'providers/autenticacion_provider.dart';
import 'providers/ventas_cobros_provider.dart';
import 'screens/pantalla_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AutenticacionProvider()),
        ChangeNotifierProvider(create: (_) => VentasCobrosProvider()),
      ],
      child: const MiApp(),
    ),
  );
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Ventas y Cobros',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          primary: Colors.amber,
        ),
        useMaterial3: true,
      ),
      home: const GestorPantallas(),
    );
  }
}
