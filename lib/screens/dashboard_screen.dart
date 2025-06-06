import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../widgets/product_form_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  // --- THIS IS THE CORRECTED AND MODERN FUNCTION ---
  // It uses a try/catch block to find the exact database error.
  Future<List<Product>> _getProducts() async {
    try {
      const selectQuery =
          'Product_Id, Product_Name, Product_Type, Brand, Image_Url, Price, Product_Description';

      // This call will throw a PostgrestException if there's a DB error.
      final response = await _supabase
          .from('Products')
          .select(selectQuery)
          .order('Product_Id', ascending: false);

      // This part will only run if the query was successful.
      // The response is already a List<dynamic>, not null.
      return response.map((item) => Product.fromMap(item)).toList();

    } on PostgrestException catch (e) {
      // This block will catch specific Supabase errors, like "table not found".
      debugPrint('--- SUPABASE POSTGREST ERROR ---');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('-----------------------------');
      // Rethrow a user-friendly error to be shown in the UI.
      throw Exception('Database Error: ${e.message}');
    } catch (e) {
      // This block will catch any other errors (e.g., network issues).
      debugPrint('--- UNEXPECTED ERROR ---');
      debugPrint('An unexpected error occurred: $e');
      debugPrint('------------------------');
      // Rethrow to show the error in the UI.
      rethrow;
    }
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // This will now catch the error we threw from the catch block.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Failed to load products.\n\nError: ${snapshot.error}\n\nPlease check the debug console for more details.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found. Click the + button to add one.'));
          }

          final products = snapshot.data!;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1000),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Expanded(child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold)))),
                    DataColumn(label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: products.map((product) {
                    return DataRow(cells: [
                      DataCell(SizedBox(width: 300, child: Text(product.productName, overflow: TextOverflow.ellipsis)), onTap: () => _showProductDialog(product: product)),
                      DataCell(Text(product.brand)),
                      DataCell(Text(product.productType)),
                      DataCell(Text(NumberFormat.currency(symbol: '\$').format(product.price))),
                      DataCell(Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), tooltip: 'Edit', onPressed: () => _showProductDialog(product: product)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Delete', onPressed: () => _deleteProduct(product.productId!)),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- CRUD Helper Methods (No changes needed here) ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  void _showProductDialog({Product? product}) {
    showDialog(context: context, builder: (context) => ProductFormDialog(product: product, onSubmit: _handleProductSubmission));
  }

  Future<void> _handleProductSubmission(Product product) async {
    try {
      if (product.productId == null) {
        await _supabase.from('Products').insert(product.toMap());
      } else {
        await _supabase.from('Products').update(product.toMap()).eq('Product_Id', product.productId!);
      }
      _refreshProducts();
    } catch (e) {
      _showErrorSnackBar('Failed to save product: ${e.toString()}');
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final shouldDelete = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Confirm Deletion'),
      content: const Text('Are you sure you want to delete this product?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
      ],
    ));
    if (shouldDelete == true) {
      try {
        await _supabase.from('Products').delete().eq('Product_Id', productId);
        _refreshProducts();
      } catch (e) {
        _showErrorSnackBar('Failed to delete product: ${e.toString()}');
      }
    }
  }
}