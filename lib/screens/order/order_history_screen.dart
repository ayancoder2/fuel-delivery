import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/settings_screen.dart';
import 'add_vehicle_screen.dart';
import 'order_details_screen.dart';
import '../../services/supabase_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final orders = await SupabaseService.getOrders(user.id);
      if (mounted) {
        setState(() {
          _orders = orders;
          _filteredOrders = orders;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((order) {
          final vehicle = order['vehicles'];
          final vehicleName = vehicle != null ? '${vehicle['make']} ${vehicle['model']}'.toLowerCase() : '';
          final fuelType = (order['fuel_type'] ?? '').toString().toLowerCase();
          final status = (order['status'] ?? '').toString().toLowerCase();
          final address = (order['delivery_address'] ?? '').toString().toLowerCase();
          
          return vehicleName.contains(query) || 
                 fuelType.contains(query) || 
                 status.contains(query) || 
                 address.contains(query);
        }).toList();
      }
    });
  }

  String _getMonthYear(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = [
        'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
        'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'UNKNOWN';
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      String month = months[date.month - 1];
      String day = date.day.toString().padLeft(2, '0');
      int hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      String minute = date.minute.toString().padLeft(2, '0');
      String period = date.hour >= 12 ? 'PM' : 'AM';
      return '$month $day, ${date.year} • $hour:$minute $period';
    } catch (e) {
      return 'Unknown Date';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Order History',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        color: const Color(0xFFFF6600),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFFAAAAAA)),
                    hintText: 'Search orders, status or fuel...',
                    hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6600)))
                  : _filteredOrders.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            const Center(
                              child: Text(
                                'No orders found',
                                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final vehicle = order['vehicles'];
                            String vehicleText = 'Unknown Vehicle';
                            if (vehicle != null) {
                              vehicleText = '${vehicle['make']} ${vehicle['model']} • ${order['quantity']}L';
                            } else {
                              vehicleText = 'Vehicle removed • ${order['quantity']}L';
                            }

                            String currentMonthYear = _getMonthYear(order['created_at']);
                            bool showHeader = false;
                            if (index == 0) {
                              showHeader = true;
                            } else {
                              String prevMonthYear = _getMonthYear(_filteredOrders[index - 1]['created_at']);
                              if (currentMonthYear != prevMonthYear) {
                                showHeader = true;
                              }
                            }

                            String status = order['status'] ?? 'DELIVERED';
                            Color statusColor;
                            switch(status) {
                              case 'CANCELLED':
                                statusColor = const Color(0xFFF44336);
                                break;
                              case 'DELIVERED':
                                statusColor = const Color(0xFF4CAF50);
                                break;
                              case 'PENDING':
                                statusColor = const Color(0xFFFFB74D);
                                break;
                              default:
                                statusColor = const Color(0xFF2196F3); // Processing, Out for Delivery
                            }

                            final double price = (order['total_price'] is int) 
                                ? (order['total_price'] as int).toDouble() 
                                : (order['total_price'] ?? 0.0);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader) _buildSectionHeader(currentMonthYear),
                                _buildOrderCard(
                                  date: _formatDateTime(order['created_at']),
                                  vehicle: vehicleText,
                                  price: 'Rs. ${price.toStringAsFixed(0)}',
                                  status: status,
                                  statusColor: statusColor,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsScreen(order: order),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
            ).then((_) => _loadOrders());
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
         ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String date,
    required String vehicle,
    required String price,
    required String status,
    required Color statusColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF5F5F5)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_gas_station_rounded, color: Color(0xFFFF6600), size: 28),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
