class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String imagePath;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.imagePath,
  });

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      imagePath: map['imagePath'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
    };
  }
}
