import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import 'entregador_available_orders_screen.dart';
import 'entregador_my_orders_screen.dart';
import 'entregador_profile_screen.dart';
import 'entregador_provider.dart';

class EntregadorShell extends StatefulWidget {
  const EntregadorShell({super.key});

  @override
  State<EntregadorShell> createState() => _EntregadorShellState();
}

class _EntregadorShellState extends State<EntregadorShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<EntregadorProvider>(
      builder: (context, provider, _) {
        final hasAvailable = provider.availableOrders.isNotEmpty;
        final hasActive = provider.myOrders.isNotEmpty;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              EntregadorAvailableOrdersScreen(),
              EntregadorMyOrdersScreen(),
              EntregadorProfileScreen(),
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
                  isLabelVisible: hasAvailable,
                  label: Text('${provider.availableOrders.length}'),
                  child: const Icon(Icons.inbox_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: hasAvailable,
                  label: Text('${provider.availableOrders.length}'),
                  child: const Icon(Icons.inbox),
                ),
                label: 'Disponíveis',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: hasActive,
                  child: const Icon(Icons.delivery_dining_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: hasActive,
                  child: const Icon(Icons.delivery_dining),
                ),
                label: 'Minhas entregas',
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
