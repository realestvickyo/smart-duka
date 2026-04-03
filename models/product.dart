class Product {
  final String id;
  final String name;
  final double sellingPrice;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.sellingPrice,
    this.stock = 99, // plenty for now
  });
}