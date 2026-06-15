import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/menu_item.dart';
import '../../core/models/restaurant.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/dish_thumb.dart';
import 'cliente_cart_screen.dart';
import 'cliente_provider.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class ClienteRestaurantScreen extends StatelessWidget {
  final Restaurant restaurant;
  const ClienteRestaurantScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final color = restaurantColor(restaurant.name);
    return Consumer<ClienteProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: color,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: color,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            restaurant.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (restaurant.description != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              restaurant.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.star, color: fuba, size: 14),
                            Text(' 4.8  ', style: TextStyle(color: Colors.white, fontSize: 12)),
                            Icon(Icons.access_time, color: Colors.white70, size: 14),
                            Text(' 30 min  ', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (restaurant.items.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Cardápio vazio por aqui.',
                      style: TextStyle(color: textMuted),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _MenuItemCard(
                        item: restaurant.items[i],
                        restaurantId: restaurant.id,
                      ),
                      childCount: restaurant.items.length,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: provider.cartCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClienteCartScreen()),
                    );
                  },
                  backgroundColor: urucum,
                  icon: const Icon(Icons.shopping_bag, color: Colors.white),
                  label: Text(
                    'Ver carrinho · ${_brl.format(provider.cartSubtotal)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final String restaurantId;
  const _MenuItemCard({required this.item, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          DishThumb(name: item.name, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!,
                    style: const TextStyle(fontSize: 12, color: textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _brl.format(item.price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: urucum,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              context.read<ClienteProvider>().addToCart(
                    restaurantId,
                    item.id,
                    item.name,
                    item.price,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: urucum,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}
