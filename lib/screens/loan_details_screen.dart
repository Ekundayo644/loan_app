import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:loan_app/providers/loan_provider.dart';
import 'package:loan_app/widgets/repayment_dialog.dart';
import 'package:loan_app/widgets/custom_button.dart';
import 'package:loan_app/widgets/repayment_history_item.dart';
import 'package:loan_app/utils/toast_utils.dart';

class LoanDetailsScreen extends StatefulWidget {
  final int loanId;

  const LoanDetailsScreen({
    super.key,
    required this.loanId,
  });

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  Map<String, dynamic>? _loanDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoanDetails();
  }

  Future<void> _loadLoanDetails() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<LoanProvider>();
      final details = await provider.getLoanDetails(widget.loanId);
      setState(() {
        _loanDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showToast('Failed to load loan details: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLoanDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loanDetails == null
              ? const Center(child: Text('No loan details found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loan Status Card
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      
                      // Loan Summary
                      _buildLoanSummary(),
                      const SizedBox(height: 16),
                      
                      // Repayment Schedule
                      _buildRepaymentSchedule(),
                      const SizedBox(height: 16),
                      
                      // Repayment History
                      _buildRepaymentHistory(),
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      if (_loanDetails!['loan']['status'] == 'disbursed' ||
                          _loanDetails!['loan']['status'] == 'approved')
                        _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final loan = _loanDetails!['loan'];
    final status = loan['status'];
    final statusColors = {
      'pending': Colors.orange,
      'approved': Colors.blue,
      'disbursed': Colors.green,
      'completed': Colors.green,
      'rejected': Colors.red,
      'defaulted': Colors.red,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan #${loan['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColors[status]?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(
                      color: statusColors[status],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  'Amount',
                  _formatCurrency(loan['amount']),
                  Icons.attach_money,
                ),
                _buildInfoItem(
                  'Tenure',
                  '${loan['tenure']} days',
                  Icons.calendar_today,
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  'Interest',
                  '${loan['interest_rate']}%',
                  Icons.percent,
                ),
                _buildInfoItem(
                  'Total',
                  _formatCurrency(loan['total_repayment']),
                  Icons.calculate,  // or Icons.attach_money,
                ),
              ],
            ),
            if (loan['monthly_installment'] != null) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    'Monthly Installment',
                    _formatCurrency(loan['monthly_installment']),
                    Icons.calendar_month,
                  ),
                  _buildInfoItem(
                    'Due Date',
                    loan['due_date'] != null
                        ? _formatDate(DateTime.parse(loan['due_date']))
                        : 'N/A',
                    Icons.event,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoanSummary() {
    final loan = _loanDetails!['loan'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Product', loan['product_name'] ?? 'N/A'),
            _buildSummaryRow('Purpose', loan['purpose'] ?? 'Not specified'),
            _buildSummaryRow(
              'Application Date',
              _formatDate(DateTime.parse(loan['application_date'])),
            ),
            if (loan['approval_date'] != null)
              _buildSummaryRow(
                'Approval Date',
                _formatDate(DateTime.parse(loan['approval_date'])),
              ),
            if (loan['disbursement_date'] != null)
              _buildSummaryRow(
                'Disbursement Date',
                _formatDate(DateTime.parse(loan['disbursement_date'])),
              ),
            if (loan['rejection_reason'] != null)
              _buildSummaryRow(
                'Rejection Reason',
                loan['rejection_reason'],
                isError: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isError ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentSchedule() {
    final loan = _loanDetails!['loan'];
    final totalRepayment = loan['total_repayment'] as double;
    final amount = loan['amount'] as double;
    final interestRate = loan['interest_rate'] as double;
    final tenure = loan['tenure'] as int;

    // Calculate repayment schedule
    final interest = amount * interestRate / 100;
    final total = amount + interest;
    final installment = total / (tenure / 30);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repayment Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildScheduleRow('Principal Amount', _formatCurrency(amount)),
            _buildScheduleRow('Interest (${interestRate}%)', _formatCurrency(interest)),
            _buildScheduleRow('Processing Fee', _formatCurrency(loan['processing_fee'] ?? 0)),
            const Divider(),
            _buildScheduleRow(
              'Total Repayment',
              _formatCurrency(total),
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildScheduleRow(
              'Monthly Installment',
              _formatCurrency(installment),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentHistory() {
    final repayments = _loanDetails!['repayments'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repayment History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${repayments.length} payments',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (repayments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No repayments recorded yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: repayments.length > 5 ? 5 : repayments.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final repayment = repayments[index];
                  return RepaymentHistoryItem(
                    repayment: repayment,
                  );
                },
              ),
            if (repayments.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    // Show all repayments in a dialog
                    _showAllRepayments(repayments);
                  },
                  child: Text('View all ${repayments.length} payments'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAllRepayments(List repayments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Repayments'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.separated(
            itemCount: repayments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final repayment = repayments[index];
              return ListTile(
                title: Text(_formatCurrency(repayment['amount'])),
                subtitle: Text(repayment['payment_method'] ?? 'N/A'),
                trailing: Text(
                  _formatDate(DateTime.parse(repayment['payment_date'])),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final loan = _loanDetails!['loan'];
    final isDisbursed = loan['status'] == 'disbursed';
    final isApproved = loan['status'] == 'approved';

    if (!isDisbursed && !isApproved) return const SizedBox.shrink();

    return Column(
      children: [
        if (isDisbursed)
          CustomButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => RepaymentDialog(
                  loanId: widget.loanId,
                  totalAmount: loan['total_repayment'],
                  onSuccess: () {
                    _loadLoanDetails();
                  },
                ),
              );
            },
            text: 'Make Payment',
            icon: Icons.payment,
          ),
        if (isApproved && !isDisbursed)
          const SizedBox(height: 12),
        if (isApproved && !isDisbursed)
          CustomButton(
            onPressed: () {
              // Show loan agreement/confirmation
              _showDisbursementConfirmation();
            },
            text: 'Accept & Get Disbursed',
            icon: Icons.check_circle,
          ),
      ],
    );
  }

  void _showDisbursementConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Disbursement'),
        content: const Text(
          'By confirming, you agree to the loan terms and conditions. '
          'The funds will be disbursed to your account immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Call API to disburse loan
                showToast('Loan disbursed successfully!');
                _loadLoanDetails();
              } catch (e) {
                showToast('Failed to disburse loan: $e', isError: true);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    return NumberFormat.currency(
      symbol: '₦',
      decimalDigits: 0,
    ).format(amount ?? 0);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y HH:mm').format(date);
  }
}