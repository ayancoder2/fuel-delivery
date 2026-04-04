import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

import '../order/plan_selection_screen.dart';
import 'edit_profile_screen.dart';
import 'payments_screen.dart';
import 'help_support_screen.dart';
import 'privacy_terms_screen.dart';
import 'my_vehicles_screen.dart';
import 'my_addresses_screen.dart';
import 'wallet_screen.dart';
import '../order/order_history_screen.dart';
import '../../widgets/auth_wrapper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final profile = await SupabaseService.getProfile(user.id);
      if (mounted) {
        setState(() {
          _profileData = profile;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 8, bottom: 8),
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
              icon: const Icon(Icons.close, color: Color(0xFF333333), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EE6)))
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: const Color(0xFFEEEEEE),
                                backgroundImage: (_profileData?['avatar_url'] != null)
                                    ? NetworkImage(_profileData!['avatar_url'])
                                    : const NetworkImage(
                                        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=1974&auto=format&fit=crop',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _profileData?['full_name'] ?? 'Guest User',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.workspace_premium_outlined, color: Color(0xFF6B4EE6), size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Gold Member',
                                  style: TextStyle(
                                    color: Color(0xFF6B4EE6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              SupabaseService.currentUser?.email ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEEEEEE)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                final result = await navigator.push(
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                );
                                if (!context.mounted) return;
                                if (result == true || result == null) {
                                  _loadProfileData();
                                }
                              },
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ACCOUNT MANAGEMENT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF999999),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsCard([
                        _buildSettingsItem(
                          context: context,
                          icon: Icons.directions_car_outlined,
                          iconColor: const Color(0xFFFF8A65),
                          title: 'My Vehicles',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsItem(
                          context: context,
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFF4CAF50),
                          title: 'Address Book',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsItem(
                          context: context,
                          icon: Icons.credit_card_outlined,
                          iconColor: const Color(0xFF2196F3),
                          title: 'Payments',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsItem(
                          context: context,
                          icon: Icons.workspace_premium_outlined,
                          iconColor: const Color(0xFFFFB74D),
                          title: 'Subscription',
                          trailing: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Color(0xFF6B4EE6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsItem(
                          context: context,
                          icon: Icons.receipt_long_outlined,
                          iconColor: const Color(0xFF6B4EE6),
                          title: 'Transaction History',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsItem(
                          context: context,
                          icon: Icons.help_outline,
                          iconColor: const Color(0xFFFFB74D),
                          title: 'Help & Support',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _buildSettingsCard([
                        _buildSettingsItem(
                          context: context,
                          icon: Icons.security_outlined,
                          iconColor: const Color(0xFFFF8A65),
                          title: 'Privacy & Terms',
                        ),
                      ]),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: TextButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            try {
                              await SupabaseService.signOut();
                              if (!context.mounted) return;
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const AuthWrapper()),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error signing out: $e')),
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Version 24.0 (Premium Fuel Delivery)',
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Color(0xFFCCCCCC), size: 14),
      onTap: () async {
        if (title == 'Subscription') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PlanSelectionScreen()),
          );
        } else if (title == 'My Vehicles') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MyVehiclesScreen()),
          );
        } else if (title == 'Address Book') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MyAddressesScreen()),
          );
        } else if (title == 'Wallet & Loyalty') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          );
        } else if (title == 'Payments') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PaymentsScreen()),
          );
        } else if (title == 'Transaction History') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
          );
        } else if (title == 'Help & Support') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
          );
        } else if (title == 'Privacy & Terms') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PrivacyTermsScreen()),
          );
        }
      },
    );
  }
}
