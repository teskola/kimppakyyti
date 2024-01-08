import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kimppakyyti/providers/location.dart';
import 'package:kimppakyyti/providers/ride_id.dart';
import 'package:kimppakyyti/providers/route.dart';
import 'package:kimppakyyti/providers/status.dart';
import 'package:kimppakyyti/providers/time.dart';
import 'package:kimppakyyti/providers/user.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth.dart';
import 'screens/login.dart';
import 'screens/navigation.dart';
import 'widgets/loading_spinner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthProvider>(lazy: false, create: (_) => AuthProvider()),
        Provider<UserProvider>(lazy: false, create: (_) => UserProvider()),
        ChangeNotifierProvider<RideIdProvider>(
          create: (_) => RideIdProvider(),
        ),
        ChangeNotifierProxyProvider<RideIdProvider, TimeProvider>(
          create: (_) => TimeProvider(),
          update: (_, idProvider, timeProvider) {
            if (timeProvider == null) {
              throw Exception('TimeProvider not created');
            }
            return timeProvider..fetchAll(idProvider.data);
          },
        ),
        ChangeNotifierProvider<StatusProvider>(create: (_) => StatusProvider()),
        ChangeNotifierProvider<RouteProvider>(create: (_) => RouteProvider()),
        ChangeNotifierProvider<LocationProvider>(lazy: false, create: (context) => LocationProvider(context))
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        title: 'Kimppakyyti',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            return snapshot.hasData
                ? const NavigationPage()
                : const LoginPage();
          }
          return const LoadingSpinner();
        });
  }
}
