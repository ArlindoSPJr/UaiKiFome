class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final double price;
  final bool available;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    required this.available,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as String,
    restaurantId: json['restaurantId'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toDouble(),
    available: json['available'] as bool? ?? true,
  );
}
