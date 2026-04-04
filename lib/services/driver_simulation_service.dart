import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'supabase_service.dart';

class DriverSimulationService {
  static final Map<String, Timer?> _simulations = {};

  /// Starts a simulation that updates the driver's location in Supabase.
  static void startOrderSimulation(String orderId, LatLng destination) {
    // If a simulation is already running for this order, cancel it
    stopOrderSimulation(orderId);

    // Starting point: Slightly offset from destination (simulating a nearby driver)
    final startLat = destination.latitude + (Random().nextDouble() - 0.5) * 0.05;
    final startLng = destination.longitude + (Random().nextDouble() - 0.5) * 0.05;
    
    int currentStep = 0;
    const totalSteps = 100; // Increased steps for smoother movement
    const stepDuration = Duration(seconds: 2);

    _simulations[orderId] = Timer.periodic(stepDuration, (timer) async {
      if (currentStep == 2) {
        // Mock driver assignment after 4 seconds (2 steps)
        await SupabaseService.updateOrderDriver(
          orderId: orderId,
          driverName: 'Robert Wilson',
          driverPhoto: 'https://randomuser.me/api/portraits/men/32.jpg',
          driverVehicle: 'Volvo FH16 Tanker (ABC-1234)',
        );
      }

      if (currentStep >= totalSteps) {
        timer.cancel();
        _simulations.remove(orderId);
        // Mark as Delivered at the end
        await SupabaseService.client.from('orders').update({'status': 'DELIVERED'}).eq('id', orderId);
        return;
      }

      // Linear interpolation
      final t = currentStep / totalSteps;
      final currentLat = startLat + (destination.latitude - startLat) * t;
      final currentLng = startLng + (destination.longitude - startLng) * t;

      await SupabaseService.updateDriverLocation(orderId, currentLat, currentLng);
      
      currentStep++;
    });
  }

  static void stopOrderSimulation(String orderId) {
    _simulations[orderId]?.cancel();
    _simulations.remove(orderId);
  }
}
