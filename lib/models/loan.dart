class Loan {
  final int id;
  final String userId;
  final double amount;
  final int tenure;
  final String duration;
  final int? productId;
  final String? purpose;
  final String status;
  final double paidAmount;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? disbursedAt;
  final DateTime? createdAt;
  final String? customerName;
  final String? productName;
  final double? interestRate;
  final double? totalRepayment;
  final DateTime? applicationDate;

  Loan({
    required this.id,
    required this.userId,
    required this.amount,
    required this.tenure,
    required this.duration,
    this.productId,
    this.purpose,
    required this.status,
    this.paidAmount = 0,
    this.approvedBy,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.disbursedAt,
    this.createdAt,
    this.customerName,
    this.productName,
    this.interestRate,
    this.totalRepayment,
    this.applicationDate,
  });

  // ============= STATUS DISPLAY =============
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'disbursed':
        return 'Disbursed';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  // ============= STATUS COLOR =============
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'approved':
        return '#4CAF50'; // Green
      case 'rejected':
        return '#F44336'; // Red
      case 'disbursed':
        return '#2196F3'; // Blue
      case 'active':
        return '#9C27B0'; // Purple
      case 'completed':
        return '#4CAF50'; // Green
      default:
        return '#757575'; // Grey
    }
  }

  // ============= PROGRESS =============
  double get progress {
    if (amount == 0) return 0;
    return (paidAmount / amount).clamp(0.0, 1.0);
  }

  // ============= REMAINING AMOUNT =============
  double get remainingAmount {
    return amount - paidAmount;
  }

  // ============= FACTORY METHODS =============
  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      tenure: json['tenure'] ?? 0,
      duration: json['duration'] ?? 'monthly',
      productId: json['product_id'],
      purpose: json['purpose'],
      status: json['status'] ?? 'pending',
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'])
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      disbursedAt: json['disbursed_at'] != null
          ? DateTime.tryParse(json['disbursed_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      // For joined queries
      customerName: json['users'] != null 
          ? json['users']['full_name'] 
          : json['customer_name'],
      productName: json['product_name'],
      interestRate: json['interest_rate']?.toDouble(),
      totalRepayment: json['total_repayment']?.toDouble(),
      applicationDate: json['application_date'] != null
          ? DateTime.tryParse(json['application_date'])
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'tenure': tenure,
      'duration': duration,
      'product_id': productId,
      'purpose': purpose,
      'status': status,
      'paid_amount': paidAmount,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'disbursed_at': disbursedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'customer_name': customerName,
      'product_name': productName,
      'interest_rate': interestRate,
      'total_repayment': totalRepayment,
      'application_date': applicationDate?.toIso8601String(),
    };
  }

  Loan copyWith({
    int? id,
    String? userId,
    double? amount,
    int? tenure,
    String? duration,
    int? productId,
    String? purpose,
    String? status,
    double? paidAmount,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? disbursedAt,
    DateTime? createdAt,
    String? customerName,
    String? productName,
    double? interestRate,
    double? totalRepayment,
    DateTime? applicationDate,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      tenure: tenure ?? this.tenure,
      duration: duration ?? this.duration,
      productId: productId ?? this.productId,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      productName: productName ?? this.productName,
      interestRate: interestRate ?? this.interestRate,
      totalRepayment: totalRepayment ?? this.totalRepayment,
      applicationDate: applicationDate ?? this.applicationDate,
    );
  }
}