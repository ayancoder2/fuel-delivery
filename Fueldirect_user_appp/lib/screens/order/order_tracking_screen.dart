import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'delivery_complete_screen.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/financial_service.dart';
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
  Timer? _pollingTimer;
  Map<String, dynamic>? _orderData;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _userIcon;
  bool _isLoading = true;
  String? _currentOrderId;
  
  // Guard to prevent starting simulation multiple times
  bool _simulationStarted = false;

  // Notification flags — fire each exactly once per order lifecycle
  bool _hasNotifiedDriverAssigned = false;
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
    _loadCustomIcons();
    _initializeTracking();
  }

  Future<void> _loadCustomIcons() async {
    try {
      _truckIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/truck_marker.png',
      );
      _userIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/images/map.png',
      );
    } catch (e) {
      debugPrint('Error loading custom icons: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _pollingTimer?.cancel();
    if (_currentOrderId != null) {
      DriverSimulationService.stopOrderSimulation(_currentOrderId!);
    }
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    if (_currentOrderId == null) {
      final activeOrder = await OrderService.getActiveOrder(user.id);
      if (activeOrder != null) {
        final computed = _computeMarkersAndPolylines(activeOrder);
        setState(() {
          _currentOrderId = activeOrder['id'];
          _orderData = activeOrder;
          _isLoading = false;
          _markers = computed.$1;
          _polylines = computed.$2;
        });
        _animateCameraForOrder(activeOrder);

        // Start simulation if no driver yet
        // Simulation auto-start disabled as per user request to test real tracking
        /*
        if (!_simulationStarted && activeOrder['status'] != 'completed') {
          _simulationStarted = true;
          DriverSimulationService.startOrderSimulation(
            activeOrder['id'],
            LatLng(activeOrder['latitude'], activeOrder['longitude']),
          );
        }
        */
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      // If we have an ID, fetch it once to show data immediately
      try {
        final order = await Supabase.instance.client
            .from('orders')
            .select('*, vehicles(make, model, license_plate)')
            .eq('id', _currentOrderId!)
            .single();
        
        // Compute markers BEFORE setState to avoid nested setState
        final computed = _computeMarkersAndPolylines(order);
        setState(() {
          _orderData = order;
          _isLoading = false;
          _markers = computed.$1;
          _polylines = computed.$2;
        });

        // Animate camera AFTER setState (safe outside)
        _animateCameraForOrder(order);

        // Simulation auto-start disabled as per user request to test real tracking
        /*
        if (!_simulationStarted && order['status'] != 'completed' && order['latitude'] != null) {
          _simulationStarted = true;
           DriverSimulationService.startOrderSimulation(
             _currentOrderId!, 
             LatLng(order['latitude'], order['longitude']),
           );
        }
        */
      } catch (e) {
        debugPrint('Error fetching order initially: $e');
        // fall back to stream only, but turn off loading after a delay if still empty
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isLoading) setState(() => _isLoading = false);
        });
      }
    }
    if (_currentOrderId != null) {
      // 1. Live Stream Listener
      _orderSubscription = OrderService.getOrderStream(_currentOrderId!).listen((orders) {
        debugPrint('TRACKING: Received Stream Update for $_currentOrderId');
        if (orders.isNotEmpty) {
          _updateUIWithNewData(orders.first);
        }
      });

      // 2. Polling Fallback (In case Realtime is not enabled in Supabase)
      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          final order = await Supabase.instance.client
              .from('orders')
              .select('*, vehicles(make, model, license_plate)')
              .eq('id', _currentOrderId!)
              .single();
          
          if (mounted) {
            debugPrint('TRACKING: Received Polling Update for $_currentOrderId (Status: ${order['status']})');
            _updateUIWithNewData(order);
          }
        } catch (e) {
          debugPrint('TRACKING POLLING ERROR: $e');
        }
      });
    }
  }

  void _updateUIWithNewData(Map<String, dynamic> newOrderData) {
    if (!mounted) return;
    
    final String status = newOrderData['status'] ?? 'PENDING';
    
    // Compute markers before calling setState
    final computed = _computeMarkersAndPolylines(newOrderData);
    setState(() {
      _orderData = newOrderData;
      _isLoading = false;
      _markers = computed.$1;
      _polylines = computed.$2;
    });

    // Animate camera to follow driver if available, otherwise destination
    if (newOrderData['driver_latitude'] != null) {
      _animateCameraForOrder(newOrderData);
    } else {
      _animateCameraForOrder(newOrderData); // Still centers on destination initially
    }

    // ── NOTIFICATION: Driver Assigned ──
    if (!_hasNotifiedDriverAssigned && newOrderData['driver_latitude'] != null) {
      _hasNotifiedDriverAssigned = true;
      final driverName = newOrderData['driver_name'] ?? 'Your driver';
      NotificationService().showNotification(
        id: 1001,
        title: '🚚 Driver Assigned!',
        body: '$driverName is on the way to you. Track in real-time.',
      );
    }

    // ── NOTIFICATION: Order Delivered ──
    if (!_hasNotifiedCompleted && status == 'DELIVERED') {
      _hasNotifiedCompleted = true;
      NotificationService().showNotification(
        id: 1002,
        title: '✅ Fuel Delivered!',
        body: 'Your fuel has been delivered. Enjoy the ride! 🛣️',
      );
    }

    // Simulation auto-start disabled as per user request to test real tracking
    /*
    if (!_simulationStarted && status != 'DELIVERED') {
      _simulationStarted = true;
      DriverSimulationService.startOrderSimulation(
        _currentOrderId!, 
        LatLng(newOrderData['latitude'] ?? 30.3753, newOrderData['longitude'] ?? 69.3451),
      );
    }
    */
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Computes markers and polylines from order data WITHOUT calling setState.
  /// Returns a record of (markers, polylines).
  (Set<Marker>, Set<Polyline>) _computeMarkersAndPolylines(Map<String, dynamic> data) {
    Set<Marker> newMarkers = {};
    Set<Polyline> newPolylines = {};

    final double? userLat = data['latitude']?.toDouble();
    final double? userLng = data['longitude']?.toDouble();
    final double? driverLat = data['driver_latitude']?.toDouble();
    final double? driverLng = data['driver_longitude']?.toDouble();

    // Destination Marker (User)
    if (userLat != null && userLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(userLat, userLng),
          infoWindow: const InfoWindow(title: 'Your Delivery Spot'),
          icon: _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    // Driver Marker (Moving Truck)
    if (driverLat != null && driverLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(driverLat, driverLng),
          infoWindow: const InfoWindow(title: 'Fuel Tanker'),
          icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
        ),
      );

      // Add Polyline if we have both points
      if (userLat != null && userLng != null) {
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [LatLng(driverLat, driverLng), LatLng(userLat, userLng)],
            color: const Color(0xFFFF6600),
            width: 4,
            patterns: [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );

        // Update estimated ETA based on distance
        final distanceKm = _calculateDistance(driverLat, driverLng, userLat, userLng);
        data['estimated_minutes'] = (distanceKm * 2.5).ceil();
      }
    }

    return (newMarkers, newPolylines);
  }

  /// Animates the map camera to fit both driver and destination.
  void _animateCameraForOrder(Map<String, dynamic> data) {
    if (_mapController == null) return;
    final double? driverLat = data['driver_latitude']?.toDouble();
    final double? driverLng = data['driver_longitude']?.toDouble();
    final double? userLat = data['latitude']?.toDouble();
    final double? userLng = data['longitude']?.toDouble();

    if (driverLat != null && driverLng != null && userLat != null && userLng != null) {
      // Zoom to fit both
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(driverLat, userLat),
          min(driverLng, userLng),
        ),
        northeast: LatLng(
          max(driverLat, userLat),
          max(driverLng, userLng),
        ),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
      );
    } else if (driverLat != null && driverLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(driverLat, driverLng)),
      );
    } else if (userLat != null && userLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(userLat, userLng)),
      );
    }
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
    // Set map style
    _mapController!.setMapStyle(_mapStyle);
    
    // If we already have order data, move the camera
    if (_orderData != null) {
      _animateCameraForOrder(_orderData!);
    }
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
                    : const LatLng(30.3753, 69.3451), // Default to Pakistan range for testing
                zoom: 15,
              ),
              markers: _markers,
              polylines: _polylines,
              // style: _mapStyle, // Moved style to onMapCreated for reliability
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
                                  (_orderData?['estimated_minutes']?.toString() ?? 
                                   _orderData?['eta']?.toString().split(' ')[0] ?? 
                                   '15'),
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
                                _orderData?['status'] == 'completed' 
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
