import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import 'subscription_checkout_screen.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPlan = 'Pay-As-You-Go';
  bool _isSaving = false;
  bool _isLoading = true;

  // Car count per plan (separate state)
  int _familyCarCount = 1;
  int _eliteCarCount = 1;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchCurrentPlan();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentPlan() async {
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        final profileData = await ProfileService.getProfile(user.id);
        if (profileData != null && profileData['subscription_plan'] != null) {
          if (mounted) {
            setState(() {
              _selectedPlan = profileData['subscription_plan'];
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching plan: $e');
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  double _getFamilyMonthlyFee(int cars) {
    if (cars == 1) return 25.0;
    if (cars == 2) return 25.0 + 5.0;
    return 30.0 + 5.0; // 3 cars
  }

  double _getEliteMonthlyFee(int cars) {
    if (cars == 1) return 30.0;
    if (cars == 2) return 30.0 + 5.0;
    if (cars == 3) return 35.0 + 5.0;
    return 35.0 + 5.0; // 4th car is FREE
  }

  String _getFamilyPriceLabel(int cars) {
    if (cars == 1) return '\$25';
    if (cars == 2) return '\$30';
    return '\$35';
  }

  String _getElitePriceLabel(int cars) {
    if (cars == 1) return '\$30';
    if (cars == 2) return '\$35';
    if (cars == 3) return '\$40';
    return '\$40 ✦ 4th FREE';
  }

  void _proceed() {
    if (_selectedPlan == 'Pay-As-You-Go') {
      _savePAYG();
      return;
    }
    final carCount =
        _selectedPlan == 'Family Subscription' ? _familyCarCount : _eliteCarCount;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionCheckoutScreen(
          planName: _selectedPlan,
          carCount: carCount,
          monthlyFee: _selectedPlan == 'Family Subscription'
              ? _getFamilyMonthlyFee(carCount)
              : _getEliteMonthlyFee(carCount),
        ),
      ),
    );
  }

  Future<void> _savePAYG() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      await ProfileService.updateProfile(
        userId: user.id,
        subscriptionPlan: _selectedPlan,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Switched to Pay-As-You-Go'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
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
          'FUEL PLAN',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6600)))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Fuel delivered to you — on your schedule.',
                      style:
                          TextStyle(fontSize: 14, color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 28),

                    // ── PAY-AS-YOU-GO ──
                    _PayAsYouGoCard(
                      isSelected: _selectedPlan == 'Pay-As-You-Go',
                      onTap: () =>
                          setState(() => _selectedPlan = 'Pay-As-You-Go'),
                    ),
                    const SizedBox(height: 20),

                    // ── FAMILY ──
                    _FamilyPlanCard(
                      isSelected: _selectedPlan == 'Family Subscription',
                      carCount: _familyCarCount,
                      priceLabel: _getFamilyPriceLabel(_familyCarCount),
                      onTap: () =>
                          setState(() => _selectedPlan = 'Family Subscription'),
                      onCarCountChanged: (v) =>
                          setState(() => _familyCarCount = v),
                      maxCars: 3,
                    ),
                    const SizedBox(height: 20),

                    // ── FAMILY ELITE ──
                    _FamilyEliteCard(
                      isSelected: _selectedPlan == 'Family Elite',
                      carCount: _eliteCarCount,
                      priceLabel: _getElitePriceLabel(_eliteCarCount),
                      onTap: () =>
                          setState(() => _selectedPlan = 'Family Elite'),
                      onCarCountChanged: (v) =>
                          setState(() => _eliteCarCount = v),
                      maxCars: 4,
                    ),
                    const SizedBox(height: 28),

                    // Business link
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Business Accounts coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.business_center_outlined,
                            color: Color(0xFF888888), size: 18),
                        label: const Text(
                          'BUSINESS ACCOUNTS',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomSheet: _isLoading
          ? const SizedBox.shrink()
          : _BottomCTASheet(
              planName: _selectedPlan,
              isSaving: _isSaving,
              onPressed: _proceed,
            ),
    );
  }
}

// ─────────────────────────────────────────────
// PAY-AS-YOU-GO CARD
// ─────────────────────────────────────────────
class _PayAsYouGoCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _PayAsYouGoCard({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFE8E8E8),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2196F3).withAlpha(30)
                  : Colors.black.withAlpha(8),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bolt_rounded,
                      color:
                          isSelected ? Colors.white : const Color(0xFF2196F3),
                      size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PAY-AS-YOU-GO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'Flexible, no commitment',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                _SelectionDot(isSelected: isSelected, color: const Color(0xFF2196F3)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  '\$12',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(width: 6),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Delivery Fee + Gallons',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FeatureRow(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF2196F3),
              text: 'Service available at selected locations',
            ),
            _FeatureRow(
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFF2196F3),
              text: 'Based on driver availability',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FAMILY PLAN CARD
// ─────────────────────────────────────────────
class _FamilyPlanCard extends StatelessWidget {
  final bool isSelected;
  final int carCount;
  final String priceLabel;
  final VoidCallback onTap;
  final ValueChanged<int> onCarCountChanged;
  final int maxCars;

  const _FamilyPlanCard({
    required this.isSelected,
    required this.carCount,
    required this.priceLabel,
    required this.onTap,
    required this.onCarCountChanged,
    required this.maxCars,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF6600)
                    : const Color(0xFFE8E8E8),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFFFF6600).withAlpha(35)
                      : Colors.black.withAlpha(8),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF6600)
                            : const Color(0xFFFFECE0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.groups_rounded,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFFF6600),
                          size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'FAMILY',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Up to 3 Cars',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    ),
                    _SelectionDot(
                        isSelected: isSelected,
                        color: const Color(0xFFFF6600)),
                  ],
                ),
                const SizedBox(height: 18),

                // Price tiers
                _PricingTable(
                  rows: const [
                    _PricingRow('1 Car', '\$25', '+ Gallons'),
                    _PricingRow('2 Cars', '\$25 + \$5', '+ Gallons'),
                    _PricingRow('3 Cars', '\$30 + \$5', '+ Gallons'),
                  ],
                  highlightIndex: carCount - 1,
                  accentColor: const Color(0xFFFF6600),
                ),
                const SizedBox(height: 16),

                // Car count selector
                if (isSelected) ...[
                  _CarCountSelector(
                    label: 'How many cars?',
                    count: carCount,
                    max: maxCars,
                    accentColor: const Color(0xFFFF6600),
                    onChanged: onCarCountChanged,
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(color: Color(0xFFF0F0F0), height: 24),
                const Text(
                  'Includes:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 8),
                _FeatureRow(
                    icon: Icons.local_gas_station_rounded,
                    iconColor: const Color(0xFFFF6600),
                    text: '1 Fill-Up per Week'),
                _FeatureRow(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFFFF6600),
                    text: 'Service at 2 Addresses'),
                _FeatureRow(
                    icon: Icons.schedule_rounded,
                    iconColor: const Color(0xFFFF6600),
                    text: 'Flexible Schedule'),
                _FeatureRow(
                    icon: Icons.tire_repair_rounded,
                    iconColor: const Color(0xFFFF6600),
                    text: 'Tire Pressure Check'),
                _FeatureRow(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFFFF6600),
                    text: 'Windshield Cleaning'),
              ],
            ),
          ),
          // MOST POPULAR badge
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6600), Color(0xFFFF9500)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFF6600).withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Text(
                    '⭐  MOST POPULAR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FAMILY ELITE CARD
// ─────────────────────────────────────────────
class _FamilyEliteCard extends StatelessWidget {
  final bool isSelected;
  final int carCount;
  final String priceLabel;
  final VoidCallback onTap;
  final ValueChanged<int> onCarCountChanged;
  final int maxCars;

  const _FamilyEliteCard({
    required this.isSelected,
    required this.carCount,
    required this.priceLabel,
    required this.onTap,
    required this.onCarCountChanged,
    required this.maxCars,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF9C27B0).withAlpha(50)
                  : Colors.black.withAlpha(8),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withAlpha(30)
                        : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.workspace_premium_rounded,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF9C27B0),
                      size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FAMILY ELITE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color:
                              isSelected ? Colors.white : const Color(0xFF1A1A2E),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Up to 4 Cars',
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white60
                                : const Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                _SelectionDot(
                    isSelected: isSelected,
                    color: Colors.white,
                    borderColor:
                        isSelected ? Colors.white : const Color(0xFFDDDDDD)),
              ],
            ),
            const SizedBox(height: 18),

            // Pricing table
            _PricingTable(
              rows: const [
                _PricingRow('1 Car', '\$30', '+ Gallons'),
                _PricingRow('2 Cars', '\$30 + \$5', '+ Gallons'),
                _PricingRow('3 Cars', '\$35 + \$5', '+ Gallons'),
                _PricingRow('4th Car', 'FREE', '🎁 BONUS'),
              ],
              highlightIndex: carCount - 1,
              accentColor:
                  isSelected ? Colors.white : const Color(0xFF9C27B0),
              textColor: isSelected ? Colors.white : const Color(0xFF333333),
              subTextColor:
                  isSelected ? Colors.white60 : const Color(0xFF888888),
            ),
            const SizedBox(height: 16),

            // Car count selector
            if (isSelected) ...[
              _CarCountSelector(
                label: 'How many cars?',
                count: carCount,
                max: maxCars,
                accentColor: Colors.white,
                onChanged: onCarCountChanged,
                darkMode: true,
              ),
              const SizedBox(height: 16),
            ],

            Divider(
                color: isSelected
                    ? Colors.white.withAlpha(40)
                    : const Color(0xFFF0F0F0),
                height: 24),
            Text(
              'Everything in Family, plus:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white70 : const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            _FeatureRow(
                icon: Icons.local_gas_station_rounded,
                iconColor: isSelected ? Colors.white : const Color(0xFF9C27B0),
                text: '3 Fill-Ups per Week',
                textColor: isSelected ? Colors.white : null),
            _FeatureRow(
                icon: Icons.location_on_rounded,
                iconColor: isSelected ? Colors.white : const Color(0xFF9C27B0),
                text: 'Service at 3 Addresses',
                textColor: isSelected ? Colors.white : null),
            _FeatureRow(
                icon: Icons.flash_on_rounded,
                iconColor: isSelected ? Colors.white : const Color(0xFF9C27B0),
                text: 'Same-Day Fill-Up',
                textColor: isSelected ? Colors.white : null),
            _FeatureRow(
                icon: Icons.card_giftcard_rounded,
                iconColor: isSelected
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFF39C12),
                text: 'BONUS: 4th Car FREE!',
                textColor: isSelected ? const Color(0xFFFFD700) : null,
                bold: true),
            _FeatureRow(
                icon: Icons.local_offer_rounded,
                iconColor: isSelected ? Colors.white : const Color(0xFF9C27B0),
                text: 'Gas Discount (Possible Offer!)',
                textColor: isSelected ? Colors.white : null),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────

class _SelectionDot extends StatelessWidget {
  final bool isSelected;
  final Color color;
  final Color? borderColor;
  const _SelectionDot(
      {required this.isSelected, required this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? color : Colors.transparent,
        border: Border.all(
          color: borderColor ?? (isSelected ? color : const Color(0xFFDDDDDD)),
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check,
              size: 14,
              color: isSelected && color == Colors.white
                  ? const Color(0xFF1A1A2E)
                  : Colors.white)
          : null,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color? textColor;
  final bool bold;
  const _FeatureRow(
      {required this.icon,
      required this.iconColor,
      required this.text,
      this.textColor,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor ?? const Color(0xFF555555),
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingRow {
  final String label;
  final String price;
  final String suffix;
  const _PricingRow(this.label, this.price, this.suffix);
}

class _PricingTable extends StatelessWidget {
  final List<_PricingRow> rows;
  final int highlightIndex;
  final Color accentColor;
  final Color? textColor;
  final Color? subTextColor;

  const _PricingTable({
    required this.rows,
    required this.highlightIndex,
    required this.accentColor,
    this.textColor,
    this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows.length, (i) {
        final row = rows[i];
        final isHighlighted = i == highlightIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? accentColor.withAlpha(accentColor == Colors.white ? 40 : 20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isHighlighted
                ? Border.all(
                    color: accentColor.withAlpha(
                        accentColor == Colors.white ? 100 : 60),
                    width: 1)
                : null,
          ),
          child: Row(
            children: [
              Text(
                row.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted
                      ? (textColor ?? const Color(0xFF333333))
                      : (subTextColor ?? const Color(0xFF888888)),
                ),
              ),
              const Spacer(),
              Text(
                row.price,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isHighlighted
                      ? accentColor
                      : (subTextColor ?? const Color(0xFFAAAAAA)),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                row.suffix,
                style: TextStyle(
                  fontSize: 11,
                  color: isHighlighted
                      ? (textColor?.withAlpha(180) ??
                          const Color(0xFF888888))
                      : const Color(0xFFBBBBBB),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CarCountSelector extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final Color accentColor;
  final ValueChanged<int> onChanged;
  final bool darkMode;

  const _CarCountSelector({
    required this.label,
    required this.count,
    required this.max,
    required this.accentColor,
    required this.onChanged,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: darkMode ? Colors.white70 : const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(max, (i) {
            final n = i + 1;
            final isSelected = n == count;
            return GestureDetector(
              onTap: () => onChanged(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 10),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : (darkMode
                          ? Colors.white.withAlpha(20)
                          : const Color(0xFFF4F6FA)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : (darkMode
                            ? Colors.white.withAlpha(40)
                            : const Color(0xFFDDDDDD)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_filled_rounded,
                      size: 14,
                      color: isSelected
                          ? (darkMode ? const Color(0xFF1A1A2E) : Colors.white)
                          : (darkMode ? Colors.white54 : const Color(0xFF888888)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? (darkMode
                                ? const Color(0xFF1A1A2E)
                                : Colors.white)
                            : (darkMode
                                ? Colors.white54
                                : const Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BottomCTASheet extends StatelessWidget {
  final String planName;
  final bool isSaving;
  final VoidCallback onPressed;

  const _BottomCTASheet({
    required this.planName,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 16),
                const SizedBox(width: 6),
                Text(
                  planName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Cancel anytime',
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isSaving ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6600).withAlpha(100),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            planName == 'Pay-As-You-Go'
                                ? 'Select Plan'
                                : 'Continue to Checkout',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
