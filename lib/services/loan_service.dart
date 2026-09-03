import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loan_app/models/loan.dart';
import 'package:loan_app/models/transaction.dart';

class LoanService {
  final SupabaseClient _supabase = Supabase.instance.client;  // ← ADD THIS!

  // ============= APPLY FOR LOAN =============
  Future<Map<String, dynamic>> applyForLoan({
    required double amount,
    required int tenure,
    required String duration,
    int? productId,
    String? purpose,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = {
        'user_id': user.id,
        'amount': amount,
        'tenure': tenure,
        'duration': duration,
        'duration': duration,
        'product_id': productId,
        'purpose': purpose ?? '',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('loans')
          .insert(data)
          .select()
          .single();

      return {'success': true, 'loan': response};
    } catch (e) {
      throw Exception('Application failed: $e');
    }
  }

  // ============= GET USER LOANS =============
  Future<List<Loan>> getLoans() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final response = await _supabase
          .from('loans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Loan.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch loans: $e');
    }
  }

  // ============= GET SINGLE LOAN DETAILS =============
  Future<Map<String, dynamic>> getLoanDetails(int loanId) async {
    try {
      final response = await _supabase
          .from('loans')
          .select('*, repayments(*)')
          .eq('id', loanId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch loan details: $e');
    }
  }

  // ============= APPROVE LOAN (Agent/Admin) =============
  Future<Map<String, dynamic>> approveLoan(int loanId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final userData = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      if (userData['role'] != 'admin' && userData['role'] != 'agent') {
        throw Exception('Unauthorized: Only admins and agents can approve loans');
      }

      final response = await _supabase
          .from('loans')
          .update({
            'status': 'approved',
            'approved_by': user.id,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loanId)
          .select()
          .single();

      return {'success': true, 'loan': response};
    } catch (e) {
      throw Exception('Approval failed: $e');
    }
  }

  // ============= REJECT LOAN (Agent/Admin) =============
  Future<Map<String, dynamic>> rejectLoan(int loanId, {String reason = ''}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final response = await _supabase
          .from('loans')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'rejected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loanId)
          .select()
          .single();

      return {'success': true, 'loan': response};
    } catch (e) {
      throw Exception('Rejection failed: $e');
    }
  }

  // ============= DISBURSE LOAN =============
  Future<Map<String, dynamic>> disburseLoan(int loanId) async {
    try {
      final response = await _supabase
          .from('loans')
          .update({
            'status': 'disbursed',
            'disbursed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', loanId)
          .select()
          .single();

      return {'success': true, 'loan': response};
    } catch (e) {
      throw Exception('Disbursement failed: $e');
    }
  }

  // ============= RECORD REPAYMENT =============
  Future<Map<String, dynamic>> recordRepayment({
    required int loanId,
    required double amount,
    String paymentMethod = 'bank_transfer',
    String? transactionId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final repaymentData = {
        'loan_id': loanId,
        'amount': amount,
        'payment_method': paymentMethod,
        'transaction_id': transactionId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      };

      final repayment = await _supabase
          .from('repayments')
          .insert(repaymentData)
          .select()
          .single();

      final loanData = await _supabase
          .from('loans')
          .select()
          .eq('id', loanId)
          .single();

      final currentPaid = loanData['paid_amount'] ?? 0.0;
      final newPaid = currentPaid + amount;

      await _supabase
          .from('loans')
          .update({
            'paid_amount': newPaid,
            'status': newPaid >= loanData['amount'] ? 'completed' : 'active',
          })
          .eq('id', loanId);

      return {'success': true, 'repayment': repayment};
    } catch (e) {
      throw Exception('Repayment failed: $e');
    }
  }

  // ============= GET REPAYMENT HISTORY =============
  Future<List<Map<String, dynamic>>> getRepaymentHistory(int loanId) async {
    try {
      final response = await _supabase
          .from('repayments')
          .select()
          .eq('loan_id', loanId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch repayment history: $e');
    }
  }

  // ============= GET REPAYMENT SUMMARY =============
  Future<Map<String, dynamic>> getRepaymentSummary(int loanId) async {
    try {
      final loan = await _supabase
          .from('loans')
          .select()
          .eq('id', loanId)
          .single();

      final repayments = await _supabase
          .from('repayments')
          .select('amount')
          .eq('loan_id', loanId);

      final totalPaid = (repayments as List)
          .fold<double>(0.0, (sum, item) => sum + (item['amount'] as double));

      return {
        'loan_id': loanId,
        'total_amount': loan['amount'],
        'total_paid': totalPaid,
        'remaining': loan['amount'] - totalPaid,
        'status': loan['status'],
        'repayment_count': repayments.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch repayment summary: $e');
    }
  }

  // ============= PAYSTACK PAYMENT INTEGRATION =============
  Future<Map<String, dynamic>> initializePaystackPayment({
    required int loanId,
    required double amount,
    required String email,
    String? reference,
  }) async {
    try {
      final paymentData = {
        'loan_id': loanId,
        'amount': amount,
        'email': email,
        'reference': reference ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('payments')
          .insert(paymentData)
          .select()
          .single();

      return {
        'success': true,
        'data': response,
        'authorization_url': 'https://paystack.com/pay/${response['reference']}',
        'reference': response['reference'],
      };
    } catch (e) {
      throw Exception('Payment initialization failed: $e');
    }
  }

  Future<Map<String, dynamic>> verifyPaystackPayment(String reference) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('reference', reference)
          .single();

      return {
        'success': true,
        'data': response,
        'status': 'success',
      };
    } catch (e) {
      throw Exception('Payment verification failed: $e');
    }
  }

  // ============= TRANSACTION HISTORY =============
  Future<List<Transaction>> getTransactionHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<Map<String, dynamic>> getTransactionDetails(String transactionId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('id', transactionId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }

  // ============= LOAN PRODUCTS =============
  Future<List<Map<String, dynamic>>> getLoanProducts() async {
    try {
      final response = await _supabase
          .from('loan_products')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch loan products: $e');
    }
  }

  // ============= NOTIFICATIONS =============
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(int notificationId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .select()
          .single();

      return {'success': true, 'data': response};
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // ============= GET ALL LOANS (Admin/Agent) =============
  Future<List<Loan>> getAllLoans() async {
    try {
      final response = await _supabase
          .from('loans')
          .select('*, users(full_name, email)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Loan.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch loans: $e');
    }
  }

  // ============= GET DASHBOARD STATS =============
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      final isAdmin = userData['role'] == 'admin' || userData['role'] == 'agent';

      var query = _supabase.from('loans').select();
      if (!isAdmin) {
        query = query.eq('user_id', user.id);
      }

      final loans = await query;

      final totalLoans = loans.length;
      final pendingLoans = loans.where((l) => l['status'] == 'pending').length;
      final approvedLoans = loans.where((l) => l['status'] == 'approved').length;
      final completedLoans = loans.where((l) => l['status'] == 'completed').length;
      final rejectedLoans = loans.where((l) => l['status'] == 'rejected').length;

      final totalAmount = loans.fold<double>(
        0.0,
        (sum, loan) => sum + (loan['amount'] as double),
      );

      final paidAmount = loans.fold<double>(
        0.0,
        (sum, loan) => sum + (loan['paid_amount'] as double? ?? 0.0),
      );

      return {
        'total_loans': totalLoans,
        'pending_loans': pendingLoans,
        'approved_loans': approvedLoans,
        'completed_loans': completedLoans,
        'rejected_loans': rejectedLoans,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'outstanding_amount': totalAmount - paidAmount,
        'role': userData['role'],
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  // ============= GET ALL CUSTOMERS (Admin/Agent) =============
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'customer')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  // ============= GET CUSTOMER DETAILS =============
  Future<Map<String, dynamic>> getCustomerDetails(String customerId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*, loans(*)')
          .eq('id', customerId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch customer details: $e');
    }
  }
}