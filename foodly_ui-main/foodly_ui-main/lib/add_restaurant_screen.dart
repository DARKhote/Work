import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  _AddRestaurantScreenState createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _cuisineType = '';
  String _address = '';
  String _imageUrl = ''; // Added for image URL
  double _rating = 0.0; // Added for rating

  // To manage focus
  final FocusNode _cuisineFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _imageUrlFocusNode = FocusNode();
  final FocusNode _ratingFocusNode = FocusNode();


  @override
  void dispose() {
    // Clean up the focus nodes when the form is disposed.
    _cuisineFocusNode.dispose();
    _addressFocusNode.dispose();
    _imageUrlFocusNode.dispose();
    _ratingFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addRestaurant() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // This will trigger onSaved for each TextFormField
      try {
        // Get a reference to the Firestore collection
        CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');

        // Add a new document with a generated ID
        await restaurants.add({
          'name': _name,
          'cuisineType': _cuisineType,
          'address': _address,
          'imageUrl': _imageUrl.isNotEmpty ? _imageUrl : 'https://via.placeholder.com/150?text=No+Image', // Default placeholder if empty
          'rating': _rating,
          'deliveryTimeEstimate': '25-35 min', // Example static value
          'createdAt': Timestamp.now(), // Good practice to add a timestamp
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant Added Successfully!')),
        );
        _formKey.currentState!.reset(); // Reset form after submission
        setState(() { // Reset local state variables if needed after form reset
          _name = '';
          _cuisineType = '';
          _address = '';
          _imageUrl = '';
          _rating = 0.0;
        });
      } catch (e) {
        var kDebugMode = true ;
        if (kDebugMode) {
          print('Error adding restaurant: $e');
        } // Log the error for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add restaurant. See console for details.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Restaurant'),
      ),
      body: SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Restaurant Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the restaurant name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                  textInputAction: TextInputAction.next, // For keyboard action
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_cuisineFocusNode);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Cuisine Type (e.g., Italian, Chinese)'),
                  focusNode: _cuisineFocusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the cuisine type';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _cuisineType = value!;
                  },
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_addressFocusNode);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Address'),
                  focusNode: _addressFocusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the address';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _address = value!;
                  },
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_imageUrlFocusNode);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Image URL (Optional)'),
                  focusNode: _imageUrlFocusNode,
                  keyboardType: TextInputType.url,
                  onSaved: (value) {
                    _imageUrl = value ?? ''; // Handle null case
                  },
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_ratingFocusNode);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Rating (0.0 - 5.0)'),
                  focusNode: _ratingFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a rating';
                    }
                    final n = double.tryParse(value);
                    if (n == null) {
                      return 'Please enter a valid number';
                    }
                    if (n < 0 || n > 5) {
                      return 'Rating must be between 0.0 and 5.0';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _rating = double.parse(value!);
                  },
                  textInputAction: TextInputAction.done, // Last field
                  onFieldSubmitted: (_) {
                    _addRestaurant(); // Submit form on "done"
                  },
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _addRestaurant,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0)
                  ),
                  child: const Text('Add Restaurant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}