import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final Function(Product) onSubmit;

  const ProductFormDialog({super.key, this.product, required this.onSubmit});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _brandController; // <-- ADD THIS LINE
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.productName ?? '');
    _typeController = TextEditingController(text: widget.product?.productType ?? '');
    _brandController = TextEditingController(text: widget.product?.brand ?? ''); // <-- ADD THIS LINE
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: widget.product?.productDescription ?? '');
  }

  @override
  void dispose() {
    // ... dispose other controllers
    _brandController.dispose(); // <-- ADD THIS LINE
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final submittedProduct = Product(
        productId: widget.product?.productId,
        productName: _nameController.text.trim(),
        productType: _typeController.text.trim(),
        brand: _brandController.text.trim(), // <-- ADD THIS LINE
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        imageUrl: _imageUrlController.text.trim(),
        productDescription: _descriptionController.text.trim(),
      );
      widget.onSubmit(submittedProduct);
      Navigator.of(context).pop();
    }
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
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _brandController, decoration: const InputDecoration(labelText: 'Brand'), validator: (v) => v!.trim().isEmpty ? 'Required' : null), // <-- ADD THIS WIDGET
              const SizedBox(height: 8),
              TextFormField(controller: _typeController, decoration: const InputDecoration(labelText: 'Product Type (e.g., Cleanser)'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Product Description'), maxLines: 4, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
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