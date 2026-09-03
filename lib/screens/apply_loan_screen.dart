import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loan_app/providers/loan_provider.dart';
import 'package:loan_app/providers/auth_provider.dart';
import 'package:loan_app/widgets/custom_button.dart';
import 'package:loan_app/widgets/custom_text_field.dart';
import 'package:loan_app/utils/toast_utils.dart';

class ApplyLoanScreen extends StatefulWidget {
  const ApplyLoanScreen({super.key});

  @override
  State<ApplyLoanScreen> createState() => _ApplyLoanScreenState();
}

class _ApplyLoanScreenState extends State<ApplyLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _tenureController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _tenureController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _applyForLoan() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    final tenure = int.tryParse(_tenureController.text);

    if (amount == null || amount <= 0) {
      showToast('Please enter a valid amount', isError: true);
      return;
    }

    if (tenure == null || tenure <= 0) {
      showToast('Please enter a valid tenure', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<LoanProvider>();
      await provider.applyForLoan(
        amount: amount,
        tenure: tenure,
        purpose: _purposeController.text,
        duration: 'days',
      );
      
      if (mounted) {
        showToast('Loan application submitted successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showToast('Application failed: $e', isError: true);
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
      appBar: AppBar(
        title: const Text('Apply for Loan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please fill in the details below to apply for a loan',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _amountController,
                label: 'Loan Amount',
                hint: 'Enter amount (e.g., 50000)',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter loan amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _tenureController,
                label: 'Tenure (Days)',
                hint: 'Enter number of days',
                prefixIcon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter tenure';
                  }
                  final tenure = int.tryParse(value);
                  if (tenure == null || tenure <= 0) {
                    return 'Enter a valid tenure';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _purposeController,
                label: 'Purpose',
                hint: 'Why do you need this loan?',
                prefixIcon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the purpose';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _applyForLoan,
                isLoading: _isLoading,
                text: 'Submit Application',
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}