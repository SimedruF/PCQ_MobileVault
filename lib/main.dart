import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/crypto_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inițializează serviciile
  final secureStorage = FlutterSecureStorage();
  final databaseService = DatabaseService();
  final cryptoService = CryptoService();
  final authService = AuthService(secureStorage);
  
  await databaseService.initDatabase();
  
  runApp(MyApp(
    authService: authService,
    databaseService: databaseService,
    cryptoService: cryptoService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final DatabaseService databaseService;
  final CryptoService cryptoService;

  const MyApp({
    Key? key,
    required this.authService,
    required this.databaseService,
    required this.cryptoService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        Provider.value(value: databaseService),
        Provider.value(value: cryptoService),
      ],
      child: MaterialApp(
        title: 'PQC Mobile Vault',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: Consumer<AuthService>(
          builder: (context, authService, child) {
            if (authService.isAuthenticated) {
              return const HomeScreen();
            } else {
              return const AuthScreen();
            }
          },
        ),
      ),
    );
  }
}
