import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_service.dart';

class DriverSimulationService {
  static final Map<String, Timer?> _simulations = {};

  static void startOrderSimulation(String orderId, LatLng destination) {
    // If a simulation is already running for this order, cancel it
    stopOrderSimulation(orderId);

    // Simulation uses the provided destination (Pakistani coordinates if that's where the order is)
    LatLng targetDestination = destination;

    // Starting point: Slightly offset from destination (simulating a nearby driver)
    final startLat = targetDestination.latitude + (Random().nextDouble() - 0.5) * 0.02;
    final startLng = targetDestination.longitude + (Random().nextDouble() - 0.5) * 0.02;
    
    int currentStep = 0;
    const totalSteps = 60; // 60 steps for ultra-smooth movement
    const stepDuration = Duration(milliseconds: 500); // Update every 0.5 seconds for "Real-Time" feel

    _simulations[orderId] = Timer.periodic(stepDuration, (timer) async {
      if (currentStep == 1) {
        // Mock driver assignment after 1 second
        try {
          await OrderService.updateOrderDriver(
            orderId: orderId,
            driverName: 'Robert Wilson',
            driverPhoto: 'https://randomuser.me/api/portraits/men/32.jpg',
            driverVehicle: 'Volvo FH16 Tanker (ABC-1234)',
          );
          debugPrint('SIMULATION: Driver assigned successfully to $orderId');
        } catch (e) {
          debugPrint('SIMULATION ERROR [updateOrderDriver]: $e');
        }
      }

      if (currentStep >= totalSteps) {
        timer.cancel();
        _simulations.remove(orderId);
        
        // Mark as Delivered and notify
        await OrderService.completeOrder(orderId);
        return;
      }

      // Linear interpolation
      final t = currentStep / totalSteps;
      final currentLat = startLat + (targetDestination.latitude - startLat) * t;
      final currentLng = startLng + (targetDestination.longitude - startLng) * t;

      try {
        await OrderService.updateDriverLocation(orderId, currentLat, currentLng);
      } catch (e) {
        debugPrint('SIMULATION ERROR [updateDriverLocation]: $e');
      }
      
      currentStep++;
    });
  }

  static void stopOrderSimulation(String orderId) {
    _simulations[orderId]?.cancel();
    _simulations.remove(orderId);
  }
}
