class CartItem {
  final String menuItemId;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });
}
