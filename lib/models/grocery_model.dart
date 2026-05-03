// Identifies which products are grocery items (not consignment)
class GroceryModel {
  final String id;
  final String productId;

  const GroceryModel({
    required this.id,
    required this.productId,
  });

  factory GroceryModel.fromJson(Map<String, dynamic> json) {
    return GroceryModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
    };
  }

  GroceryModel copyWith({
    String? id,
    String? productId,
  }) {
    return GroceryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
    );
  }
}