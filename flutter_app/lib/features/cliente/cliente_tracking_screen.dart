import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/order.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/pill_badge.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

Color _statusColor(OrderStatus s) => switch (s) {
      OrderStatus.CRIADO => fuba,
      OrderStatus.ACEITO => couve,
      OrderStatus.ENTREGADOR_DESIGNADO => couve,
      OrderStatus.EM_ENTREGA => urucum,
      OrderStatus.ENTREGUE => Colors.grey,
    };

const _steps = [
  (status: OrderStatus.CRIADO, label: 'Restaurante recebeu', icon: Icons.restaurant),
  (status: OrderStatus.ACEITO, label: 'Preparando o trem bão', icon: Icons.soup_kitchen),
  (status: OrderStatus.EM_ENTREGA, label: 'Saiu pra entrega', icon: Icons.delivery_dining),
  (status: OrderStatus.ENTREGUE, label: 'Chegou na porta!', icon: Icons.home),
];

int _statusIndex(OrderStatus s) => switch (s) {
      OrderStatus.CRIADO => 0,
      OrderStatus.ACEITO => 1,
      OrderStatus.ENTREGADOR_DESIGNADO => 2,
      OrderStatus.EM_ENTREGA => 2,
      OrderStatus.ENTREGUE => 3,
    };

class ClienteTrackingScreen extends StatelessWidget {
  final Order order;
  const ClienteTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final currentStep = _statusIndex(order.status);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pedido #$shortId'),
            Text(
              order.deliveryAddress,
              style: const TextStyle(
                fontSize: 11,
                color: textMuted,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Fake map area
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: CustomPaint(
                    size: const Size(200, 80),
                    painter: _RoutePainter(),
                  ),
                ),
                const Positioned(
                  left: 40,
                  top: 60,
                  child: _MapPin(label: 'R', color: couve),
                ),
                Positioned(
                  right: 40,
                  top: 60,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: urucum,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.home, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status card
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status atual',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.status.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                PillBadge(
                  label: order.status.label,
                  color: _statusColor(order.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Timeline
          const Text(
            'Acompanhamento',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isDone = i < currentStep;
            final isCurrent = i == currentStep;
            final isFuture = i > currentStep;

            return _TimelineStep(
              label: step.label,
              icon: step.icon,
              isDone: isDone,
              isCurrent: isCurrent,
              isFuture: isFuture,
              isLast: i == _steps.length - 1,
            );
          }),
          const SizedBox(height: 20),

          // Items list
          const Text(
            'Itens do pedido',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}×  ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: urucum,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.menuItemName ??
                          item.menuItemId.substring(
                              0, item.menuItemId.length.clamp(0, 8)),
                      style: const TextStyle(color: textDark),
                    ),
                  ),
                  Text(
                    _brl.format(item.unitPrice * item.quantity),
                    style: const TextStyle(color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              Text(
                _brl.format(order.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: urucum,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isFuture;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.isFuture,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor =
        isDone ? couve : (isCurrent ? urucum : Colors.grey.shade300);
    final textColor = isFuture ? textMuted : (isCurrent ? urucum : couve);

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                child: Icon(
                  isDone ? Icons.check : icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? couve : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final String label;
  final Color color;
  const _MapPin({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(width: 2, height: 8, color: color),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = urucum.withOpacity(0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(
        size.width * 0.25,
        0,
        size.width * 0.75,
        size.height,
        size.width,
        size.height * 0.5,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
