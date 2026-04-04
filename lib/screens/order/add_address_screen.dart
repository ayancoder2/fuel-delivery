import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? initialAddress;
  const AddAddressScreen({super.key, this.initialAddress});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _isEditing = true;
      final addr = widget.initialAddress!;
      _titleController.text = addr['title'] ?? '';
      _addressController.text = addr['address'] ?? '';
      _isDefault = addr['is_default'] ?? false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_titleController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final query = _addressController.text.trim();
        final response = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1'),
          headers: {'User-Agent': 'FuelDirectApp'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to connect to map services.');
        }

        final List data = json.decode(response.body);
        if (data.isEmpty) {
          throw Exception('Could not pinpoint "$query". Please be more specific with city/country.');
        }

        final double lat = double.parse(data[0]['lat']);
        final double lng = double.parse(data[0]['lon']);

        if (_isEditing) {
          await SupabaseService.updateAddress(
            addressId: widget.initialAddress!['id'],
            title: _titleController.text.trim(),
            address: query,
            latitude: lat,
            longitude: lng,
            isDefault: _isDefault,
          );
        } else {
          await SupabaseService.addAddress(
            userId: user.id,
            title: _titleController.text.trim(),
            address: query,
            latitude: lat,
            longitude: lng,
            isDefault: _isDefault,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Address updated successfully!' : 'Address saved successfully!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Address' : 'Add Address',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Update Address' : 'Address Details',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF333333),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Give this address a title like "Home" or "Work"',
              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Address Title'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              hint: 'e.g. Home, Office, Gym',
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Full Address'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              hint: 'e.g. 123 Main St, Apartment 4B, City, State',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Checkbox(
                  value: _isDefault,
                  activeColor: const Color(0xFFFF6600),
                  onChanged: (val) => setState(() => _isDefault = val ?? false),
                ),
                const Text(
                  'Set as default address',
                  style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'UPDATE ADDRESS' : 'SAVE ADDRESS',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      ),
    );
  }
}
