import 'package:flutter/material.dart';
import 'dart:ui';
import 'add_vehicle_screen.dart';
import 'schedule_delivery_screen.dart';
import 'add_address_screen.dart';
import '../../services/supabase_service.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  int _selectedVehicleIndex = 0;
  int _selectedAddressIndex = 0;
  double _amount = 45.0; 
  bool _isFullTank = false;
  bool _isCustomMode = false;
  final TextEditingController _amountController = TextEditingController(text: "45.00");

  final List<double> _quickSelectOptions = [25.0, 45.0, 65.0];
  final FocusNode _amountFocusNode = FocusNode();

  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _addresses = [];
  List<Map<String, dynamic>> _fuelPrices = [];
  double _pricePerGallon = 3.49; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final results = await Future.wait([
        SupabaseService.getVehicles(user.id),
        SupabaseService.getAddresses(user.id),
        SupabaseService.getFuelPrices(),
      ]);

      if (mounted) {
        setState(() {
          _vehicles = results[0];
          _addresses = results[1];
          _fuelPrices = results[2];
          _updatePricePerGallon();
        });
      }
    }
  }

  void _updatePricePerGallon() {
    if (_vehicles.isNotEmpty && _fuelPrices.isNotEmpty) {
      final vehicle = _vehicles[_selectedVehicleIndex];
      final fuelType = vehicle['fuel_type'] ?? 'Petrol';
      
      final priceEntry = _fuelPrices.firstWhere(
        (p) => p['name'].toString().toLowerCase().contains(fuelType.toString().toLowerCase()),
        orElse: () => _fuelPrices.first,
      );
      
      setState(() {
        _pricePerGallon = (priceEntry['price'] as num).toDouble();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _updateAmount(double val) {
    setState(() {
      _amount = val;
      _amountController.text = _amount.toStringAsFixed(2);
      _isFullTank = false;
      _isCustomMode = false;
    });
  }

  void _toggleCustomMode() {
    setState(() {
      _isCustomMode = true;
      _isFullTank = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _amountFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Vehicle Selection',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
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
                'Which vehicle needs fuel?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF333333),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a vehicle from your garage to continue.',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              
              if (_vehicles.isEmpty)
                const Center(child: Text('No vehicles added yet', style: TextStyle(color: Colors.grey)))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vehicles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final v = _vehicles[index];
                    return _buildVehicleCard(
                      index: index,
                      name: '${v['make']} ${v['model']}',
                      type: v['type'] ?? v['fuel_type'] ?? 'Vehicle',
                      imageUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?q=80&w=2070&auto=format&fit=crop', // Generic car image
                    );
                  },
                ),
              const SizedBox(height: 16),
              // Add New Vehicles Button (High Fidelity - Dotted Border)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                  ).then((_) => _loadData());
                },
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: const Color(0xFFCBD5E1),
                    strokeWidth: 2,
                    dashWidth: 8,
                    dashSpace: 6,
                    borderRadius: 16,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline, color: Color(0xFF64748B), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Add New Vehicles',
                          style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddAddressScreen()),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFFFF6600)),
                    label: const Text('Add Address', style: TextStyle(color: Color(0xFFFF6600), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_addresses.isEmpty)
                const Center(child: Text('No addresses found', style: TextStyle(color: Colors.grey)))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _addresses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final addr = _addresses[index];
                    return _buildAddressCard(
                      index: index,
                      title: addr['title'],
                      address: addr['address'],
                      isHome: addr['title'].toString().toLowerCase() == 'home',
                    );
                  },
                ),
              const SizedBox(height: 32),
              // Amount Section (High Fidelity)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Dollar Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isCustomMode)
                      const Text(
                        'Enter your own amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6600),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Amount Display / Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: (_isFullTank && !_isCustomMode)
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF1E293B),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            enabled: _isCustomMode && !_isFullTank,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "0.00",
                              hintStyle: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE2E8F0),
                                letterSpacing: -1,
                              ),
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: (_isFullTank && !_isCustomMode)
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E293B),
                              letterSpacing: -1,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _amount = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _amount < 20.0 && !_isFullTank
                          ? 'Minimum order: \$20'
                          : 'Approx. Fuel: ${(_amount / _pricePerGallon).toStringAsFixed(1)} gallons',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _amount < 20.0 && !_isFullTank
                            ? Colors.red
                            : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price per gallon: \$${_pricePerGallon.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Selection Area
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Preset Chips
                        ..._quickSelectOptions.map(
                          (q) => _buildQuickSelectChip(q),
                        ),

                        // [NEW] Custom Amount Button
                        GestureDetector(
                          onTap: _toggleCustomMode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _isCustomMode
                                  ? const Color(0xFFFF6600)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isCustomMode
                                    ? const Color(0xFFFF6600)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              'Custom Amount',
                              style: TextStyle(
                                color: _isCustomMode
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        // Full Tank Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFullTank = !_isFullTank;
                              _isCustomMode = false;
                              if (_isFullTank) {
                                _amountController.text = '---';
                              } else {
                                _amountController.text = _amount
                                    .toStringAsFixed(2);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: (_isFullTank && !_isCustomMode)
                                  ? const Color(0xFFFF6600)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (_isFullTank && !_isCustomMode)
                                    ? const Color(0xFFFF6600)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_gas_station,
                                  size: 16,
                                  color: (_isFullTank && !_isCustomMode)
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Full Tank',
                                  style: TextStyle(
                                    color: (_isFullTank && !_isCustomMode)
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Footer (Now part of scrollable content)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
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
                              'TOTAL ESTIMATE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isFullTank
                                  ? '---'
                                  : '\$${_amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              'TIME SLOT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'WITHIN 20 MINS',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF4D00),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_vehicles.isEmpty || _addresses.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please add both a vehicle and an address to continue.')),
                            );
                            return;
                          }

                          final vehicle = _vehicles[_selectedVehicleIndex];
                          final address = _addresses[_selectedAddressIndex];
                          
                          String vehicleName = '${vehicle['make']} ${vehicle['model']}';
                          String locationName = '${address['title']} (${address['address']})';
                          String fuelType = vehicle['fuel_type'] ?? 'Petrol';

                          if (!_isFullTank && _amount < 20.0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Minimum order amount is \$20.00'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ScheduleDeliveryScreen(
                                vehicleName: vehicleName,
                                locationName: locationName,
                                latitude: (address['latitude'] is int) ? (address['latitude'] as int).toDouble() : (address['latitude'] ?? 37.7749),
                                longitude: (address['longitude'] is int) ? (address['longitude'] as int).toDouble() : (address['longitude'] ?? -122.4194),
                                quantity: _isFullTank
                                    ? 'Full Tank'
                                    : '${(_amount / _pricePerGallon).toStringAsFixed(1)} gal',
                                amount: _isFullTank
                                    ? '---'
                                    : '\$${_amount.toStringAsFixed(2)}',
                                fuelType: fuelType,
                                vehicleId: vehicle['id'] as String?,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5500),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required int index,
    required String name,
    required String type,
    required String imageUrl,
  }) {
    bool isSelected = _selectedVehicleIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6600)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Image.network(
              imageUrl,
              width: 80,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_car,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF6600)
                      : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6600),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required int index,
    required String title,
    required String address,
    required bool isHome,
  }) {
    bool isSelected = _selectedAddressIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressIndex = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7F0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6600)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853), // Green
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isHome ? Icons.home_filled : Icons.business,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFF6600), size: 28)
            else
              const Icon(
                Icons.circle_outlined,
                color: Color(0xFFE2E8F0),
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectChip(double val) {
    bool isCurrent = !_isFullTank && _amount == val;
    return GestureDetector(
      onTap: () => _updateAmount(val),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '\$${val.toInt()}',
          style: TextStyle(
            color: isCurrent
                ? const Color(0xFF1E293B)
                : const Color(0xFF64748B),
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
    this.borderRadius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromLTRBR(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth / 2,
      size.height - strokeWidth / 2,
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rRect);
    final Path dashPath = Path();

    double distance = 0.0;
    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace ||
      borderRadius != oldDelegate.borderRadius;
}
