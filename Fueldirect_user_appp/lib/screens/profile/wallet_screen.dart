import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/financial_service.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _walletInfo;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final info = await FinancialService.getWalletInfo(user.id);
      final txs = await FinancialService.getWalletTransactions(user.id);
      if (mounted) {
        setState(() {
          _walletInfo = info;
          _transactions = txs;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _topUp() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    // Simulated top-up flow
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: '50.00');
        return AlertDialog(
          title: const Text('Top Up Wallet'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter Amount',
              prefixText: '\$ ',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text) ?? 50.0;
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                await FinancialService.processWalletTransaction(
                  userId: user.id,
                  amount: amount,
                  type: 'TOPUP',
                  description: 'Wallet Top-up',
                );
                
                await _loadData();
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Top-up successful!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Top Up'),
            ),
          ],
        );
      },
    );
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
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Wallet & Loyalty', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6600)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet Card (Glassmorphism inspired)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6600), Color(0xFFFF944D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6600).withAlpha(60),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CURRENT BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              Image.asset('assets/images/logo_white.png', height: 20, errorBuilder: (c, e, s) => const Icon(Icons.flash_on, color: Colors.white, size: 20)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '\$${(_walletInfo?['wallet_balance'] ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LOYALTY POINTS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text('${_walletInfo?['loyalty_points'] ?? 0} pts', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: _topUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFFF6600),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  elevation: 0,
                                ),
                                child: const Text('Top Up', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Loyalty Tier Section
                    const Text('Loyalty Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFFFFECE0), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.workspace_premium, color: Color(0xFFFF6600), size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Gold Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                                    Text('Earn 250 more points for Platinum', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 0.65,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFF1F1F1),
                              color: const Color(0xFFFF6600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Transaction History
                    const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 16),
                    if (_transactions.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No transactions yet', style: TextStyle(color: Colors.grey))))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isTopUp = tx['type'] == 'TOPUP';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isTopUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isTopUp ? Icons.add_rounded : Icons.payment_rounded,
                                color: isTopUp ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(tx['description'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(tx['created_at']).toLocal()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: Text(
                              '${isTopUp ? '+' : '-'}\$${tx['amount'].toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: isTopUp ? Colors.green : Colors.red, fontSize: 15),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
