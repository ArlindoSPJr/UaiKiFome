class OrderItem {
  final String id;
  final String menuItemId;
  final int quantity;
  final double unitPrice;
  final String? menuItemName;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    this.menuItemName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as String,
    menuItemId: json['menuItemId'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    menuItemName: json['menuItem']?['name'] as String?,
  );
}
