import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_summary_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../services/supabase_service.dart';

class SelectLocationScreen extends StatefulWidget {
  final String vehicleName;
  final String locationName;
  final String fuelType;
  final String quantity;
  final String amount;
  final String subtotal;
  final String discount;
  final String? couponCode;
  final bool useWallet;
  final double latitude;
  final double longitude;
  final String? vehicleId;
  final DateTime scheduledDate;
  final String scheduledTimeSlot;
  final String? notes;

  const SelectLocationScreen({
    super.key,
    required this.vehicleName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.fuelType,
    required this.quantity,
    required this.amount,
    required this.subtotal,
    required this.discount,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    this.couponCode,
    this.useWallet = false,
    this.vehicleId,
    this.notes,
  });

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  late String _currentAddress;
  late LatLng _selectedLatLng;
  
  // Standard Map styling is used instead of _mapStyle to prevent blank rendering in rural areas.

  String? _subscriptionPlan;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _currentAddress = widget.locationName;
    _selectedLatLng = LatLng(widget.latitude, widget.longitude);
    _searchController.text = widget.locationName;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        final profile = await SupabaseService.getProfile(user.id);
        if (mounted && profile != null) {
          setState(() {
            _subscriptionPlan = profile['subscription_plan'];
            _isLoadingProfile = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
    if (mounted) {
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (query.isNotEmpty) {
        _searchLocations(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _searchLocations(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5'),
        headers: {'User-Agent': 'FuelDirectApp'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isSearching = false);
    }
  }

  void _selectLocation(dynamic result) {
    final double lat = double.parse(result['lat']);
    final double lon = double.parse(result['lon']);
    final LatLng position = LatLng(lat, lon);

    setState(() {
      _selectedLatLng = position;
      _currentAddress = result['display_name'];
      _searchResults = [];
      _isSearching = false;
      _searchController.text = result['display_name'];
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json'),
        headers: {'User-Agent': 'FuelDirectApp'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentAddress = data['display_name'] ?? 'Unknown Location';
        });
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
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
          // Real Google Map Background
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 15,
              ),
              // style: _mapStyle, // Removed to allow standard map labels and colors to show
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              onCameraMove: (position) {
                _selectedLatLng = position.target;
              },
              onCameraIdle: () {
                _reverseGeocode(_selectedLatLng);
              },
            ),
          ),
          
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
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
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
                'Confirm Location',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: 130,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: 'Search for a different location..',
                            hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6600)),
                        ),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: Color(0xFFFF6600)),
                          title: Text(
                            result['display_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectLocation(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Fixed Center Pin (Matches Indrive behavior)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFFFF6600),
                  size: 48,
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 48), // Account for the pin pointer
              ],
            ),
          ),

          // Locate Me Button
          Positioned(
            bottom: 300, // Adjusted to be above the bottom card
            right: 24,
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
                icon: const Icon(Icons.my_location, color: Colors.black, size: 24),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('GPS Auto-location is mocked in this demo.')),
                  );
                },
              ),
            ),
          ),

          // Bottom Section (Confirm Location Card)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT SELECTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAAAAAA),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _currentAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF333333)),
                    ],
                  ),
                  // Removed hardcoded San Francisco address text
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFECE0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.access_time_filled, size: 16, color: Color(0xFFFF6600)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ESTIMATED WAIT',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF666666)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '15-20 mins',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoadingProfile ? null : () {
                        double parsedAmount = double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                        double serviceFee = (_subscriptionPlan == 'Family Subscription' || _subscriptionPlan == 'Family Elite') ? 0.0 : 4.99;
                        double finalAmount = parsedAmount + serviceFee;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrderSummaryScreen(
                              vehicleName: widget.vehicleName,
                              locationName: _currentAddress,
                              fuelType: widget.fuelType,
                              quantity: widget.quantity,
                              subtotal: widget.subtotal,
                              discount: widget.discount,
                              amount: '\$${finalAmount.toStringAsFixed(2)}',
                              couponCode: widget.couponCode,
                              useWallet: widget.useWallet,
                              vehicleId: widget.vehicleId,
                              scheduledDate: widget.scheduledDate,
                              scheduledTimeSlot: widget.scheduledTimeSlot,
                              notes: widget.notes,
                              latitude: _selectedLatLng.latitude,
                              longitude: _selectedLatLng.longitude,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6600),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Confirm Order',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
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
