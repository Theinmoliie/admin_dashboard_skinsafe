import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../models/product.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final List<String> productTypes; // Receive the list of types
  final Function(Product) onSubmit;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.productTypes,
    required this.onSubmit,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;

  // State for the dropdown
  String? _selectedProductType;
  // State for allowing a new, custom type
  final TextEditingController _newTypeController = TextEditingController();
  bool _isNewType = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.productName ?? '');
    _brandController = TextEditingController(text: widget.product?.brand ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: widget.product?.productDescription ?? '');

    // Set the initial dropdown value
    if (widget.product != null && widget.productTypes.contains(widget.product!.productType)) {
      _selectedProductType = widget.product!.productType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _newTypeController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // Trigger validation on all fields
    if (!_formKey.currentState!.validate()) {
      return; // If validation fails, do not proceed
    }
    
    // Determine the final product type
    String finalProductType;
    if (_isNewType) {
      finalProductType = _newTypeController.text.trim();
    } else {
      finalProductType = _selectedProductType!;
    }

    final submittedProduct = Product(
      productId: widget.product?.productId,
      productName: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      productType: finalProductType,
      price: toNumericString(_priceController.text, allowPeriod: true) != null
          ? double.parse(toNumericString(_priceController.text, allowPeriod: true)!)
          : 0.0,
      imageUrl: _imageUrlController.text.trim(),
      productDescription: _descriptionController.text.trim(),
    );
    widget.onSubmit(submittedProduct);
    Navigator.of(context).pop();
  }
  
  // --- VALIDATOR FUNCTIONS ---

  String? _validateNonEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an image URL.';
    }
    // Use a regular expression to check for a valid URL format
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAbsolutePath || !uri.hasScheme) {
      return 'Please enter a valid URL (e.g., https://example.com/image.png)';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a price.';
    }
    final numericValue = toNumericString(value, allowPeriod: true);
    if (numericValue == null || double.tryParse(numericValue) == null) {
      return 'Please enter a valid number.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add New Product' : 'Edit Product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name'), validator: _validateNonEmpty, autovalidateMode: AutovalidateMode.onUserInteraction),
              const SizedBox(height: 12),
              TextFormField(controller: _brandController, decoration: const InputDecoration(labelText: 'Brand'), validator: _validateNonEmpty, autovalidateMode: AutovalidateMode.onUserInteraction),
              const SizedBox(height: 12),
              
              // --- DROPDOWN FOR PRODUCT TYPE ---
              if (!_isNewType)
                DropdownButtonFormField<String>(
                  value: _selectedProductType,
                  hint: const Text('Select a Product Type'),
                  items: [
                    ...widget.productTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                    const DropdownMenuItem(value: '---new---', child: Text('Add New Type...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue))),
                  ],
                  onChanged: (value) {
                    if (value == '---new---') {
                      setState(() { _isNewType = true; _selectedProductType = null; });
                    } else {
                      setState(() { _selectedProductType = value; });
                    }
                  },
                  validator: (value) => value == null ? 'Please select a type.' : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              
              // --- TEXT FIELD FOR NEW TYPE ---
              if (_isNewType)
                TextFormField(
                  controller: _newTypeController,
                  decoration: InputDecoration(
                    labelText: 'New Product Type',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _isNewType = false),
                    )
                  ),
                  validator: _validateNonEmpty,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price', prefixText: '\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validatePrice,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                // Ensures XX.XX format
                inputFormatters: [
                  MoneyInputFormatter(
                    thousandSeparator: ThousandSeparator.None,
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL'), validator: _validateUrl, autovalidateMode: AutovalidateMode.onUserInteraction, keyboardType: TextInputType.url),
              const SizedBox(height: 12),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Product Description'), maxLines: 4, validator: _validateNonEmpty, autovalidateMode: AutovalidateMode.onUserInteraction),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submitForm, child: const Text('Save')),
      ],
    );
  }
}