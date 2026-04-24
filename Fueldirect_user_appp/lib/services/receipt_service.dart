import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ReceiptService {
  static Future<void> generateAndOpenReceipt(Map<String, dynamic> order) async {
    final pdf = pw.Document();

    final vehicle = order['vehicles'];
    final fuelType = order['fuel_type'] ?? 'Premium Diesel';
    final quantity = order['quantity'] ?? 0.0;
    final totalPrice = order['total_price'] ?? 0.0;
    final address = order['delivery_address'] ?? 'No address provided';
    final status = order['status'] ?? 'DELIVERED';
    final id = order['id'] ?? 'ORD-000000';
    final createdAt = order['created_at'] != null 
        ? DateTime.parse(order['created_at']).toLocal() 
        : DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('FuelDirect - Order Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Order ID: $id'),
                pw.Text('Date: ${createdAt.toLocal().toString().split('.')[0]}'),
                pw.Text('Status: $status'),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('Delivery Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Address: $address'),
                pw.Text('Vehicle: ${vehicle != null ? "${vehicle['make']} ${vehicle['model']} (${vehicle['license_plate']})" : "N/A"}'),
                pw.SizedBox(height: 20),
                pw.Text('Order Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Fuel ($fuelType, ${quantity}L)'),
                    pw.Text('Rs. ${totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Delivery Fee'),
                    pw.Text('Rs. 0.00'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Service Fee'),
                    pw.Text('Rs. 0.00'),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text('Thank you for choosing FuelDirect!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                ),
              ],
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_$id.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }
}
