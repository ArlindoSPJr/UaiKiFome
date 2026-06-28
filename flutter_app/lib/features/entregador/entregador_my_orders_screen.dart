import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import 'entregador_order_card.dart';
import 'entregador_provider.dart';

class EntregadorMyOrdersScreen extends StatefulWidget {
  const EntregadorMyOrdersScreen({super.key});

  @override
  State<EntregadorMyOrdersScreen> createState() => _EntregadorMyOrdersScreenState();
}

class _EntregadorMyOrdersScreenState extends State<EntregadorMyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EntregadorProvider>();
      if (provider.myOrders.isEmpty && provider.completedOrders.isEmpty) {
        provider.fetchMyOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EntregadorProvider>(
      builder: (context, provider, _) {
        final active = provider.myOrders;
        final done = provider.completedOrders;
        final hasAny = active.isNotEmpty || done.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Minhas entregas'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.fetchMyOrders(),
              ),
            ],
          ),
          body: provider.loadingMine && !hasAny
              ? const Center(child: CircularProgressIndicator(color: urucum))
              : !hasAny
                  ? RefreshIndicator(
                      color: urucum,
                      onRefresh: provider.fetchMyOrders,
                      child: ListView(
                        children: const [
                          SizedBox(height: 120),
                          EmptyState(
                            icon: Icons.two_wheeler,
                            title: 'Nenhuma entrega ainda',
                            hint: 'Aceite um pedido na aba "Disponíveis" para começar.',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: urucum,
                      onRefresh: provider.fetchMyOrders,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (active.isNotEmpty) ...[
                            _sectionHeader('Em entrega', urucum),
                            const SizedBox(height: 8),
                            ...active.map((o) => EntregadorOrderCard(
                                  order: o,
                                  restaurant: provider.restaurantOf(o),
                                  primaryLabel: 'Confirmar entrega',
                                  primaryIcon: Icons.check_circle_outline,
                                  primaryColor: couve,
                                  onPrimary: () async {
                                    final ok = await provider.completeOrder(o.id);
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Erro ao confirmar entrega. Tente novamente.'),
                                        ),
                                      );
                                    }
                                  },
                                )),
                            const SizedBox(height: 16),
                          ],
                          if (done.isNotEmpty) ...[
                            _sectionHeader('Entregues', Colors.grey),
                            const SizedBox(height: 8),
                            ...done.map((o) => EntregadorOrderCard(
                                  order: o,
                                  restaurant: provider.restaurantOf(o),
                                )),
                          ],
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, Color color) => Row(
        children: [
          Container(width: 4, height: 16, color: color, margin: const EdgeInsets.only(right: 8)),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
        ],
      );
}
