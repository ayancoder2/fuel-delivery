import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';

import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/receipt_service.dart';

class DeliveryCompleteScreen extends StatefulWidget {
  final Map<String, dynamic>? orderData;

  const DeliveryCompleteScreen({
    super.key,
    this.orderData,
  });

  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> {
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    // Extract dynamic data or provide defaults
    final String quantity = widget.orderData?['quantity']?.toString() ?? '---';
    final String fuelType = widget.orderData?['fuel_type'] ?? 'Fuel';
    final String address = widget.orderData?['delivery_address'] ?? 'Unknown location';
    final double totalPrice = (widget.orderData?['total_price'] ?? 0.0).toDouble();
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Delivery Complete',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Success Animation / Icon
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sunburst / Dotted Circle
                    ...List.generate(8, (index) {
                      return RotationTransition(
                        turns: AlwaysStoppedAnimation(index / 8),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 12,
                            width: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Inner Circle with Check
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF4CAF50), width: 4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          color: Color(0xFF4CAF50),
                          size: 60,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Delivery Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'All set! Your fuel has been delivered to your Location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Order Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FUEL TYPE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF999999),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$quantity Gallons',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fuelType,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF9F9F9), thickness: 1.5),
                    const SizedBox(height: 20),
                    
                    // Location
                    _buildDetailRow(
                      icon: Icons.location_on,
                      title: 'Delivery Location',
                      value: address,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Payment
                    _buildDetailRow(
                      icon: Icons.location_on, // Reusing pin icon as seen in screenshot
                      title: 'PAYMENT',
                      value: 'Card/Wallet • Total \$${totalPrice.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Rate your experience',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_outline,
                        color: index < _rating ? const Color(0xFFFF6600) : const Color(0xFFCCCCCC),
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.orderData != null) {
                    ReceiptService.generateAndOpenReceipt(widget.orderData!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No order data found to generate receipt.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.description_outlined, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Download Receipt',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: _isSubmitting ? null : () async {
                  if (_rating > 0 && widget.orderData != null) {
                    setState(() => _isSubmitting = true);
                    final user = AuthService.currentUser;
                    if (user != null) {
                      await OrderService.submitReview(
                        orderId: widget.orderData!['id'],
                        userId: user.id,
                        rating: _rating.toDouble(),
                        feedback: '',
                      );
                    }
                  }
                  
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEEEEEE),
                  foregroundColor: const Color(0xFFFF6600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFFFF6600), strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.home_outlined, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Submit & Go Home',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFF6600), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
