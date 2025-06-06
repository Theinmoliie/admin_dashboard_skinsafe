class Product {
  final int? productId;
  final String productName;
  final String productType;
  final String brand;
  final String imageUrl;
  final double price;
  final String productDescription;

  Product({
    this.productId,
    required this.productName,
    required this.productType,
    required this.brand,
    required this.imageUrl,
    required this.price,
    required this.productDescription,
  });

  // The toMap method is likely correct, as it defines what you send.
  Map<String, dynamic> toMap() {
    return {
      if (productId != null) 'Product_Id': productId,
      'Product_Name': productName,
      'Product_Type': productType,
      'Brand': brand,
      'Image_Url': imageUrl,
      'Price': price,
      'Product_Description': productDescription,
    };
  }

  // --- THIS IS THE CRITICAL FIX ---
  // Create a Product object from a Map from Supabase with safety checks.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      // Ensure the ID is cast correctly. Default to 0 if null.
      productId: (map['Product_Id'] as num?)?.toInt() ?? 0,

      // For strings, check for null and provide an empty string as a fallback.
      productName: map['Product_Name'] as String? ?? 'No Name',
      productType: map['Product_Type'] as String? ?? 'No Type',
      brand: map['Brand'] as String? ?? 'No Brand',
      imageUrl: map['Image_Url'] as String? ?? '',
      productDescription: map['Product_Description'] as String? ?? 'No Description',

      // For numbers, cast as num first, then to double, with a fallback.
      price: (map['Price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}