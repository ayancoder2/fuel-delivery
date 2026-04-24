import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/receipt_service.dart';
import '../../services/refund_service.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import 'order_summary_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _refundRequest;
  List<Map<String, dynamic>> _deliveryProofs = [];
  bool _isLoadingRefund = true;
  bool _isSubmittingRefund = false;
  bool _isLoadingProofs = false;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _checkRefundStatus();
    _loadDeliveryProofs();
  }

  Future<void> _checkRefundStatus() async {
    final refund = await RefundService.getRefundByOrder(widget.order['id']);
    if (mounted) {
      setState(() {
        _refundRequest = refund;
        _isLoadingRefund = false;
      });
    }
  }

  Future<void> _loadDeliveryProofs() async {
    if (widget.order['status'] == 'DELIVERED') {
      setState(() => _isLoadingProofs = true);
      try {
        final proofs = await DeliveryService.getDeliveryProofs(widget.order['id']);
        if (mounted) setState(() => _deliveryProofs = proofs);
      } catch (e) {
        debugPrint('Error loading proofs: $e');
      } finally {
        if (mounted) setState(() => _isLoadingProofs = false);
      }
    }
  }

  Future<void> _simulateDelivery() async {
    setState(() => _isSimulating = true);
    try {
      // 1. Upload a dummy proof (placeholder image)
      await DeliveryService.client.from('delivery_proofs').insert({
        'order_id': widget.order['id'],
        'photo_url': 'https://plus.unsplash.com/premium_photo-1661284828052-ea149b158c94?q=80&w=2670&auto=format&fit=crop',
        'caption': 'Simulated delivery success!',
      });

      // 2. Complete the order
      await client.from('orders').update({'status': 'DELIVERED'}).eq('id', widget.order['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery simulated successfully!'), backgroundColor: Colors.green),
        );
        // Refresh by popping and re-pushing or just modifying local state
        setState(() {
          widget.order['status'] = 'DELIVERED';
        });
        _loadDeliveryProofs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  void _showRefundDialog() {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Refund', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for your refund request:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Fuel was not delivered as expected',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              
              Navigator.pop(context);
              setState(() => _isSubmittingRefund = true);
              
              try {
                final user = AuthService.currentUser;
                final totalPrice = (widget.order['total_price'] ?? 0.0) is int 
                    ? (widget.order['total_price'] as int).toDouble() 
                    : (widget.order['total_price'] ?? 0.0);

                await RefundService.requestRefund(
                  orderId: widget.order['id'],
                  userId: user!.id,
                  amount: totalPrice,
                  reason: reason,
                );
                
                await _checkRefundStatus();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refund request submitted successfully!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              } finally {
                if (mounted) setState(() => _isSubmittingRefund = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final vehicle = order['vehicles'];
    final fuelType = order['fuel_type'] ?? 'Premium Diesel';
    final quantity = order['quantity'] ?? 0.0;
    final totalPrice = (order['total_price'] ?? 0.0) is int 
        ? (order['total_price'] as int).toDouble() 
        : (order['total_price'] ?? 0.0);
    final address = order['delivery_address'] ?? 'No address provided';
    final status = order['status'] ?? 'DELIVERED';
    final createdAt = order['created_at'] != null 
        ? DateTime.parse(order['created_at']).toLocal() 
        : DateTime.now();

    // Simulated helper for formatting
    String formatDate(DateTime date) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

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
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Delivery Location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Location',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF5F5F5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFECE0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Color(0xFFFF6600), size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle & Order Date Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      title: 'VEHICLE',
                      name: vehicle != null ? '${vehicle['make']} ${vehicle['model']}' : 'Unknown Vehicle',
                      subtitle: vehicle != null ? vehicle['license_plate'] : 'N/A',
                      icon: Icons.directions_car_filled_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      title: 'ORDER DATE',
                      name: formatDate(createdAt),
                      subtitle: status,
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cost Breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF5F5F5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cost Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 16),
                    _buildCostRow('Fuel ($fuelType, ${quantity}L)', 'Rs. ${totalPrice.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildCostRow('Delivery Fee', 'Rs. 0.00'),
                    const SizedBox(height: 12),
                    _buildCostRow('Service Fee', 'Rs. 0.00'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          'Rs. ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF6600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Download Receipt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          SizedBox(width: 16),
                          Text('Generating receipt PDF...'),
                        ],
                      ),
                      backgroundColor: Color(0xFFFF6600),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  try {
                    await ReceiptService.generateAndOpenReceipt(order);
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to generate receipt: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF5F5F5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECE0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF6600), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Download Receipt',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.file_download_outlined, color: Color(0xFF555555), size: 24),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const SizedBox(height: 24),

            // Proof of Delivery Section
            if (status == 'DELIVERED' && _deliveryProofs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proof of Delivery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _deliveryProofs.length,
                        itemBuilder: (context, index) {
                          final proof = _deliveryProofs[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(proof['photo_url']),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(150),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                ),
                                child: Text(
                                  proof['caption'] ?? 'Delivery Proof',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              )
            else if (status == 'DELIVERED' && _isLoadingProofs)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6600))),
              ),

            // Refund Request Section
            if (status == 'DELIVERED')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _isLoadingRefund 
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6600)))
                  : _refundRequest != null
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _refundRequest!['status'] == 'PENDING' ? Icons.timer_outlined : 
                                  _refundRequest!['status'] == 'APPROVED' ? Icons.check_circle_outline :
                                  _refundRequest!['status'] == 'REJECTED' ? Icons.cancel_outlined : Icons.account_balance_wallet_outlined,
                                  color: _refundRequest!['status'] == 'PENDING' ? Colors.orange : 
                                         _refundRequest!['status'] == 'APPROVED' ? Colors.green :
                                         _refundRequest!['status'] == 'REJECTED' ? Colors.red : Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Refund ${_refundRequest!['status']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _refundRequest!['status'] == 'PENDING' ? Colors.orange : 
                                           _refundRequest!['status'] == 'APPROVED' ? Colors.green :
                                           _refundRequest!['status'] == 'REJECTED' ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reason: ${_refundRequest!['reason']}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                            ),
                            if (_refundRequest!['admin_notes'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Admin Note: ${_refundRequest!['admin_notes']}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      )
                    : InkWell(
                        onTap: _isSubmittingRefund ? null : _showRefundDialog,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF5F5F5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.help_outline_rounded, color: Colors.blue, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need a Refund?',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    'Request a refund for this order',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (_isSubmittingRefund)
                                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
              ),

            if (status != 'DELIVERED' && status != 'CANCELLED')
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSimulating ? null : _simulateDelivery,
                    icon: _isSimulating 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.flash_on_rounded),
                    label: Text(_isSimulating ? 'Simulating...' : 'Simulate Delivery (Test Mode)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 120), // Space for button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderSummaryScreen(
                    vehicleName: vehicle != null ? '${vehicle['make']} ${vehicle['model']}' : 'Unknown Vehicle',
                    locationName: address,
                    fuelType: fuelType,
                    quantity: '${quantity}L',
                    amount: 'Rs. ${totalPrice.toStringAsFixed(2)}',
                    subtotal: 'Rs. ${totalPrice.toStringAsFixed(2)}',
                    discount: 'Rs. 0.00',
                    scheduledDate: DateTime.now(),
                    scheduledTimeSlot: '9:00 AM - 12:00 PM', // Default slot for re-order
                    latitude: order['latitude'] ?? 0.0,
                    longitude: order['longitude'] ?? 0.0,
                    vehicleId: order['vehicle_id'],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Order Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String name,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFFF6600), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
