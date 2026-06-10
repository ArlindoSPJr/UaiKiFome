import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/models/user.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/cliente/cliente_provider.dart';
import 'features/cliente/cliente_shell.dart';
import 'shared/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const UaiKiFomeApp(),
    ),
  );
}

class UaiKiFomeApp extends StatelessWidget {
  const UaiKiFomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UaiKiFome',
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => ClienteProvider(clientId: auth.user!.id),
              ),
            ],
            child: auth.user!.role == UserRole.client
                ? const ClienteShell()
                : Scaffold(
                    body: Center(
                      child: Text('Role: ${auth.user!.role.name}'),
                    ),
                  ),
          );
        }
        return const LoginScreen();
      },
    );
  }
}
