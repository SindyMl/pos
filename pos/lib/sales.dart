import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../utils/constants.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();
  final List<Map<String, dynamic>> _cartItems = [];
  double _taxRate = 15.5; // Default tax rate
  double _discount = 0.0; // Manual discount
  bool _showKeypad = false;
  bool _isCardPayment = false;

  @override
  void initState() {
    super.initState();
    _loadTaxRate();
    _loadDiscount();
  }

  // Load tax rate from settings/tax
  Future<void> _loadTaxRate() async {
    try {
      final doc = await _firestore.collection('settings').doc('tax').get();
      if (doc.exists) {
        setState(() {
          _taxRate = (doc.data()!['rate'] as num?)?.toDouble() ?? 15.5;
        });
      }
    } catch (e) {
      debugPrint('Error loading tax rate: $e');
    }
  }

  // Load discount from settings/discount
  Future<void> _loadDiscount() async {
    try {
      final doc = await _firestore.collection('settings').doc('discount').get();
      if (doc.exists) {
        setState(() {
          _discount = (doc.data()!['value'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error loading discount: $e');
    }
  }

  // Scan barcode or manual entry
  Future<void> _scanBarcode() async {
    try {
      String barcode = await FlutterBarcodeScanner.scanBarcode(
        '#EF5350', // Cancel button color (Red)
        'Cancel',
        true, // Show flash
        ScanMode.BARCODE,
      );
      if (barcode != '-1') {
        // -1 means scan cancelled
        _barcodeController.text = barcode;
        await _addItemToCart(barcode);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan failed: $e',
            style: const TextStyle(color: Color(0xFFEF5350)),
          ),
        ),
      );
    }
  }

  // Add item to cart by barcode or SKU
  Future<void> _addItemToCart(String input) async {
    try {
      final query =
          await _firestore
              .collection('inventory')
              .where('barcode', isEqualTo: input)
              .get();
      final queryBySku =
          await _firestore
              .collection('inventory')
              .where('sku', isEqualTo: input)
              .get();
      final itemDoc =
          query.docs.isNotEmpty
              ? query.docs.first
              : queryBySku.docs.isNotEmpty
              ? queryBySku.docs.first
              : null;
      if (itemDoc != null) {
        final item = itemDoc.data();
        setState(() {
          final existingItem = _cartItems.firstWhere(
            (i) => i['sku'] == item['sku'],
            orElse: () => {},
          );
          if (existingItem.isNotEmpty) {
            existingItem['quantity'] += 1;
          } else {
            _cartItems.add({
              'sku': item['sku'],
              'name': item['name'],
              'price': item['price']?.toDouble() ?? 0.0,
              'quantity': 1,
            });
          }
        });
        _barcodeController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Item not found',
              style: TextStyle(color: Color(0xFFEF5350)),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error adding item',
            style: TextStyle(color: Color(0xFFEF5350)),
          ),
        ),
      );
    }
  }

  // Calculate totals
  double get _subtotal => _cartItems.fold(
    0.0,
    (sum, item) => sum + (item['price'] * item['quantity']),
  );
  double get _tax => _subtotal * (_taxRate / 100);
  double get _total => _subtotal + _tax - _discount;

  // Delete item from cart
  void _deleteItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  // Clear cart
  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _discount = 0.0;
      _loadDiscount();
      _cashController.clear();
      _showKeypad = false;
      _isCardPayment = false;
    });
  }

  // Process cash payment
  void _processCashPayment() {
    setState(() {
      _showKeypad = true;
      _isCardPayment = false;
    });
  }

  // Process card payment
  void _processCardPayment() {
    setState(() {
      _showKeypad = false;
      _isCardPayment = true;
    });
  }

  // Complete sale and save to Firestore
  Future<void> _completeSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cart is empty',
            style: TextStyle(color: Color(0xFFEF5350)),
          ),
        ),
      );
      return;
    }
    try {
      await _firestore.collection('sales').add({
        'total': _total,
        'timestamp': Timestamp.now(),
        'status': 'completed',
        'items': _cartItems,
        'paymentType': _isCardPayment ? 'card' : 'cash',
      });
      setState(() {
        _cartItems.clear();
        _discount = 0.0;
        _loadDiscount();
        _cashController.clear();
        _showKeypad = false;
        _isCardPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sale completed',
            style: TextStyle(color: Color(0xFF4CAF50)),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error saving sale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving sale: $e',
            style: const TextStyle(color: Color(0xFFEF5350)),
          ),
        ),
      );
    }
  }

  // Autocomplete suggestions for TextField
  Future<List<String>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];
    try {
      final barcodeQuery =
          await _firestore
              .collection('inventory')
              .where('barcode', isGreaterThanOrEqualTo: query)
              .where('barcode', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(5)
              .get();
      final skuQuery =
          await _firestore
              .collection('inventory')
              .where('sku', isGreaterThanOrEqualTo: query)
              .where('sku', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(5)
              .get();
      return [
        ...barcodeQuery.docs.map((doc) => doc['barcode'] as String),
        ...skuQuery.docs.map((doc) => doc['sku'] as String),
      ].toSet().toList();
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light Gray
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A), // Teal
        title: const Text('New Sale', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {},
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFFFFB300), // Amber
                    child: Text(
                      _cartItems.length.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Items List and Scan/Entry
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item List
                  Container(
                    height: 400, // Increased height for better visibility
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        _cartItems.isEmpty
                            ? const Center(
                              child: Text(
                                'Cart is empty',
                                style: TextStyle(color: Color(0xFF424242)),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _cartItems.length,
                              itemBuilder: (context, index) {
                                final item = _cartItems[index];
                                final subtotal =
                                    item['price'] * item['quantity'];
                                return ListTile(
                                  title: Text(
                                    item['name'],
                                    style: const TextStyle(
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Qty: ${item['quantity']} | Price: R${item['price'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'R${subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF424242),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Color(0xFFEF5350), // Red
                                        ),
                                        onPressed: () => _deleteItem(index),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                  // Scan/Manual Entry
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Autocomplete<String>(
                      optionsBuilder: (
                        TextEditingValue textEditingValue,
                      ) async {
                        return await _getSuggestions(textEditingValue.text);
                      },
                      onSelected: (String selection) {
                        _barcodeController.text = selection;
                        _addItemToCart(selection);
                      },
                      fieldViewBuilder: (
                        context,
                        controller,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        _barcodeController.addListener(() {
                          controller.text = _barcodeController.text;
                        });
                        return TextField(
                          controller: _barcodeController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Enter barcode or SKU',
                            hintStyle: const TextStyle(
                              color: Color(0xFF424242),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF424242),
                              ),
                              onPressed: () => _barcodeController.clear(),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          style: const TextStyle(color: Color(0xFF424242)),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _addItemToCart(value);
                            }
                            onFieldSubmitted();
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A), // Teal
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _scanBarcode,
                      child: const Text(
                        'Scan Barcode',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right Side: Keypad, Totals, and Payment
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Numeric Keypad (Upper Right)
                  if (_showKeypad)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width:
                            MediaQuery.of(context).size.width /
                            3, // 1/3 screen width
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5), // Light Gray
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.2,
                          mainAxisSpacing: 10.0,
                          crossAxisSpacing: 10.0,
                          children: [
                            // Numbers 1-9
                            for (var i = 1; i <= 9; i++)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFFFFB300,
                                  ), // Amber
                                  foregroundColor: const Color(
                                    0xFF424242,
                                  ), // Dark Gray text
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: const BorderSide(
                                      color: Color(0xFF26A69A),
                                    ), // Teal border
                                  ),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                onPressed: () {
                                  _cashController.text += i.toString();
                                  setState(() {});
                                },
                                child: Text(
                                  '$i',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            // Decimal Point
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFFB300,
                                ), // Amber
                                foregroundColor: const Color(
                                  0xFF424242,
                                ), // Dark Gray text
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: const BorderSide(
                                    color: Color(0xFF26A69A),
                                  ), // Teal border
                                ),
                                padding: const EdgeInsets.all(12.0),
                              ),
                              onPressed: () {
                                if (!_cashController.text.contains('.')) {
                                  _cashController.text += '.';
                                  setState(() {});
                                }
                              },
                              child: const Text(
                                '.',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Number 0
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFFB300,
                                ), // Amber
                                foregroundColor: const Color(
                                  0xFF424242,
                                ), // Dark Gray text
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: const BorderSide(
                                    color: Color(0xFF26A69A),
                                  ), // Teal border
                                ),
                                padding: const EdgeInsets.all(12.0),
                              ),
                              onPressed: () {
                                _cashController.text += '0';
                                setState(() {});
                              },
                              child: const Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Backspace
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFFB300,
                                ), // Amber
                                foregroundColor: const Color(
                                  0xFF424242,
                                ), // Dark Gray text
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: const BorderSide(
                                    color: Color(0xFF26A69A),
                                  ), // Teal border
                                ),
                                padding: const EdgeInsets.all(12.0),
                              ),
                              onPressed: () {
                                if (_cashController.text.isNotEmpty) {
                                  _cashController.text = _cashController.text
                                      .substring(
                                        0,
                                        _cashController.text.length - 1,
                                      );
                                  setState(() {});
                                }
                              },
                              child: const Icon(Icons.backspace, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Cash Tendered Field (below keypad when visible)
                  if (_showKeypad) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cash Tendered',
                          labelStyle: TextStyle(color: Color(0xFF424242)),
                          prefixText: 'R',
                          prefixStyle: TextStyle(color: Color(0xFF424242)),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(color: Color(0xFF424242)),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Change: R${(_cashController.text.isNotEmpty ? (double.tryParse(_cashController.text) ?? 0.0) - _total : 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          color:
                              (double.tryParse(_cashController.text) ?? 0.0) >=
                                      _total
                                  ? const Color(0xFF4CAF50) // Green
                                  : const Color(0xFFEF5350), // Red
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  // Total Section
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Subtotal: R${_subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color:
                                _subtotal > 0
                                    ? const Color(0xFF4CAF50) // Green
                                    : const Color(0xFFEF5350), // Red
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Tax ($_taxRate%): R${_tax.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF424242),
                          ),
                        ),
                        Text(
                          'Discount: -R${_discount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF424242),
                          ),
                        ),
                        Text(
                          'Total: R${_total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                _total >= 0
                                    ? const Color(0xFF4CAF50) // Green
                                    : const Color(0xFFEF5350), // Red
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Payment Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300), // Amber
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed:
                                _cartItems.isEmpty ? null : _processCashPayment,
                            child: const Text(
                              'Cash Payment',
                              style: TextStyle(color: Color(0xFF424242)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF26A69A), // Teal
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed:
                                _cartItems.isEmpty ? null : _processCardPayment,
                            child: const Text(
                              'Card Payment',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Card Payment Placeholder
                  if (_isCardPayment) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                size: 48,
                                color: Color(0xFF424242),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Card Payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424242),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This feature will be connected to a banking API or Paystack in the future.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF424242)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350), // Red
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _cartItems.isEmpty ? null : _clearCart,
              child: const Text(
                'Clear Cart',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // Green
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed:
                  _cartItems.isEmpty
                      ? null
                      : () {
                        if (_isCardPayment) {
                          _completeSale();
                        } else {
                          final cash =
                              double.tryParse(_cashController.text) ?? 0.0;
                          if (cash >= _total) {
                            _completeSale();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Insufficient cash',
                                  style: TextStyle(color: Color(0xFFEF5350)),
                                ),
                              ),
                            );
                          }
                        }
                      },
              child: const Text(
                'Complete Sale',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _cashController.dispose();
    super.dispose();
  }
}
