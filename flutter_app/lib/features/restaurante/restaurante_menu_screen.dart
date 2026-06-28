import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/dish_thumb.dart';
import '../../shared/widgets/empty_state.dart';
import 'restaurante_provider.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class RestauranteMenuScreen extends StatefulWidget {
  const RestauranteMenuScreen({super.key});

  @override
  State<RestauranteMenuScreen> createState() => _RestauranteMenuScreenState();
}

class _RestauranteMenuScreenState extends State<RestauranteMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RestauranteProvider>();
      if (provider.menuItems.isEmpty) provider.fetchMenu();
    });
  }

  void _openAddItemSheet(BuildContext context, RestauranteProvider provider) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Novo item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nome do prato *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Preço *',
                  prefixText: 'R\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o preço';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Preço inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Quantidade em estoque *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe a quantidade';
                  final parsed = int.tryParse(v.trim());
                  if (parsed == null || parsed < 0) return 'Quantidade inválida';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final price =
                      double.parse(priceCtrl.text.replaceAll(',', '.'));
                  final quantity = int.parse(quantityCtrl.text.trim());
                  final ok = await provider.addMenuItem(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    price: price,
                    quantity: quantity,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao adicionar item.')),
                    );
                  }
                },
                child: const Text('Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestauranteProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cardápio'),
                Text(
                  '${provider.menuItems.length} ${provider.menuItems.length == 1 ? 'item' : 'itens'}',
                  style: const TextStyle(
                      fontSize: 12, color: textMuted, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          body: provider.loadingMenu
              ? const Center(child: CircularProgressIndicator(color: urucum))
              : provider.menuItems.isEmpty
                  ? const EmptyState(
                      icon: Icons.menu_book,
                      title: 'Cardápio vazio',
                      hint: 'Adicione pratos usando o botão abaixo.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: provider.menuItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final item = provider.menuItems[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              DishThumb(name: item.name, size: 56),
                              const SizedBox(width: 12),
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
                                    if (item.description != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description!,
                                        style: const TextStyle(
                                            fontSize: 12, color: textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _brl.format(item.price),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: urucum,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 13,
                                          color: item.quantity > 0 ? couve : urucum,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          item.quantity > 0
                                              ? '${item.quantity} em estoque'
                                              : 'Sem estoque',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: item.quantity > 0 ? couve : urucum,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: item.available,
                                onChanged: (v) =>
                                    provider.toggleAvailability(item.id, v),
                                activeThumbColor: couve,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddItemSheet(context, provider),
            backgroundColor: urucum,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Adicionar prato',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}
