import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/order.dart';
import '../../core/models/restaurant.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/pill_badge.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

Color statusColor(OrderStatus s) => switch (s) {
      OrderStatus.CRIADO => fuba,
      OrderStatus.ACEITO => couve,
      OrderStatus.ENTREGADOR_DESIGNADO => couve,
      OrderStatus.EM_ENTREGA => urucum,
      OrderStatus.ENTREGUE => Colors.grey,
    };

class EntregadorOrderCard extends StatelessWidget {
  final Order order;
  final Restaurant? restaurant;
  final String? primaryLabel;
  final IconData? primaryIcon;
  final Color? primaryColor;
  final Future<void> Function()? onPrimary;
  final VoidCallback? onReject;

  const EntregadorOrderCard({
    super.key,
    required this.order,
    this.restaurant,
    this.primaryLabel,
    this.primaryIcon,
    this.primaryColor,
    this.onPrimary,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final itemsSummary = order.items
        .map((i) => '${i.quantity}× ${i.menuItemName ?? 'Item'}')
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
        border: onPrimary != null
            ? Border.all(color: couve.withValues(alpha: 0.4), width: 1.5)
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
              PillBadge(label: order.status.label, color: statusColor(order.status)),
            ],
          ),
          const SizedBox(height: 8),
          _locationRow(
            Icons.store_outlined,
            cafe,
            'Retirar em',
            restaurant != null
                ? '${restaurant!.name} — ${restaurant!.address}'
                : (order.restaurantName ?? 'Restaurante'),
          ),
          if (order.clientName != null) ...[
            const SizedBox(height: 4),
            _locationRow(Icons.person_outline, cafe, 'Cliente', order.clientName!),
          ],
          const SizedBox(height: 4),
          _locationRow(
            Icons.location_on_outlined,
            urucum,
            'Entregar em',
            order.deliveryAddress,
          ),
          if (itemsSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(itemsSummary,
                style: const TextStyle(fontSize: 12, color: textMuted),
                maxLines: 2,
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
          if (onPrimary != null && primaryLabel != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onPrimary!(),
                icon: Icon(primaryIcon ?? Icons.check_circle_outline, size: 16),
                label: Text(primaryLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor ?? couve,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          if (onReject != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, size: 16, color: textMuted),
                label: const Text(
                  'Recusar',
                  style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: textMuted),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: textDark),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      );
}
