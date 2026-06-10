import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurant.dart';
import '../../features/auth/auth_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/dish_thumb.dart';
import '../../shared/widgets/empty_state.dart';
import 'cliente_provider.dart';
import 'cliente_restaurant_screen.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

const _categories = [
  'Comida mineira',
  'Pão de queijo',
  'Boteco',
  'Doces',
  'Bebidas',
  'Salgados',
];

class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().fetchRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final firstName = auth.user?.name.split(' ').first ?? 'você';

    return Consumer<ClienteProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(firstName)),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildCategories()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Restaurantes pertinho de ocê',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
                if (provider.loadingRestaurants)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: urucum)),
                  )
                else if (provider.restaurants.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.restaurant,
                      title: 'Nenhum restaurante',
                      hint: 'Ainda não tem restaurante por aqui. Volta mais tarde!',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _RestaurantCard(
                          restaurant: provider.restaurants[i],
                        ),
                        childCount: provider.restaurants.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: provider.cartCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () {},
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

  Widget _buildHeader(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: urucum, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Lourdes, BH',
                style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'E aí, $firstName! Cumê que tá?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: textMuted),
            const SizedBox(width: 8),
            const Text(
              'Procura aí, sô… pão de queijo, tropeiro…',
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? cafe : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? cafe : Colors.grey.shade300),
              ),
              child: Text(
                _categories[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final color = restaurantColor(restaurant.name);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClienteRestaurantScreen(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                restaurant.name[0].toUpperCase(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark),
                  ),
                  if (restaurant.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      restaurant.description!,
                      style: const TextStyle(fontSize: 12, color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: fuba, size: 14),
                      const SizedBox(width: 2),
                      const Text('4.8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, color: textMuted, size: 14),
                      const SizedBox(width: 2),
                      const Text('30 min', style: TextStyle(fontSize: 12, color: textMuted)),
                      const SizedBox(width: 8),
                      const Text('R\$ 6,90', style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textMuted),
          ],
        ),
      ),
    );
  }
}
