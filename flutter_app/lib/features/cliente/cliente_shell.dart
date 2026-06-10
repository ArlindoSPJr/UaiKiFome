import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/order.dart';
import '../../shared/theme/app_theme.dart';
import 'cliente_cart_screen.dart';
import 'cliente_home_screen.dart';
import 'cliente_orders_screen.dart';
import 'cliente_profile_screen.dart';
import 'cliente_provider.dart';

class ClienteShell extends StatefulWidget {
  const ClienteShell({super.key});

  @override
  State<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends State<ClienteShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ClienteProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              ClienteHomeScreen(),
              ClienteCartScreen(),
              ClienteOrdersScreen(),
              ClienteProfileScreen(),
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
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: provider.cartCount > 0,
                  label: Text('${provider.cartCount}'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: provider.cartCount > 0,
                  label: Text('${provider.cartCount}'),
                  child: const Icon(Icons.shopping_bag),
                ),
                label: 'Carrinho',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: provider.orders
                      .any((o) => o.status != OrderStatus.ENTREGUE),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: provider.orders
                      .any((o) => o.status != OrderStatus.ENTREGUE),
                  child: const Icon(Icons.receipt_long),
                ),
                label: 'Pedidos',
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
