//dashboard_screen.dart

import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../widgets/product_form_dialog.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  List<Product>? _products;
  String? _error;
  bool _isLoading = true;
  List<String> _productTypes = [];
  int _currentPage = 0;
  final int _pageSize = 100;
  bool _canLoadNextPage = true;

  // --- NEW: SEARCH STATE ---
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Fetch initial data when the screen loads
    _fetchInitialData();
    
    // Add a listener to the search controller to trigger search on text change
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel(); // Cancel any active timer
    super.dispose();
  }

  /// Called whenever the search text field changes
  void _onSearchChanged() {
    // Debounce the search to avoid querying on every keystroke
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // After 500ms of no typing, fetch the first page with the new search term
      _fetchProductsForPage(0, searchTerm: _searchController.text.trim());
    });
  }

  Future<void> _fetchInitialData() async {
    // Run both fetches in parallel for efficiency
    await Future.wait([
      _fetchProductsForPage(0),
      _fetchDistinctProductTypes(),
    ]);
  }


 /// --- CORRECTED: Fetches distinct product types for the dropdown ---
  Future<void> _fetchDistinctProductTypes() async {
    try {
      // Call the SQL function we created.
      final response = await _supabase.rpc('get_distinct_product_types');
      
      if (response is List) {
        // *** THE FIX: Use the correct, lowercase key returned by the function ***
        final types = response
            .map((item) => item['product_type_name'].toString())
            .toList();
            
        // Sort the list one more time in Dart as a safeguard.
        types.sort();
        
        setState(() {
          _productTypes = types;
        });
      }
    } on PostgrestException catch (e) {
      // This will now provide a much clearer error if something is still wrong
      _showErrorSnackBar('Could not fetch product types. DB Error: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Could not fetch product types: ${e.toString()}');
    }
  }


   /// --- MODIFIED: Now accepts an optional searchTerm ---
  Future<void> _fetchProductsForPage(int page, {String searchTerm = ''}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final from = page * _pageSize;
      final to = from + _pageSize - 1;

      const selectQuery = 'Product_Id, Product_Name, Product_Type, Brand, Image_Url, Price, Product_Description';
      
      // Start building the query
      var query = _supabase
          .from('Products')
          .select(selectQuery);
      
      // --- NEW: Add search filter if a search term is provided ---
      if (searchTerm.isNotEmpty) {
        // Use 'or' filter to search in both Product_Name and Brand columns
        // '.ilike.%$searchTerm%' performs a case-insensitive "contains" search
        query = query.or('Product_Name.ilike.%$searchTerm%,Brand.ilike.%$searchTerm%');
      }

      // Add the ordering and pagination at the end
      final response = await query
          .order('Product_Id', ascending: false)
          .range(from, to);

      final newProducts = response.map((item) => Product.fromMap(item)).toList();
      
      setState(() {
        _products = newProducts;
        _isLoading = false;
        _currentPage = page;
        _canLoadNextPage = newProducts.length == _pageSize;
      });
    } on PostgrestException catch (e) {
      setState(() { _error = "Database Error: ${e.message}"; _isLoading = false; });
    } catch (e) {
      setState(() { _error = "An unexpected error occurred: $e"; _isLoading = false; });
    }
  }
  
  void _clearSearch() {
    _searchController.clear();
    // No need to call _fetchProductsForPage here, the listener will handle it.
  }

  void _refreshCurrentPage() {
    _fetchProductsForPage(_currentPage, searchTerm: _searchController.text.trim());
  }

  void _refreshAndGoToFirstPage() {
    _fetchProductsForPage(0, searchTerm: _searchController.text.trim());
  }

   // --- NEW: LOGOUT FUNCTION ---
  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      _showErrorSnackBar('Logout failed: ${e.toString()}');
    }

    // After signing out, the AuthGuard in main.dart will automatically
    // redirect to the LoginScreen. We add this for immediate navigation.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _refreshCurrentPage,
          ),
           // --- NEW: LOGOUT BUTTON ---
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _buildBody(), // The body is now built from state variables
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Builds the main content area based on the current state.
Widget _buildBody() {
    return Column(
     crossAxisAlignment: CrossAxisAlignment.end, // Align children to the start (left)
      children: [
        // --- MODIFIED: SEARCH BAR WIDGET ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // Adjusted padding
          child: SizedBox(
            width: 350, // Give the search bar a specific width
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Product Name or Brand',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: const OutlineInputBorder(),
                // Make the text field smaller and denser
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
        ),

        // A separator to give some space
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Divider(),
        ),

        // --- The rest of the body depends on the state ---
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center))))
        else if (_products == null || _products!.isEmpty)
          Expanded(child: Center(child: Text(_searchController.text.isNotEmpty ? 'No products found for your search.' : 'No products found. Click + to add one.')))
        else
        Expanded(
          child: Center(
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
                    DataColumn(label: Text('Image_Url', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _products!.map((product) {
                    return DataRow(cells: [
                      DataCell(SizedBox(width: 300, child: Text(product.productName, overflow: TextOverflow.ellipsis)), onTap: () => _showProductDialog(product: product)),
                      DataCell(Text(product.brand)),
                      DataCell(Text(product.productType)),
                      DataCell(Text(NumberFormat.currency(symbol: '\$').format(product.price))),
                       
                       // --- THIS IS THE FIX ---
                      // Wrap the Text widget in a SizedBox and add overflow ellipsis
                      DataCell(
                        SizedBox(
                          width: 200, // Give it a max width to know when to truncate
                          child: Text(
                            product.imageUrl, // The URL string
                            overflow: TextOverflow.ellipsis, // The magic property
                            softWrap: false, // Prevents wrapping to a new line
                          ),
                        ),
                      ),
                      // --- END OF FIX ---

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
          ),
        ),

        // --- PAGINATION CONTROLS WIDGET ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_double_arrow_left),
                tooltip: 'First Page',
                onPressed: _currentPage == 0 ? null : _refreshAndGoToFirstPage,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_left),
                tooltip: 'Previous Page',
                onPressed: _currentPage == 0 ? null : () {
                  _fetchProductsForPage(_currentPage - 1);
                },
              ),
              const SizedBox(width: 24),
              Text('Page ${_currentPage + 1}'),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_right),
                tooltip: 'Next Page',
                onPressed: !_canLoadNextPage ? null : () {
                  _fetchProductsForPage(_currentPage + 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }


  // --- CRUD HELPER METHODS ---

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

   // --- NEW: SUCCESS SNACKBAR METHOD ---
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  
// --- UPDATED: Pass the types list to the dialog ---
  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing on outside click
      builder: (context) {
        return ProductFormDialog(
          product: product,
          productTypes: _productTypes, // Pass the fetched types
          onSubmit: _handleProductSubmission,
        );
      },
    );
  }

  Future<void> _handleProductSubmission(Product product) async {
    try {
      if (product.productId == null) {
        // After adding a new product, go to the first page to see it.
        await _supabase.from('Products').insert(product.toMap());
        _showSuccessSnackBar('Product successfully added!'); // <-- SUCCESS MESSAGE
        _refreshAndGoToFirstPage();
      } else {
        // After updating, just refresh the current page.
        await _supabase.from('Products').update(product.toMap()).eq('Product_Id', product.productId!);
        _showSuccessSnackBar('Product successfully updated!'); // <-- SUCCESS MESSAGE

        _refreshCurrentPage();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save product: ${e.toString()}');
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ),
    );
    if (shouldDelete == true) {
      try {
        await _supabase.from('Products').delete().eq('Product_Id', productId);
        _showSuccessSnackBar('Product successfully deleted!'); // <-- SUCCESS MESSAGE

        // After deleting, refresh the current page.
        // If it was the last item on the page, the user may need to go to the previous page.
        // For simplicity, we just refresh. A more advanced implementation could handle this edge case.
        _refreshCurrentPage();
      } catch (e) {
        _showErrorSnackBar('Failed to delete product: ${e.toString()}');
      }
    }
  }
}