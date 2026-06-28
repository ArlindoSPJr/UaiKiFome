import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import 'entregador_order_card.dart';
import 'entregador_provider.dart';

class EntregadorAvailableOrdersScreen extends StatefulWidget {
  const EntregadorAvailableOrdersScreen({super.key});

  @override
  State<EntregadorAvailableOrdersScreen> createState() =>
      _EntregadorAvailableOrdersScreenState();
}

class _EntregadorAvailableOrdersScreenState
    extends State<EntregadorAvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EntregadorProvider>();
      if (provider.availableOrders.isEmpty) provider.fetchAvailableOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EntregadorProvider>(
      builder: (context, provider, _) {
        final orders = provider.availableOrders;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pedidos disponíveis'),
                if (orders.isNotEmpty)
                  Text(
                    '${orders.length} aguardando entregador',
                    style: const TextStyle(
                      fontSize: 12,
                      color: couve,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.fetchAvailableOrders(),
              ),
            ],
          ),
          body: provider.loadingAvailable && orders.isEmpty
              ? const Center(child: CircularProgressIndicator(color: urucum))
              : orders.isEmpty
                  ? RefreshIndicator(
                      color: urucum,
                      onRefresh: provider.fetchAvailableOrders,
                      child: ListView(
                        children: const [
                          SizedBox(height: 120),
                          EmptyState(
                            icon: Icons.delivery_dining,
                            title: 'Nenhum pedido disponível',
                            hint: 'Quando restaurantes aceitarem pedidos, eles aparecerão aqui.',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: urucum,
                      onRefresh: provider.fetchAvailableOrders,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: orders
                            .map((o) => EntregadorOrderCard(
                                  order: o,
                                  restaurant: provider.restaurantOf(o),
                                  primaryLabel: 'Aceitar entrega',
                                  primaryIcon: Icons.delivery_dining,
                                  primaryColor: couve,
                                  onPrimary: () async {
                                    final ok = await provider.acceptOrder(o.id);
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Erro ao aceitar entrega. Tente novamente.'),
                                        ),
                                      );
                                    }
                                  },
                                  onReject: () => provider.rejectOrder(o.id),
                                ))
                            .toList(),
                      ),
                    ),
        );
      },
    );
  }
}
