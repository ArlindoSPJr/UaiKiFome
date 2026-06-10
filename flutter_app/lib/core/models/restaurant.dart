import 'menu_item.dart';

class Restaurant {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String address;
  final List<MenuItem> items;

  const Restaurant({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.address,
    this.items = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    address: json['address'] as String,
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}
