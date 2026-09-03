import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loan_app/providers/loan_provider.dart';
import 'package:loan_app/models/loan.dart';
import 'package:loan_app/widgets/stat_card.dart';
import 'package:loan_app/utils/toast_utils.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<LoanProvider>();
    await provider.fetchLoans();
  }

  Future<void> _approveLoan(int loanId) async {
    try {
      final provider = context.read<LoanProvider>();
      await provider.approveLoan(loanId);
      showToast('Loan approved successfully!');
    } catch (e) {
      showToast('Failed to approve loan: $e', isError: true);
    }
  }

  Future<void> _rejectLoan(int loanId) async {
    try {
      final provider = context.read<LoanProvider>();
      await provider.rejectLoan(loanId, reason: 'Rejected by agent');
      showToast('Loan rejected');
    } catch (e) {
      showToast('Failed to reject loan: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Row(
    children: [
      ClipOval(
        child: Image.asset(
          'assets/images/loanImg.jpg',
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 32,
              height: 32,
              color: Colors.white,
              child: Icon(
                Icons.account_balance_wallet,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 10),
      const Text('Agent Dashboard'),
    ],
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _loadData,
    ),
  ],
),
      body: Consumer<LoanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = provider.getStatistics();
          final pendingLoans = provider.loans.where((l) => l.status == 'pending').toList();

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Loans',
                          value: stats['total'] ?? 0,
                          icon: Icons.assignment,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Pending',
                          value: stats['pending'] ?? 0,
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Active',
                          value: stats['active'] ?? 0,
                          icon: Icons.payment,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Completed',
                          value: stats['completed'] ?? 0,
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pending Loans
                  Text(
                    'Pending Loan Applications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  if (pendingLoans.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'No pending loan applications',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingLoans.length,
                      itemBuilder: (context, index) {
                        final loan = pendingLoans[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Loan #${loan.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'PENDING',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Amount: ₦${loan.amount.toStringAsFixed(0)}'),
                                Text('Tenure: ${loan.tenure} days'),
                                Text('Interest: ${loan.interestRate}%'),
                                if (loan.customerName != null)
                                  Text('Customer: ${loan.customerName}'),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _approveLoan(loan.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Approve',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _rejectLoan(loan.id),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Reject',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}