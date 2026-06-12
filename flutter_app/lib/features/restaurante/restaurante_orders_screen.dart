import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/order.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pill_badge.dart';
import 'restaurante_provider.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

Color _statusColor(OrderStatus s) => switch (s) {
      OrderStatus.CRIADO => fuba,
      OrderStatus.ACEITO => couve,
      OrderStatus.ENTREGADOR_DESIGNADO => couve,
      OrderStatus.EM_ENTREGA => urucum,
      OrderStatus.ENTREGUE => Colors.grey,
    };

class RestauranteOrdersScreen extends StatefulWidget {
  const RestauranteOrdersScreen({super.key});

  @override
  State<RestauranteOrdersScreen> createState() => _RestauranteOrdersScreenState();
}

class _RestauranteOrdersScreenState extends State<RestauranteOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestauranteProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestauranteProvider>(
      builder: (context, provider, _) {
        final pending = provider.orders
            .where((o) => o.status == OrderStatus.CRIADO)
            .toList();
        final active = provider.orders
            .where((o) =>
                o.status == OrderStatus.ACEITO ||
                o.status == OrderStatus.ENTREGADOR_DESIGNADO ||
                o.status == OrderStatus.EM_ENTREGA)
            .toList();
        final done = provider.orders
            .where((o) => o.status == OrderStatus.ENTREGUE)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pedidos'),
                if (pending.isNotEmpty)
                  Text(
                    '${pending.length} aguardando confirmação',
                    style: const TextStyle(
                      fontSize: 12,
                      color: fuba,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.fetchOrders(),
              ),
            ],
          ),
          body: provider.loadingOrders
              ? const Center(child: CircularProgressIndicator(color: urucum))
              : provider.orders.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long,
                      title: 'Nenhum pedido ainda',
                      hint: 'Quando clientes fizerem pedidos, eles aparecerão aqui.',
                    )
                  : RefreshIndicator(
                      color: urucum,
                      onRefresh: provider.fetchOrders,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (pending.isNotEmpty) ...[
                            _sectionHeader('Aguardando confirmação', fuba),
                            const SizedBox(height: 8),
                            ...pending.map((o) => _OrderCard(
                                  order: o,
                                  onAccept: () => provider.acceptOrder(o.id),
                                )),
                            const SizedBox(height: 16),
                          ],
                          if (active.isNotEmpty) ...[
                            _sectionHeader('Em andamento', couve),
                            const SizedBox(height: 8),
                            ...active.map((o) => _OrderCard(order: o)),
                            const SizedBox(height: 16),
                          ],
                          if (done.isNotEmpty) ...[
                            _sectionHeader('Entregues', Colors.grey),
                            const SizedBox(height: 8),
                            ...done.map((o) => _OrderCard(order: o)),
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

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onAccept;
  const _OrderCard({required this.order, this.onAccept});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final itemsSummary = order.items
        .map((i) => '${i.quantity}× ${i.menuItemName ?? i.menuItemId.substring(0, 6)}')
        .join(' · ');
    final diff = DateTime.now().difference(order.createdAt);
    final timeAgo = diff.inMinutes < 1
        ? 'agora'
        : diff.inMinutes < 60
            ? 'há ${diff.inMinutes} min'
            : 'há ${diff.inHours}h';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: onAccept != null
            ? Border.all(color: fuba.withValues(alpha: 0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pedido #$shortId',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
              ),
              const Spacer(),
              PillBadge(label: order.status.label, color: _statusColor(order.status)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.deliveryAddress,
            style: const TextStyle(fontSize: 12, color: textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (itemsSummary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(itemsSummary,
                style: const TextStyle(fontSize: 12, color: textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: textMuted),
              const SizedBox(width: 4),
              Text(timeAgo, style: const TextStyle(fontSize: 12, color: textMuted)),
              const Spacer(),
              Text(
                _brl.format(order.total),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: urucum),
              ),
            ],
          ),
          if (onAccept != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Aceitar pedido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: couve,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
