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
      // Linear interpolation
      final t = currentStep / totalSteps;
      final currentLat = startLat + (targetDestination.latitude - startLat) * t;
      final currentLng = startLng + (targetDestination.longitude - startLng) * t;

      // Calculate ETA based on remaining distance
      final p = 0.017453292519943295;
      final c = cos;
      final a = 0.5 - c((targetDestination.latitude - currentLat) * p) / 2 + 
            c(currentLat * p) * c(targetDestination.latitude * p) * 
            (1 - c((targetDestination.longitude - currentLng) * p)) / 2;
      final distanceKm = 12742 * asin(sqrt(a));
      final minutesRemaining = (distanceKm * 2.5).ceil();
      final etaText = minutesRemaining > 0 ? '$minutesRemaining mins' : 'Arriving';

      if (currentStep == 1) {
        // Mock driver assignment after 1 second
        try {
          final now = DateTime.now().toIso8601String();
          await OrderService.client.from('orders').update({
            'driver_name': 'Robert Wilson',
            'driver_photo': 'https://randomuser.me/api/portraits/men/32.jpg',
            'driver_vehicle': 'Volvo FH16 Tanker (ABC-1234)',
            'eta': etaText,
            'status': 'ON_THE_WAY', // Match DB ENUM
            'assigned_at': now,
            'accepted_at': now,
            'meter_reading_start': '4523.50',
            'pickup_photo_url': 'https://images.unsplash.com/photo-1542224566-6e85f2e6772f?auto=format&fit=crop&w=800',
          }).eq('id', orderId);
          debugPrint('SIMULATION: Status updated to in_progress for $orderId');
        } catch (e) {
          debugPrint('SIMULATION ERROR [initial benchmarks]: $e');
        }
      }

      if (currentStep == (totalSteps ~/ 2)) {
        // Mock arrival at half way
        await OrderService.client.from('orders').update({
          'status': 'IN_PROGRESS', // Match DB ENUM
          'arrived_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);
      }

      if (currentStep >= totalSteps) {
        timer.cancel();
        _simulations.remove(orderId);
        
        // Finalize order with delivery benchmarks
        try {
          final orderData = await OrderService.client.from('orders').select('quantity').eq('id', orderId).single();
          final qty = orderData['quantity'] ?? 0.0;
          final meterEnd = 4523.50 + qty;
          
          await OrderService.client.from('orders').update({
            'status': 'DELIVERED', // Match DB ENUM
            'completed_at': DateTime.now().toIso8601String(),
            'meter_reading_end': meterEnd.toStringAsFixed(2),
            'delivery_photo_url': 'https://images.unsplash.com/photo-1563911302283-d2bc129e7570?auto=format&fit=crop&w=800',
          }).eq('id', orderId);
          
          // Legacy complete call for notifications
          await OrderService.completeOrder(orderId);
        } catch (e) {
          debugPrint('SIMULATION ERROR [final benchmarks]: $e');
        }
        return;
      }

      try {
        await OrderService.client.from('orders').update({
          'driver_latitude': currentLat,
          'driver_longitude': currentLng,
          'eta': etaText,
        }).eq('id', orderId);
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
