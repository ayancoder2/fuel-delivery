import 'package:flutter/material.dart';
import '../notifications/notifications_screen.dart';
import '../order/vehicle_selection_screen.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/notification_store.dart';
import '../../services/inventory_service.dart';
import '../profile/settings_screen.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../services/order_service.dart';
import '../order/add_vehicle_screen.dart';
import '../order/order_history_screen.dart';
import '../order/order_tracking_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _vehicle;
  Map<String, dynamic>? _activeOrder;
  int? _selectedFuelIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;
    if (user != null) {
      NotificationStore.instance.syncWithSupabase(user.id);
      final results = await Future.wait<dynamic>([
        ProfileService.getProfile(user.id),
        VehicleService.getVehicles(user.id),
        OrderService.getActiveOrder(user.id),
      ]);
      
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          final List<Map<String, dynamic>> vehicles = results[1] as List<Map<String, dynamic>>;
          if (vehicles.isNotEmpty) {
            _vehicle = vehicles.first;
          }
          _activeOrder = results[2] as Map<String, dynamic>?;
        });
      }
    }
  }

  Widget _buildActiveOrderBanner() {
    final status = _activeOrder?['status'] ?? 'PENDING';
    final fuelType = _activeOrder?['fuel_type'] ?? 'Fuel';
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(orderId: _activeOrder!['id']),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6600), Color(0xFFFF9933)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6600).withAlpha(60),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Delivery',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$fuelType • $status',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'local_gas_station': return Icons.local_gas_station;
      case 'ev_station': return Icons.ev_station;
      default: return Icons.local_gas_station;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _profile?['full_name'] ?? 'Guest';
    final String avatarUrl = _profile?['avatar_url'] ?? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=1974&auto=format&fit=crop';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFFF6600),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          ).then((_) => _loadData()); 
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good day, $displayName',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const Text(
                                  'Ready for a top-up?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ListenableBuilder(
                        listenable: NotificationStore.instance,
                        builder: (context, _) {
                          final count = NotificationStore.instance.unreadCount;
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFEEEEEE)),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    size: 20,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF6600),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        count > 9 ? '9+' : '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Active Order Banner
                  if (_activeOrder != null) ...[
                    _buildActiveOrderBanner(),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 20),
                  // Fuel Types Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF5F5F5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TODAY\'S FUEL PRICE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: InventoryService.getFuelPrices(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Error loading prices: ${snapshot.error}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Color(0xFFFF6600)),
                              ));
                            }
                            final prices = snapshot.data!;
                            if (prices.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('No fuel prices available', style: TextStyle(color: Colors.grey)),
                                ),
                              );
                            }
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: prices.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                              itemBuilder: (context, index) {
                                final fuel = prices[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFuelIndex = index;
                                    });
                                  },
                                  child: _FuelTypeTile(
                                    title: fuel['name'],
                                    price: '\$${(fuel['price'] as num).toStringAsFixed(2)}/${fuel['unit']}',
                                    isSelected: _selectedFuelIndex == index,
                                    icon: _getIconData(fuel['icon_name']),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Order Fuel Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const VehicleSelectionScreen(),
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFF6600).withAlpha(150),
                                  const Color(0xFFFFE5CC).withAlpha(100),
                                  Colors.white,
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 170,
                            height: 170,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6600),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66FF6600),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.local_gas_station,
                                  size: 50,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'ORDER FUEL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      if (_vehicle == null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                        ).then((_) => _loadData());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF5F5F5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _vehicle != null 
                                    ? '${_vehicle!['make']} ${_vehicle!['model']}'
                                    : 'No vehicle added',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _vehicle != null 
                                    ? 'PLATE: ${_vehicle!['license_plate']}'
                                    : 'Add a vehicle to get started',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          _vehicle != null
                            ? const Icon(Icons.directions_car, size: 60, color: Color(0xFFFF6600))
                            : const Icon(Icons.add_circle_outline, size: 60, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Delivery Status 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.local_shipping, color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Delivery available in 15-20 min',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OrderHistoryScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }
}

class _FuelTypeTile extends StatelessWidget {
  final String title;
  final String price;
  final bool isSelected;
  final IconData? icon;

  const _FuelTypeTile({
    required this.title,
    required this.price,
    required this.isSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFF0F0F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.local_gas_station,
            color: isSelected ? const Color(0xFFFF6600) : Colors.blueAccent,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          Text(price, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
