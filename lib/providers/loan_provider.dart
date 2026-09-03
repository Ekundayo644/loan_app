import 'package:flutter/material.dart';
import 'package:loan_app/models/loan.dart';
import 'package:loan_app/models/transaction.dart';
import 'package:loan_app/models/repayment.dart';
import 'package:loan_app/models/loan_product.dart';
import 'package:loan_app/services/loan_service.dart';

class LoanProvider extends ChangeNotifier {
  final LoanService _loanService = LoanService();
  
  // State variables
  List<Loan> _loans = [];
  List<Transaction> _transactions = [];
  List<LoanProduct> _loanProducts = [];
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? _loanDetails;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Loan> get loans => _loans;
  List<Transaction> get transactions => _transactions;
  List<LoanProduct> get loanProducts => _loanProducts;
  List<Map<String, dynamic>> get notifications => _notifications;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  Map<String, dynamic>? get loanDetails => _loanDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============= LOAN MANAGEMENT =============

  Future<void> fetchLoans() async {
    _setLoading(true);
    
    try {
      _loans = await _loanService.getLoans();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getLoanDetails(int loanId) async {
    _setLoading(true);
    
    try {
      _loanDetails = await _loanService.getLoanDetails(loanId);
      _error = null;
      return _loanDetails!;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> applyForLoan({
    required double amount,
    required int tenure,
    required String duration,
    int? productId,
    String? purpose,
  }) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.applyForLoan(
        amount: amount,
        tenure: tenure,
        duration: duration,
        productId: productId,
        purpose: purpose,
      );
      
      // Refresh loans after application
      await fetchLoans();
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> approveLoan(int loanId) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.approveLoan(loanId);
      await fetchLoans();
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> rejectLoan(int loanId, {String reason = ''}) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.rejectLoan(loanId, reason: reason);
      await fetchLoans();
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> disburseLoan(int loanId) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.disburseLoan(loanId);
      await fetchLoans();
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============= REPAYMENT MANAGEMENT =============

  Future<Map<String, dynamic>> recordRepayment({
    required int loanId,
    required double amount,
    String paymentMethod = 'bank_transfer',
    String? transactionId,
  }) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.recordRepayment(
        loanId: loanId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );
      
      // Refresh loans and loan details
      await fetchLoans();
      if (_loanDetails != null) {
        _loanDetails = await _loanService.getLoanDetails(loanId);
      }
      
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getRepaymentHistory(int loanId) async {
    _setLoading(true);
    
    try {
      final repayments = await _loanService.getRepaymentHistory(loanId);
      _error = null;
      return repayments;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getRepaymentSummary(int loanId) async {
    _setLoading(true);
    
    try {
      final summary = await _loanService.getRepaymentSummary(loanId);
      _error = null;
      return summary;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============= PAYSTACK PAYMENT INTEGRATION =============

  Future<Map<String, dynamic>> initializePaystackPayment({
    required int loanId,
    required double amount,
    required String email,
    String? reference,
  }) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.initializePaystackPayment(
        loanId: loanId,
        amount: amount,
        email: email,
        reference: reference,
      );
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyPaystackPayment(String reference) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.verifyPaystackPayment(reference);
      
      // Refresh data after payment verification
      await fetchLoans();
      if (_loanDetails != null) {
        _loanDetails = await _loanService.getLoanDetails(_loanDetails!['loan']['id']);
      }
      
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============= TRANSACTION HISTORY =============

  Future<void> fetchTransactions() async {
    _setLoading(true);
    
    try {
      _transactions = await _loanService.getTransactionHistory();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getTransactionDetails(String transactionId) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.getTransactionDetails(transactionId);
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============= LOAN PRODUCTS =============

  Future<void> fetchLoanProducts() async {
    _setLoading(true);
    
    try {
      final products = await _loanService.getLoanProducts();
      _loanProducts = products.map((json) => LoanProduct.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  LoanProduct? getProductById(int id) {
    try {
      return _loanProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============= NOTIFICATIONS =============

  Future<void> fetchNotifications() async {
    _setLoading(true);
    
    try {
      _notifications = await _loanService.getNotifications();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(int notificationId) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.markNotificationRead(notificationId);
      await fetchNotifications(); // Refresh notifications
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  int get unreadNotificationCount {
    return _notifications.where((n) => n['is_read'] == false || n['is_read'] == 0).length;
  }

  // ============= DASHBOARD STATISTICS =============

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    
    try {
      _dashboardStats = await _loanService.getDashboardStats();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Map<String, int> getStatistics() {
    int total = _loans.length;
    int pending = _loans.where((l) => l.status == 'pending').length;
    int active = _loans.where((l) => l.status == 'disbursed' || l.status == 'approved').length;
    int completed = _loans.where((l) => l.status == 'completed').length;
    int defaulted = _loans.where((l) => l.status == 'defaulted').length;

    return {
      'total': total,
      'pending': pending,
      'active': active,
      'completed': completed,
      'defaulted': defaulted,
    };
  }

  // ============= CUSTOMER MANAGEMENT (Agent/Admin) =============

  Future<Map<String, dynamic>> getCustomerDetails(String customerId) async {
    _setLoading(true);
    
    try {
      final result = await _loanService.getCustomerDetails(customerId);
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    _setLoading(true);
    
    try {
      final customers = await _loanService.getAllCustomers();
      _error = null;
      return customers;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============= HELPER METHODS =============

  Loan? getLoanById(int id) {
    try {
      return _loans.firstWhere((loan) => loan.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Loan> getLoansByStatus(String status) {
    return _loans.where((loan) => loan.status == status).toList();
  }

  List<Loan> getActiveLoans() {
    return _loans.where((loan) => 
      loan.status == 'disbursed' || loan.status == 'approved'
    ).toList();
  }

  double getTotalLoanAmount() {
    return _loans.fold(0.0, (sum, loan) => sum + loan.amount);
  }

  double getTotalRepaymentAmount() {
    // ✅ FIXED: Using loan.totalRepayment with null safety
    return _loans.fold(0.0, (sum, loan) => sum + (loan.totalRepayment ?? 0.0));
  }

  // ============= PRIVATE METHODS =============

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ============= CLEAR / RESET =============

  void clearData() {
    _loans = [];
    _transactions = [];
    _loanProducts = [];
    _notifications = [];
    _dashboardStats = null;
    _loanDetails = null;
    _error = null;
    notifyListeners();
  }

  // ============= REFRESH ALL DATA =============

  Future<void> refreshAllData() async {
    _setLoading(true);
    
    try {
      await Future.wait([
        fetchLoans(),
        fetchTransactions(),
        fetchNotifications(),
        fetchDashboardStats(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============= SEARCH & FILTER =============

  List<Loan> searchLoans(String query) {
    if (query.isEmpty) return _loans;
    
    final searchTerm = query.toLowerCase();
    return _loans.where((loan) {
      return loan.id.toString().contains(searchTerm) ||
          (loan.customerName?.toLowerCase().contains(searchTerm) ?? false) ||
          (loan.productName?.toLowerCase().contains(searchTerm) ?? false) ||
          loan.status.toLowerCase().contains(searchTerm);
    }).toList();
  }

  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;
    
    final searchTerm = query.toLowerCase();
    return _transactions.where((transaction) {
      return (transaction.reference?.toLowerCase().contains(searchTerm) ?? false) ||
          transaction.id.toString().contains(searchTerm) ||
          (transaction.paymentMethodDisplay?.toLowerCase().contains(searchTerm) ?? false) ||
          (transaction.statusDisplay?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();
  }

  // ============= FILTER TRANSACTIONS =============

  List<Transaction> filterTransactionsByStatus(String status) {
    if (status == 'All') return _transactions;
    return _transactions.where((t) => t.status == status.toLowerCase()).toList();
  }

  List<Transaction> filterTransactionsByMethod(String method) {
    if (method == 'All') return _transactions;
    return _transactions.where((t) => t.paymentMethod?.toLowerCase() == method.toLowerCase()).toList();
  }
}