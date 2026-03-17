import 'package:flutter/material.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  String _selectedType = 'Sedan';
  String _selectedFuel = 'Regular';
  Color _selectedColor = Colors.white;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'name': 'Sedan', 'icon': Icons.directions_car},
    {'name': 'SUV', 'icon': Icons.car_rental},
    {'name': 'Van', 'icon': Icons.airport_shuttle},
    {'name': 'Truck', 'icon': Icons.local_shipping},
  ];

  final List<Color> _vehicleColors = [
    Colors.white,
    const Color(0xFF0F172A), // Dark Navy/Black
    const Color(0xFF94A3B8), // Slate/Gray
    const Color(0xFFDC2626), // Red
    const Color(0xFF2563EB), // Blue
    const Color(0xFF059669), // Green
    const Color(0xFFFBBF24), // Amber/Yellow
  ];

  final List<Map<String, String>> _fuelTypes = [
    {
      'id': 'Regular',
      'label': 'Regular',
      'sublabel': 'STANDARD PERFORMANCE',
      'octane': '87',
    },
    {
      'id': 'Premium',
      'label': 'Premium',
      'sublabel': 'HIGH OCTANE',
      'octane': '93',
    },
    {
      'id': 'Diesel',
      'label': 'On-road Diesel',
      'sublabel': 'ULTRA LOW SULFUR',
      'octane': '', // Indicates pump icon
    },
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Vehicle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSectionHeader('Select Vehicle Type'),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _vehicleTypes
                    .map((type) => _buildTypeCard(type))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Vehicle Color'),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _vehicleColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final color = _vehicleColors[index];
                  bool isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF6600)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected && color == Colors.white
                          ? const Icon(
                              Icons.check,
                              size: 20,
                              color: Color(0xFFFF6600),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Vehicle Name/Nickname'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nicknameController,
              hint: 'e.g. My Daily Driver',
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Fuel Type (Mandatory)'),
            const SizedBox(height: 16),
            ..._fuelTypes.map((fuel) => _buildFuelCard(fuel)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Make'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _makeController,
                        hint: 'e.g. Toyota',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Model'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _modelController,
                        hint: 'e.g. Corolla',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('License Plate Number'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _plateController,
              hint: 'ENTER PLATE NUMBER',
              suffixIcon: Icons.credit_card,
            ),
            const SizedBox(height: 32),
            _buildSecureInfoCard(),
            const SizedBox(height: 40),
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> type) {
    bool isSelected = _selectedType == type['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type['name']),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF6600)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF6600).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              type['icon'],
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type['name'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFFF6600)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
          fontSize: 15,
        ),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    suffixIcon,
                    color: const Color(0xFF94A3B8),
                    size: 24,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFuelCard(Map<String, String> fuel) {
    bool isSelected = _selectedFuel == fuel['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedFuel = fuel['id']!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6600)
                : const Color(0xFFF1F5F9),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6600).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF6600)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: fuel['octane']!.isNotEmpty
                    ? Text(
                        fuel['octane']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : Icon(
                        Icons.local_gas_station_rounded,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fuel['label']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fuel['sublabel']!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? const Color(0xFFFF6600)
                  : const Color(0xFFCBD5E1),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.network(
              'https://cdn-icons-png.flaticon.com/512/3064/3064197.png', // Lock icon placeholder
              width: 20,
              height: 20,
              color: const Color(0xFFB8C089),
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.lock_rounded,
                size: 20,
                color: Color(0xFFB8C089),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Vehicle Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your vehicle details help our drivers identify and service the correct vehicle at your location.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    bool isEnabled =
        _plateController.text.isNotEmpty &&
        _nicknameController.text.isNotEmpty &&
        _makeController.text.isNotEmpty &&
        _modelController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: isEnabled ? () => Navigator.pop(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? const Color(0xFFFF6600)
              : const Color(0xFFE2E8F0),
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: isEnabled ? Colors.white : const Color(0xFF94A3B8),
          elevation: isEnabled ? 4 : 0,
          shadowColor: const Color(0xFFFF6600).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check,
              size: 22,
              color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            const Text(
              'Save Vehicle',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
