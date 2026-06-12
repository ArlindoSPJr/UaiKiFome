import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user.dart';
import '../../shared/theme/app_theme.dart';
import 'auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.client;

  static const _roleLabels = {
    UserRole.client: 'Cliente',
    UserRole.restaurant: 'Restaurante',
    UserRole.delivery: 'Entregador',
  };

  static const _roleSubtitles = {
    UserRole.client: 'Cê tá cum fome, né?',
    UserRole.restaurant: 'Bora gerenciar seu restaurante!',
    UserRole.delivery: 'Partiu fazer entrega!',
  };

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erro ao fazer login.'),
          backgroundColor: urucum,
        ),
      );
      return;
    }
    if (auth.user!.role != _selectedRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Esta conta não é de um ${_roleLabels[_selectedRole]!.toLowerCase()}.',
          ),
          backgroundColor: urucum,
        ),
      );
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'UaiKiFome',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: urucum,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _roleSubtitles[_selectedRole]!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: textMuted),
                      ),
                      const SizedBox(height: 24),

                      // Role tabs
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment(
                            value: UserRole.client,
                            label: Text('Cliente'),
                            icon: Icon(Icons.person_outline),
                          ),
                          ButtonSegment(
                            value: UserRole.restaurant,
                            label: Text('Restaurante'),
                            icon: Icon(Icons.restaurant_outlined),
                          ),
                          ButtonSegment(
                            value: UserRole.delivery,
                            label: Text('Entregador'),
                            icon: Icon(Icons.delivery_dining_outlined),
                          ),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (set) =>
                            setState(() => _selectedRole = set.first),
                        style: ButtonStyle(
                          iconSize: const WidgetStatePropertyAll(16),
                        ),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe seu e-mail.';
                          if (!v.contains('@')) return 'E-mail inválido.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(auth),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe sua senha.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.loading ? null : () => _submit(auth),
                          child: auth.loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text('Criar conta'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
