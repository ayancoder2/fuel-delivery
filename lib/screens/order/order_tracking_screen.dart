import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'delivery_complete_screen.dart';
import '../../services/supabase_service.dart';
import '../../services/driver_simulation_service.dart';
import '../../services/notification_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'chat_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;
  const OrderTrackingScreen({super.key, this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  StreamSubscription? _orderSubscription;
  Map<String, dynamic>? _orderData;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _currentOrderId;
  
  // Notification flags to prevent spamming
  bool _hasNotifiedStarted = false;
  bool _hasNotifiedArrived = false;
  bool _hasNotifiedCompleted = false;

  // Silver Style JSON for a clean "Indrive" look
  final String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [ { "color": "#f5f5f5" } ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [ { "visibility": "off" } ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [ { "color": "#ffffff" } ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [ { "color": "#dadada" } ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [ { "color": "#c9c9c9" } ]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _currentOrderId = widget.orderId;
    _initializeTracking();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    if (_currentOrderId != null) {
      DriverSimulationService.stopOrderSimulation(_currentOrderId!);
    }
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    if (_currentOrderId == null) {
      final activeOrder = await SupabaseService.getActiveOrder(user.id);
      if (activeOrder != null) {
        setState(() {
          _currentOrderId = activeOrder['id'];
          _orderData = activeOrder;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      // If we have an ID, fetch it once to show data immediately
      try {
        final order = await SupabaseService.client
            .from('orders')
            .select('*, vehicles(make, model, license_plate)')
            .eq('id', _currentOrderId!)
            .single();
        
        setState(() {
          _orderData = order;
          _isLoading = false;
          _updateMarkers();
        });
      } catch (e) {
        debugPrint('Error fetching order initially: $e');
        // fall back to stream only, but turn off loading after a delay if still empty
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isLoading) setState(() => _isLoading = false);
        });
      }
    }

    if (_currentOrderId != null) {
      _orderSubscription = SupabaseService.getOrderStream(_currentOrderId!).listen((orders) {
        if (orders.isNotEmpty) {
          final newOrderData = orders.first;
          final String status = newOrderData['status'] ?? 'PENDING';
          final double? driverLat = newOrderData['driver_latitude']?.toDouble();
          
          if (mounted) {
            setState(() {
              _orderData = newOrderData;
              _isLoading = false;
              _updateMarkers();
            });
          }

          // 1. Notification: Driver Started Journey
          if (!_hasNotifiedStarted && driverLat != null) {
            _hasNotifiedStarted = true;
            NotificationService().showNotification(
              title: 'Driver is on the way! 🚛',
              body: 'Your fuel delivery driver ${newOrderData['driver_name'] ?? ''} has started moving towards you.',
            );
          }

          // 2. Notification: Driver Arrived (Simulated by distance or status)
          // Since it's a simulation, we'll check if status is 'ARRIVED' or 'DELIVERED' or 'DELIVERING'
          if (!_hasNotifiedArrived && (status == 'DELIVERING' || status == 'ARRIVED')) {
            _hasNotifiedArrived = true;
            NotificationService().showNotification(
              title: 'Driver has arrived! 📍',
              body: 'The fuel tanker is at your delivery location. Please ready your vehicle.',
            );
          }

          // 3. Notification: Order Completed
          if (!_hasNotifiedCompleted && status == 'DELIVERED') {
            _hasNotifiedCompleted = true;
            
            // Award Loyalty Points
            final double totalPrice = (newOrderData['total_price'] ?? 0.0).toDouble();
            if (totalPrice > 0) {
              SupabaseService.awardLoyaltyPoints(newOrderData['user_id'], totalPrice);
            }

            NotificationService().showNotification(
              title: 'Delivery Complete! ✅',
              body: 'Your fuel has been successfully delivered. Check your history for the receipt.',
            );
          }

          // Trigger simulation if driver is not yet assigned locally
          if (newOrderData['driver_latitude'] == null && newOrderData['latitude'] != null) {
             DriverSimulationService.startOrderSimulation(
               _currentOrderId!, 
               LatLng(newOrderData['latitude'], newOrderData['longitude']),
             );
          }
        }
      });
    }
  }

  void _updateMarkers() {
    if (_orderData == null) return;

    Set<Marker> newMarkers = {};

    // Destination Marker (User)
    if (_orderData!['latitude'] != null && _orderData!['longitude'] != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(_orderData!['latitude'], _orderData!['longitude']),
          infoWindow: const InfoWindow(title: 'Your Delivery Spot'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    // Driver Marker (Moving Truck)
    if (_orderData!['driver_latitude'] != null && _orderData!['driver_longitude'] != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_orderData!['driver_latitude'], _orderData!['driver_longitude']),
          infoWindow: const InfoWindow(title: 'Fuel Tanker'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          rotation: Random().nextDouble() * 360, // Simple rotation effect
        ),
      );

      // Camera follows the driver smoothly
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_orderData!['driver_latitude'], _orderData!['driver_longitude']),
          ),
        );
      }
    }

    setState(() => _markers = newMarkers);
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '4:25 PM';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      int hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      String minute = date.minute.toString().padLeft(2, '0');
      String period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '4:25 PM';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map View
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _orderData != null && _orderData!['latitude'] != null
                    ? LatLng(_orderData!['latitude'], _orderData!['longitude'])
                    : const LatLng(37.7749, -122.4194),
                zoom: 15,
              ),
              markers: _markers,
              style: _mapStyle,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFFF6600))),

          // Back Button
          Positioned(
            top: 60,
            left: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Title
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Order Tracking',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),

          // Bottom Tracking Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: _orderData == null && !_isLoading
                  ? const Center(child: Text("No active order found."))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _orderData?['status'] ?? 'PROCESSING',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(
                                  Icons.circle,
                                  color: Color(0xFFFF6600),
                                  size: 10,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'LIVE TRACKING',
                                  style: TextStyle(
                                    color: Color(0xFFFF6600),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _orderData?['estimated_minutes']?.toString() ?? '15',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6600),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'MIN',
                                  style: TextStyle(
                                    color: Color(0xFFFF6600),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Flexible(
                              child: Text(
                                _orderData?['status'] == 'DELIVERED' 
                                    ? 'Expected Arrival: Arrived'
                                    : 'Arriving at ${_formatTime(_orderData?['scheduled_time'])}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_orderData?['fuel_type'] ?? 'Petrol'} • ${_orderData?['quantity'] ?? '---'} Gallons',
                          style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFEEEEEE), height: 1),
                        const SizedBox(height: 24),

                        // Driver Row
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Row(
                            key: ValueKey(_orderData?['driver_name'] ?? 'Assigning'),
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEEEE),
                                    border: Border.all(
                                      color: _orderData?['driver_name'] != null ? const Color(0xFFFF6600) : Colors.grey.withAlpha(50),
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _orderData?['driver_photo'] != null 
                                    ? Image.network(
                                        _orderData!['driver_photo'],
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.person, color: Colors.grey, size: 30),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _orderData?['driver_name'] ?? 'Assigning Driver...',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _orderData?['driver_name'] != null ? const Color(0xFF333333) : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _orderData?['driver_vehicle'] ?? 'Scanning nearby tankers...',
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
  
                                // Contact Icons
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          driverName: _orderData?['driver_name'] ?? 'Marcus Johnson', // Fallback to mockup name
                                          driverPhotoUrl: _orderData?['driver_photo'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0E6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Color(0xFFFF6600),
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () async {
                                    final driverPhone = _orderData?['driver_phone'] ?? '1234567890'; // Mock number or get from backend
                                    final Uri phoneUri = Uri(scheme: 'tel', path: driverPhone);
                                    if (await canLaunchUrl(phoneUri)) {
                                      await launchUrl(phoneUri);
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not launch phone dialer')),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0E6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.phone_outlined,
                                      color: Color(0xFFFF6600),
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Home Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_orderData?['status'] == 'DELIVERED') {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => DeliveryCompleteScreen(
                                      orderData: _orderData!,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6600),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _orderData?['status'] == 'DELIVERED' ? 'Delivery Complete' : 'Back to Dashboard',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
