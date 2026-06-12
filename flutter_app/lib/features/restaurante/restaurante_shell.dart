import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/order.dart';
import '../../shared/theme/app_theme.dart';
import 'restaurante_menu_screen.dart';
import 'restaurante_orders_screen.dart';
import 'restaurante_profile_screen.dart';
import 'restaurante_provider.dart';

class RestauranteShell extends StatefulWidget {
  const RestauranteShell({super.key});

  @override
  State<RestauranteShell> createState() => _RestauranteShellState();
}

class _RestauranteShellState extends State<RestauranteShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<RestauranteProvider>(
      builder: (context, provider, _) {
        if (provider.loadingRestaurant) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: urucum)),
          );
        }

        if (provider.myRestaurant == null) {
          return _RestauranteSetupScreen(provider: provider);
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              RestauranteOrdersScreen(),
              RestauranteMenuScreen(),
              RestauranteProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: urucum,
            unselectedItemColor: textMuted,
            backgroundColor: bgCard,
            items: [
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: provider.orders
                      .any((o) => o.status == OrderStatus.CRIADO),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: provider.orders
                      .any((o) => o.status == OrderStatus.CRIADO),
                  child: const Icon(Icons.receipt_long),
                ),
                label: 'Pedidos',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Cardápio',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RestauranteSetupScreen extends StatefulWidget {
  final RestauranteProvider provider;
  const _RestauranteSetupScreen({required this.provider});

  @override
  State<_RestauranteSetupScreen> createState() => _RestauranteSetupScreenState();
}

class _RestauranteSetupScreenState extends State<_RestauranteSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await widget.provider.createMyRestaurant(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    if (mounted) setState(() => _loading = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cadastrar restaurante. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.storefront_outlined, size: 64, color: urucum),
                  const SizedBox(height: 16),
                  Text(
                    'Cadastre seu restaurante',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: textDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Antes de começar, precisamos das informações do seu estabelecimento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome do restaurante *',
                      prefixIcon: Icon(Icons.restaurant_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Endereço *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o endereço' : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Cadastrar restaurante'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
