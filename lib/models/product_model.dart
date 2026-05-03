// Represents a product (can be consignment or grocery type)
class ProductModel {
  final String id;
  final String productName;
  final String barcode;
  final String? productImage; // URL to image in Supabase Storage, nullable
  final bool isActive;
  final double sellingPrice;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.productName,
    required this.barcode,
    this.productImage,
    required this.isActive,
    required this.sellingPrice,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      barcode: json['barcode'] as String,
      productImage: json['product_image'] as String?,
      isActive: json['is_active'] as bool,
      sellingPrice: (json['selling_price'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'barcode': barcode,
      'is_active': isActive,
      'selling_price': sellingPrice,
      if (productImage != null) 'product_image': productImage,
    };
  }

  ProductModel copyWith({
    String? id,
    String? productName,
    String? barcode,
    String? productImage,
    bool? isActive,
    double? sellingPrice,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      productImage: productImage ?? this.productImage,
      isActive: isActive ?? this.isActive,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}