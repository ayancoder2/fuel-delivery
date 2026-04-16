import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class SubscriptionCheckoutScreen extends StatefulWidget {
  final String planName;
  final int carCount;
  final double monthlyFee;

  const SubscriptionCheckoutScreen({
    super.key,
    required this.planName,
    required this.carCount,
    required this.monthlyFee,
  });

  @override
  State<SubscriptionCheckoutScreen> createState() =>
      _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState
    extends State<SubscriptionCheckoutScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  int _selectedPaymentIndex = 0;

  // Mock payment options (extend with real Stripe later)
  final List<Map<String, dynamic>> _paymentOptions = [
    {'type': 'card', 'label': '•••• 4242', 'sub': 'Visa · Expires 04/27'},
    {'type': 'wallet', 'label': 'Fuel Wallet', 'sub': 'Available balance'},
    {'type': 'cash', 'label': 'Pay on Delivery', 'sub': 'Cash / POS'},
  ];

  bool get _isElite => widget.planName == 'Family Elite';
  Color get _accentColor =>
      _isElite ? const Color(0xFF7B2FBE) : const Color(0xFFFF6600);

  Future<void> _processSubscription() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));

    final user = AuthService.currentUser;
    if (user != null && mounted) {
      try {
        await ProfileService.updateProfile(
          userId: user.id,
          subscriptionPlan: widget.planName,
        );
        if (!mounted) return;
        _showSuccessSheet();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _SuccessSheet(
        planName: widget.planName,
        carCount: widget.carCount,
        isElite: _isElite,
        onDone: () =>
            Navigator.of(ctx).popUntil((route) => route.isFirst),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Plan Summary Card ──
            _buildSectionLabel('Plan Summary'),
            const SizedBox(height: 12),
            _PlanSummaryCard(
              planName: widget.planName,
              carCount: widget.carCount,
              monthlyFee: widget.monthlyFee,
              isElite: _isElite,
              accentColor: _accentColor,
            ),
            const SizedBox(height: 28),

            // ── What's included ──
            _buildSectionLabel('What\'s Included'),
            const SizedBox(height: 12),
            _IncludedCard(
              isElite: _isElite,
              carCount: widget.carCount,
              accentColor: _accentColor,
            ),
            const SizedBox(height: 28),

            // ── Payment method ──
            _buildSectionLabel('Payment Method'),
            const SizedBox(height: 12),
            ..._paymentOptions.asMap().entries.map((entry) {
              final i = entry.key;
              final option = entry.value;
              return _PaymentOption(
                icon: _iconForType(option['type']),
                label: option['label'],
                subtitle: option['sub'],
                isSelected: _selectedPaymentIndex == i,
                accentColor: _accentColor,
                onTap: () =>
                    setState(() => _selectedPaymentIndex = i),
              );
            }),
            const SizedBox(height: 12),

            // Billing note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accentColor.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentColor.withAlpha(40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _accentColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You will be billed \$${widget.monthlyFee.toStringAsFixed(2)}/month. '
                      'Fuel gallons are billed separately at market price. Cancel anytime.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _accentColor.withAlpha(200),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
          border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Subscription',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 13)),
                  Text(
                    '\$${widget.monthlyFee.toStringAsFixed(2)}/mo',
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: _accentColor.withAlpha(120),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Subscribe Now',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF888888),
        letterSpacing: 1.0,
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'cash':
        return Icons.payments_outlined;
      default:
        return Icons.credit_card_rounded;
    }
  }
}

// ─────────────────────────────────────────────
// PLAN SUMMARY CARD
// ─────────────────────────────────────────────
class _PlanSummaryCard extends StatelessWidget {
  final String planName;
  final int carCount;
  final double monthlyFee;
  final bool isElite;
  final Color accentColor;

  const _PlanSummaryCard({
    required this.planName,
    required this.carCount,
    required this.monthlyFee,
    required this.isElite,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isElite
            ? const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isElite ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isElite
                      ? Colors.white.withAlpha(30)
                      : accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isElite
                      ? Icons.workspace_premium_rounded
                      : Icons.groups_rounded,
                  color: isElite ? Colors.white : accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName == 'Family Subscription'
                          ? 'FAMILY PLAN'
                          : 'FAMILY ELITE',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isElite ? Colors.white : const Color(0xFF1A1A2E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$carCount Car${carCount > 1 ? 's' : ''} · Monthly Billing',
                      style: TextStyle(
                        fontSize: 12,
                        color: isElite
                            ? Colors.white60
                            : const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly fee',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isElite ? Colors.white60 : const Color(0xFF888888),
                ),
              ),
              Text(
                '\$${monthlyFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isElite ? Colors.white : accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '+ Fuel gallons at market price',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isElite ? Colors.white38 : const Color(0xFFAAAAAA),
                ),
              ),
              Text(
                '/month',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isElite ? Colors.white38 : const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INCLUDED FEATURES CARD
// ─────────────────────────────────────────────
class _IncludedCard extends StatelessWidget {
  final bool isElite;
  final int carCount;
  final Color accentColor;

  const _IncludedCard({
    required this.isElite,
    required this.carCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final features = isElite
        ? [
            _Feature(Icons.local_gas_station_rounded,
                '3 Fill-Ups per Week per car'),
            _Feature(Icons.location_on_rounded, 'Service at up to 3 Addresses'),
            _Feature(Icons.flash_on_rounded, 'Same-Day Fill-Up available'),
            _Feature(Icons.schedule_rounded, 'Flexible Scheduling'),
            _Feature(Icons.tire_repair_rounded, 'Tire Pressure Check'),
            _Feature(Icons.water_drop_rounded, 'Windshield Cleaning'),
            if (carCount == 4)
              _Feature(Icons.card_giftcard_rounded,
                  'BONUS: 4th Car Subscription FREE!',
                  special: true),
            _Feature(Icons.local_offer_rounded, 'Gas Discount (Possible Offer!)'),
          ]
        : [
            _Feature(Icons.local_gas_station_rounded,
                '1 Fill-Up per Week per car'),
            _Feature(Icons.location_on_rounded, 'Service at up to 2 Addresses'),
            _Feature(Icons.schedule_rounded, 'Flexible Scheduling'),
            _Feature(Icons.tire_repair_rounded, 'Tire Pressure Check'),
            _Feature(Icons.water_drop_rounded, 'Windshield Cleaning'),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: features
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: f.special
                              ? const Color(0xFFFFF9C4)
                              : accentColor.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          f.icon,
                          color: f.special
                              ? const Color(0xFFF39C12)
                              : accentColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: f.special
                                ? const Color(0xFFF39C12)
                                : const Color(0xFF333333),
                            fontWeight: f.special
                                ? FontWeight.bold
                                : FontWeight.normal,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  final bool special;
  const _Feature(this.icon, this.label, {this.special = false});
}

// ─────────────────────────────────────────────
// PAYMENT OPTION ROW
// ─────────────────────────────────────────────
class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFEEEEEE),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withAlpha(20)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color:
                      isSelected ? accentColor : const Color(0xFF888888),
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected
                          ? accentColor
                          : const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? accentColor : const Color(0xFFDDDDDD),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SUCCESS BOTTOM SHEET
// ─────────────────────────────────────────────
class _SuccessSheet extends StatelessWidget {
  final String planName;
  final int carCount;
  final bool isElite;
  final VoidCallback onDone;

  const _SuccessSheet({
    required this.planName,
    required this.carCount,
    required this.isElite,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isElite
                    ? [const Color(0xFF7B2FBE), const Color(0xFF9C27B0)]
                    : [const Color(0xFFFF6600), const Color(0xFFFF9500)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: (isElite
                            ? const Color(0xFF9C27B0)
                            : const Color(0xFFFF6600))
                        .withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 42),
          ),
          const SizedBox(height: 24),
          Text(
            isElite ? 'Welcome to Elite!' : 'Welcome to Family!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re now enrolled in the $planName plan for $carCount car${carCount > 1 ? 's' : ''}.\n'
            'Your first delivery is ready to schedule.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isElite ? const Color(0xFF7B2FBE) : const Color(0xFFFF6600),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
