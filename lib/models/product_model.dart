class ProductModel {
  final String id;
  final String productName;
  final String barcode;
  final double sellingPrice;
  final bool isActive;
  final int quantity;

  ProductModel({
    required this.id,
    required this.productName,
    required this.barcode,
    required this.sellingPrice,
    this.isActive = true,
    this.quantity = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      productName: json['product_name'] ?? json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      sellingPrice: (json['selling_price'] ?? json['price'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? true,
      quantity: json['quantity'] ?? 0,
    );
  }
}
