import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/counter_widget.dart';
import 'cliente_provider.dart';
import 'cliente_tracking_screen.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class ClienteCartScreen extends StatefulWidget {
  const ClienteCartScreen({super.key});

  @override
  State<ClienteCartScreen> createState() => _ClienteCartScreenState();
}

class _ClienteCartScreenState extends State<ClienteCartScreen> {
  final _addressController = TextEditingController(
    text: 'Rua das Flores, 88 — Lourdes',
  );

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClienteProvider>(
      builder: (context, provider, _) {
        final subtotal = provider.cartSubtotal;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Carrinho'),
                if (provider.cartRestaurantId != null)
                  Text(
                    provider.cartRestaurantName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          body: provider.cartItems.isEmpty
              ? const Center(
                  child: Text(
                    'Seu carrinho está vazio.',
                    style: TextStyle(color: textMuted),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    ...provider.cartItems.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _brl.format(item.price),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: urucum,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CounterWidget(
                              value: item.quantity,
                              onChanged: (q) =>
                                  provider.setCartQty(item.menuItemId, q),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Endereço de entrega',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined, color: urucum),
                        hintText: 'Seu endereço',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SummaryRow(label: 'Subtotal', value: _brl.format(subtotal)),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: 'Total',
                      value: _brl.format(subtotal),
                      bold: true,
                    ),
                  ],
                ),
          bottomNavigationBar: provider.cartItems.isNotEmpty
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () => _checkout(context, provider),
                      child: Text(
                        'Fazer pedido · ${_brl.format(subtotal)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<void> _checkout(BuildContext context, ClienteProvider provider) async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o endereço de entrega')),
      );
      return;
    }
    final order = await provider.placeOrder(address);
    if (!context.mounted) return;
    if (order != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ClienteTrackingScreen(order: order)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao fazer pedido. Tente novamente.')),
      );
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: bold ? textDark : textMuted,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style.copyWith(color: bold ? urucum : textMuted)),
      ],
    );
  }
}
