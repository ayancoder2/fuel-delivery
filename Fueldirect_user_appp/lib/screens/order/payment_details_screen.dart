import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/financial_service.dart';
import '../../services/inventory_service.dart';
import '../profile/payments_screen.dart';
import 'select_location_screen.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String vehicleName;
  final String locationName;
  final String fuelType;
  final String quantity;
  final String amount;
  final String? vehicleId;
  final double latitude;
  final double longitude;
  final DateTime scheduledDate;
  final String scheduledTimeSlot;

  const PaymentDetailsScreen({
    super.key,
    required this.vehicleName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.fuelType,
    required this.quantity,
    required this.amount,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    this.vehicleId,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> _paymentMethods = [];
  Map<String, dynamic>? _selectedPaymentMethod;
  bool _isLoadingPayments = true;
  double _walletBalance = 0.0;
  bool _useWallet = false;
  bool _isValidatingCoupon = false;
  Map<String, dynamic>? _appliedCoupon;
  double _discountedTotal = 0.0;
  double _subtotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final methods = await FinancialService.getPaymentMethods(user.id);
      final wallet = await FinancialService.getWalletInfo(user.id);
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _walletBalance = (wallet?['wallet_balance'] ?? 0.0).toDouble();
          if (methods.isNotEmpty) {
            _selectedPaymentMethod = methods.firstWhere(
              (m) => m['is_default'] == true,
              orElse: () => methods.first,
            );
          }
          _isLoadingPayments = false;
          _subtotal = double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          _discountedTotal = _subtotal;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingPayments = false;
          _subtotal = double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          _discountedTotal = _subtotal;
        });
      }
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);

    final discountData = await InventoryService.validateDiscount(code);

    if (mounted) {
      setState(() {
        _isValidatingCoupon = false;
        if (discountData != null) {
          final double minSpend = (discountData['min_order_amount'] as num?)?.toDouble() ?? 0.0;
          
          if (_subtotal < minSpend) {
            _appliedCoupon = null;
            _discountedTotal = _subtotal;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Minimum order amount for this discount is \$${minSpend.toStringAsFixed(2)}'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          _appliedCoupon = discountData;
          double discountAmount = 0.0;
          final String type = discountData['discount_type'] ?? 'FIXED';
          final double value = (discountData['discount_value'] as num).toDouble();

          if (type == 'PERCENTAGE') {
            discountAmount = _subtotal * (value / 100);
            final double? maxDiscount = (discountData['max_discount_amount'] as num?)?.toDouble();
            if (maxDiscount != null && discountAmount > maxDiscount) {
              discountAmount = maxDiscount;
            }
          } else {
            discountAmount = value;
          }

          _discountedTotal = (_subtotal - discountAmount).clamp(0.0, double.infinity);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discount applied!'), backgroundColor: Colors.green),
          );
        } else {
          _appliedCoupon = null;
          _discountedTotal = _subtotal;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid or expired discount code'), backgroundColor: Colors.red),
          );
        }
      });
    }
  }

  void _showPaymentSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_paymentMethods.isEmpty)
                  const Text('No saved payment methods. Please add one.', style: TextStyle(color: Colors.grey))
                else
                  ..._paymentMethods.map((method) {
                    final isSelected = _selectedPaymentMethod?['id'] == method['id'];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.credit_card,
                        color: method['card_type'] == 'Mastercard' ? const Color(0xFFEB001B) : const Color(0xFF1A1F71),
                      ),
                      title: Text('${method['card_type']} •••• ${method['last_4']}'),
                      subtitle: Text('Expires ${method['expiry_date']}'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFFFF6600))
                          : const Icon(Icons.circle_outlined, color: Colors.grey),
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF2196F3)),
                  title: const Text('Wallet Balance'),
                  subtitle: Text('\$${_walletBalance.toStringAsFixed(2)} available'),
                  trailing: _useWallet
                      ? const Icon(Icons.check_circle, color: Color(0xFFFF6600))
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () {
                    if (_walletBalance < _discountedTotal) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient wallet balance. Please top up.')),
                      );
                    } else {
                      setState(() {
                        _useWallet = true;
                        _selectedPaymentMethod = null;
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                      );
                      _loadPaymentMethods();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6600),
                      side: const BorderSide(color: Color(0xFFFF6600)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add / Manage Cards'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Details',
          style: TextStyle(
            color: Colors.black,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              // Payment Card
              GestureDetector(
                onTap: _isLoadingPayments ? null : _showPaymentSelectionSheet,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoadingPayments
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6600))))
                      : _useWallet
                          ? Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet, color: Color(0xFF2196F3), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Payment via Wallet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'AVAILABLE BALANCE: \$${_walletBalance.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                ],
                              )
                          : _selectedPaymentMethod == null
                              ? Row(
                                  children: [
                                    const Icon(Icons.add_circle_outline, color: Color(0xFFFF6600), size: 32),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Text('Add a Payment Method', style: TextStyle(fontSize: 16, color: Color(0xFF333333), fontWeight: FontWeight.bold)),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _selectedPaymentMethod!['card_type'] == 'Mastercard' ? const Color(0xFFEB001B) : const Color(0xFF1A1F71),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '•••• •••• •••• ${_selectedPaymentMethod!['last_4']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'EXPIRES ${_selectedPaymentMethod!['expiry_date']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                  ],
                                ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Have a Coupon?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.confirmation_num_outlined,
                            color: Color(0xFFFF6600),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter Coupon Code',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isValidatingCoupon ? null : _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6600),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isValidatingCoupon
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Add a Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add Note',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFEEEEEE))),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMATED TOTAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                        Row(
                        children: [
                          Text(
                            '\$${_discountedTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _appliedCoupon != null ? const Color(0xFFE8F5E9) : const Color(0xFFF1F1F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _appliedCoupon != null ? '${_appliedCoupon!['code']}' : 'NO PROMO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _appliedCoupon != null ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFFFF6600),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            // Helper to format: Mar 28, 2026
                            '${['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][widget.scheduledDate.month]} ${widget.scheduledDate.day}, ${widget.scheduledDate.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SelectLocationScreen(
                          vehicleName: widget.vehicleName,
                          locationName: widget.locationName,
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                          fuelType: widget.fuelType,
                          quantity: widget.quantity,
                          subtotal: '\$${_subtotal.toStringAsFixed(2)}',
                          discount: '\$${(_subtotal - _discountedTotal).toStringAsFixed(2)}',
                          amount: '\$${_discountedTotal.toStringAsFixed(2)}',
                          couponCode: _appliedCoupon != null ? _appliedCoupon!['code'] : null,
                          discountId: _appliedCoupon != null ? _appliedCoupon!['id'] : null,
                          vehicleId: widget.vehicleId,
                          useWallet: _useWallet,
                          scheduledDate: widget.scheduledDate,
                          scheduledTimeSlot: widget.scheduledTimeSlot,
                          notes: _noteController.text,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Confirm Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
