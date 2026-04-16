import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/financial_service.dart';
import '../../services/inventory_service.dart';
import '../../services/notification_service.dart';
import 'order_tracking_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String vehicleName;
  final String locationName;
  final String fuelType;
  final String quantity;
  final String amount;
  final String subtotal;
  final String discount;
  final String? couponCode;
  final String? discountId;
  final bool useWallet;
  final double latitude;
  final double longitude;
  final String? vehicleId;
  final DateTime scheduledDate;
  final String scheduledTimeSlot;
  final String? notes;
  final double? serviceFee;

  const OrderSummaryScreen({
    super.key,
    required this.vehicleName,
    required this.locationName,
    required this.fuelType,
    required this.quantity,
    required this.amount,
    required this.subtotal,
    required this.discount,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    required this.latitude,
    required this.longitude,
    this.couponCode,
    this.discountId,
    this.useWallet = false,
    this.vehicleId,
    this.notes,
    this.serviceFee,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
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
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Order Summary',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Fuel Details Card
            _buildSummaryCard(
              title: 'Fuel Details',
              icon: Icons.local_gas_station_rounded,
              iconColor: const Color(0xFFFF6600),
              iconBgColor: const Color(0xFFFFECE0),
              children: [
                _buildInfoRow('Fuel Type', widget.fuelType),
                _buildInfoRow(
                  'Subtotal',
                  widget.subtotal,
                ),
                if (widget.couponCode != null)
                  _buildInfoRow(
                    'Discount (${widget.couponCode})',
                    '- ${widget.discount}',
                    valueColor: Colors.green,
                  ),
                _buildInfoRow('Est. Quantity', widget.quantity),
                const Divider(height: 32),
                _buildInfoRow('Total Due', widget.amount, isBold: true),
              ],
            ),
            const SizedBox(height: 24),

            // Delivery Details Card
            _buildSummaryCard(
              title: 'Delivery Details',
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF2F80ED),
              iconBgColor: const Color(0xFFE8F1FF),
              children: [
                _buildDeliveryInfoRow(
                  icon: Icons.directions_car_outlined,
                  title: 'Vehicle',
                  value: widget.vehicleName,
                  subtitle: 'Primary Vehicle',
                ),
                const SizedBox(height: 16),
                _buildDeliveryInfoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  value: widget.locationName,
                  subtitle: 'Selected Delivery Spot',
                ),
                const SizedBox(height: 16),
                _buildDeliveryInfoRow(
                  icon: Icons.access_time_outlined,
                  title: 'Scheduled Time',
                  value: '${['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][widget.scheduledDate.month]} ${widget.scheduledDate.day}, ${widget.scheduledDate.year}',
                  subtitle: widget.scheduledTimeSlot,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Summary Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.payment_rounded,
                        color: Color(0xFFFF6600),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    'Subtotal',
                    widget.subtotal,
                  ),
                  if (widget.serviceFee != null && widget.serviceFee! > 0)
                    _buildInfoRow(
                      'Delivery Fee',
                      '+\$${widget.serviceFee!.toStringAsFixed(2)}',
                      valueColor: const Color(0xFFFF6600),
                    ),
                  if (widget.couponCode != null)
                    _buildInfoRow(
                      'Discount (${widget.couponCode})',
                      '- ${widget.discount}',
                      valueColor: Colors.green,
                    ),
                  _buildInfoRow(
                    'Points to Earn',
                    '+${(double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0).floor()} pts',
                    valueColor: const Color(0xFFFF6600),
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Due Today',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        widget.amount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Color(0xFFFF6600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.useWallet ? const Color(0xFFE3F2FD) : const Color(0xFF2F80ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                          widget.useWallet ? Icons.account_balance_wallet : Icons.credit_card,
                        color: widget.useWallet ? const Color(0xFF2196F3) : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.useWallet ? 'Fuel Wallet' : '•••• 4242',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          widget.useWallet ? 'Available Balance' : 'DEFAULT METHOD',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : () async {
              final user = AuthService.currentUser;
              if (user != null) {
                setState(() => _isPlacingOrder = true);
                try {
                  // Parsing values from string (e.g. "$45.00" -> 45.0)
                  double total = double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                  double qty = double.tryParse(widget.quantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

                  // WALLET DEDUCTION
                  if (widget.useWallet) {
                    await FinancialService.processWalletTransaction(
                      userId: user.id,
                      amount: total,
                      type: 'PAYMENT',
                      description: 'Fuel Order Payment',
                    );
                  }

                  // DISCOUNT USAGE INCREMENT
                  if (widget.discountId != null) {
                    await InventoryService.applyDiscountUsage(widget.discountId!);
                  }

                  final order = await OrderService.createOrder(
                    userId: user.id,
                    fuelType: widget.fuelType,
                    quantity: qty,
                    totalPrice: total,
                    address: widget.locationName,
                    lat: widget.latitude,
                    lng: widget.longitude,
                    scheduledTime: widget.scheduledDate,
                    vehicleId: widget.vehicleId,
                    discountId: widget.discountId,
                  );

                  if (!context.mounted) return;
                  if (order != null) {
                    // ── NOTIFICATION: Order Placed ──
                    NotificationService().showNotification(
                      id: 1000,
                      title: '📦 Order Placed!',
                      body: 'Your fuel order is confirmed. A driver is being assigned.',
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(
                          orderId: order['id'],
                        ),
                      ),
                      (route) => route.isFirst,
                    );
                  } else {
                    setState(() => _isPlacingOrder = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to place order. No drivers available in your area.'), backgroundColor: Colors.red),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  setState(() => _isPlacingOrder = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isPlacingOrder 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Place Order - ${widget.amount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.check, size: 20),
                ],
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? const Color(0xFF333333) : const Color(0xFFAAAAAA),
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF333333),
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoRow({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFAAAAAA), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? const Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
