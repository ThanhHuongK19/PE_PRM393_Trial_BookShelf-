import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'services/book_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authProvider = AuthProvider();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        Provider<BookService>(create: (_) => BookService()),
      ],
      child: BookShelfApp(authProvider: authProvider),
    ),
  );
}

class BookShelfApp extends StatefulWidget {
  const BookShelfApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<BookShelfApp> createState() => _BookShelfAppState();
}

class _BookShelfAppState extends State<BookShelfApp> {
  late final _router = createAppRouter(widget.authProvider);

  @override
  void dispose() {
    _router.dispose();
    widget.authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BookShelf',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C4C)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
