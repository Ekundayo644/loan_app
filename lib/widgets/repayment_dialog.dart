import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:loan_app/providers/loan_provider.dart';
import 'package:loan_app/widgets/custom_button.dart';
import 'package:loan_app/widgets/custom_text_field.dart';
import 'package:loan_app/utils/toast_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class RepaymentDialog extends StatefulWidget {
  final int loanId;
  final double totalAmount;
  final VoidCallback onSuccess;

  const RepaymentDialog({
    super.key,
    required this.loanId,
    required this.totalAmount,
    required this.onSuccess,
  });

  @override
  State<RepaymentDialog> createState() => _RepaymentDialogState();
}

class _RepaymentDialogState extends State<RepaymentDialog> {
  String _selectedMethod = 'bank_transfer';
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  bool _isLoading = false;
  String? _paymentLink;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'bank_transfer',
      'title': 'Bank Transfer',
      'icon': Icons.account_balance,
      'description': 'Transfer directly to our bank account',
    },
    {
      'id': 'paystack',
      'title': 'Paystack',
      'icon': Icons.payment,
      'description': 'Pay with card or bank account via Paystack',
    },
    {
      'id': 'mobile_money',
      'title': 'Mobile Money',
      'icon': Icons.phone_android,
      'description': 'Pay using your mobile money account',
    },
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      showToast('Please enter a valid amount', isError: true);
      return;
    }

    if (_selectedMethod == 'paystack') {
      await _processPaystackPayment(amount);
    } else {
      await _processBankTransfer(amount);
    }
  }

  Future<void> _processPaystackPayment(double amount) async {
    setState(() => _isLoading = true);

    try {
      // Initialize Paystack payment
      // This is a mock implementation - replace with actual Paystack integration
      final paystackKey = 'pk_test_109a84967e966bbc9dbc457205ce83ce6f6770cb';
      final callbackUrl = 'https://supabase.com/adxjesmeaqmykbpjulhb/paystack-callback';
      
      // Generate payment URL
      final paymentUrl = Uri.parse(
        'https://checkout.paystack.com/'
        '?key=$paystackKey'
        '&amount=${(amount * 100).toInt()}'
        '&email=customer@email.com'
        '&reference=TXN_${DateTime.now().millisecondsSinceEpoch}'
        '&callback_url=$callbackUrl'
      );

      // Open Paystack payment page
      if (await canLaunchUrl(paymentUrl)) {
        await launchUrl(paymentUrl, mode: LaunchMode.externalApplication);
        setState(() {
          _paymentLink = paymentUrl.toString();
          _isLoading = false;
        });
        showToast('Complete payment on Paystack page');
      } else {
        throw Exception('Could not launch Paystack payment page');
      }

      // For demo purposes, we'll simulate a successful payment
      // In production, you would handle the callback from Paystack
      await _recordPayment(amount, 'paystack');
    } catch (e) {
      setState(() => _isLoading = false);
      showToast('Payment failed: $e', isError: true);
    }
  }

  Future<void> _processBankTransfer(double amount) async {
    if (_referenceController.text.isEmpty) {
      showToast('Please enter a transaction reference', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await _recordPayment(amount, 'bank_transfer');
  }

  Future<void> _recordPayment(double amount, String method) async {
    try {
      final provider = context.read<LoanProvider>();
      await provider.recordRepayment(
        loanId: widget.loanId,
        amount: amount,
        paymentMethod: method,
        transactionId: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() => _isLoading = false);
      widget.onSuccess();
      Navigator.pop(context);
      showToast('Payment recorded successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      showToast('Failed to record payment: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payment,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make Payment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Loan #${widget.loanId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            
            // Amount
            CustomTextField(
              controller: _amountController,
              label: 'Amount to Pay',
              hint: 'Enter amount',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            
            // Payment Methods
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._paymentMethods.map((method) {
              final isSelected = _selectedMethod == method['id'];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: Icon(
                    method['icon'],
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                  title: Text(
                    method['title'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    method['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedMethod = method['id'];
                    });
                  },
                ),
              );
            }),
            
            // Bank Transfer Details
            if (_selectedMethod == 'bank_transfer') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Bank Transfer Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTransferDetail('Bank Name', 'First Bank of Nigeria'),
                    _buildTransferDetail('Account Name', 'Loan App Limited'),
                    _buildTransferDetail('Account Number', '1234567890'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _referenceController,
                label: 'Transaction Reference',
                hint: 'Enter payment reference',
                prefixIcon: Icons.receipt,
              ),
            ],
            
            // Paystack info
            if (_selectedMethod == 'paystack') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will be redirected to Paystack to complete your payment securely',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            CustomButton(
              onPressed: _isLoading ? null : _processPayment,
              isLoading: _isLoading,
              text: _selectedMethod == 'paystack'
                  ? 'Proceed to Paystack'
                  : 'Submit Payment',
              icon: _selectedMethod == 'paystack' ? Icons.open_in_new : Icons.send,
            ),
            
            // Payment link for Paystack
            if (_paymentLink != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  launchUrl(Uri.parse(_paymentLink!));
                },
                icon: const Icon(Icons.link),
                label: const Text('Open Paystack Page'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransferDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}