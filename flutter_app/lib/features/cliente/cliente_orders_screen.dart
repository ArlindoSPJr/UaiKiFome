import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/order.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pill_badge.dart';
import 'cliente_provider.dart';
import 'cliente_tracking_screen.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

Color _statusColor(OrderStatus s) => switch (s) {
      OrderStatus.CRIADO => fuba,
      OrderStatus.ACEITO => couve,
      OrderStatus.ENTREGADOR_DESIGNADO => couve,
      OrderStatus.EM_ENTREGA => urucum,
      OrderStatus.ENTREGUE => Colors.grey,
    };

class ClienteOrdersScreen extends StatefulWidget {
  const ClienteOrdersScreen({super.key});

  @override
  State<ClienteOrdersScreen> createState() => _ClienteOrdersScreenState();
}

class _ClienteOrdersScreenState extends State<ClienteOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClienteProvider>(
      builder: (context, provider, _) {
        final active =
            provider.orders.where((o) => o.status != OrderStatus.ENTREGUE).toList();
        final past =
            provider.orders.where((o) => o.status == OrderStatus.ENTREGUE).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meus pedidos'),
                Text(
                  'Cumê que vão os pedidos?',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          body: provider.loadingOrders
              ? const Center(child: CircularProgressIndicator(color: urucum))
              : provider.orders.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long,
                      title: 'Nenhum pedido ainda',
                      hint: 'Faça seu primeiro pedido!',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (active.isNotEmpty) ...[
                          _sectionHeader('Em andamento'),
                          const SizedBox(height: 8),
                          ...active.map((o) => _OrderCard(order: o)),
                          const SizedBox(height: 16),
                        ],
                        if (past.isNotEmpty) ...[
                          _sectionHeader('Anteriores'),
                          const SizedBox(height: 8),
                          ...past.map((o) => _OrderCard(order: o)),
                        ],
                      ],
                    ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      );
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final itemsSummary = order.items
        .map((i) => '${i.quantity}× ${i.menuItemName ?? 'Item'}')
        .join(' · ');
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final timeAgo = _timeAgo(order.updatedAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ClienteTrackingScreen(order: order)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pedido #$shortId',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const Spacer(),
                PillBadge(
                  label: order.status.label,
                  color: _statusColor(order.status),
                ),
              ],
            ),
            if (order.restaurantName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 12, color: cafe),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.restaurantName!,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            if (itemsSummary.isNotEmpty)
              Text(
                itemsSummary,
                style: const TextStyle(fontSize: 12, color: textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: const TextStyle(fontSize: 12, color: textMuted),
                ),
                const Spacer(),
                Text(
                  _brl.format(order.total),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: urucum,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}
