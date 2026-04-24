import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../order/add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final vehicles = await VehicleService.getVehicles(user.id);
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Vehicles',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_vehicles.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'No vehicles added yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                  ..._vehicles.map((vehicle) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildVehicleCard(
                          context,
                          vehicle: vehicle,
                        ),
                      )),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                      );
                      _loadVehicles(); // Refresh list after returning
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF6600),
                      side: const BorderSide(color: Color(0xFFFF6600), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Add New Vehicle',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getColor(String? colorName) {
    if (colorName == null) return Colors.grey;
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      case 'gray': case 'grey': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Widget _buildVehicleCard(
    BuildContext context, {
    required Map<String, dynamic> vehicle,
  }) {
    final String id = vehicle['id'];
    final String nickname = vehicle['make'] ?? 'Unnamed';
    final String model = vehicle['model'] ?? '';
    final String plate = vehicle['license_plate'] ?? '';
    final String fuelType = vehicle['fuel_type'] ?? 'Petrol';
    final Color color = _getColor(vehicle['color']);
    const IconData icon = Icons.directions_car;

    // Use a darker color if the vehicle color is white so the icon doesn't disappear on the white card
    final Color displayColor = color == Colors.white ? const Color(0xFF94A3B8) : color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: displayColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: color == Colors.white ? Border.all(color: const Color(0xFFE2E8F0)) : null,
            ),
            child: Icon(icon, color: displayColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$model • $plate • $fuelType',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF6600), size: 20),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddVehicleScreen(initialVehicle: vehicle),
                    ),
                  );
                  _loadVehicles();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                onPressed: () async {
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Vehicle'),
                      content: const Text('Are you sure you want to remove this vehicle?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await VehicleService.deleteVehicle(id);
                    _loadVehicles();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
