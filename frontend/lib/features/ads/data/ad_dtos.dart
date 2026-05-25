enum AdPlacementType {
  banner,
  sidebar,
  featured;

  String toWire() {
    switch (this) {
      case AdPlacementType.banner:
        return 'BANNER';
      case AdPlacementType.sidebar:
        return 'SIDEBAR';
      case AdPlacementType.featured:
        return 'FEATURED';
    }
  }

  static AdPlacementType fromWire(String? v) {
    switch (v) {
      case 'SIDEBAR':
        return AdPlacementType.sidebar;
      case 'FEATURED':
        return AdPlacementType.featured;
      default:
        return AdPlacementType.banner;
    }
  }

  String label() {
    switch (this) {
      case AdPlacementType.banner:
        return 'Banner';
      case AdPlacementType.sidebar:
        return 'Sidebar';
      case AdPlacementType.featured:
        return 'Featured';
    }
  }
}

enum AdStatus {
  pendingReview,
  awaitingPayment,
  pendingPayment,
  paymentPendingVerification,
  active,
  rejected,
  expired;

  static AdStatus fromWire(String? v) {
    switch (v) {
      case 'AWAITING_PAYMENT':
        return AdStatus.awaitingPayment;
      case 'PAYMENT_PENDING_VERIFICATION':
        return AdStatus.paymentPendingVerification;
      case 'ACTIVE':
        return AdStatus.active;
      case 'REJECTED':
        return AdStatus.rejected;
      case 'EXPIRED':
        return AdStatus.expired;
      case 'PENDING_PAYMENT':
        return AdStatus.pendingPayment;
      default:
        return AdStatus.pendingReview;
    }
  }

  String label() {
    switch (this) {
      case AdStatus.pendingReview:
        return 'Pending review';
      case AdStatus.awaitingPayment:
        return 'Awaiting payment';
      case AdStatus.pendingPayment:
        return 'Awaiting payment';
      case AdStatus.paymentPendingVerification:
        return 'Pending verification';
      case AdStatus.active:
        return 'Active';
      case AdStatus.rejected:
        return 'Rejected';
      case AdStatus.expired:
        return 'Expired';
    }
  }
}

enum PaymentMethod {
  telebirr,
  cbe,
  bankTransfer;

  String toWire() {
    switch (this) {
      case PaymentMethod.telebirr:
        return 'TELEBIRR';
      case PaymentMethod.cbe:
        return 'CBE';
      case PaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
    }
  }

  static PaymentMethod fromWire(String? v) {
    switch (v) {
      case 'CBE':
        return PaymentMethod.cbe;
      case 'BANK_TRANSFER':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.telebirr;
    }
  }

  String label() {
    switch (this) {
      case PaymentMethod.telebirr:
        return 'Telebirr';
      case PaymentMethod.cbe:
        return 'CBE Birr';
      case PaymentMethod.bankTransfer:
        return 'Bank transfer';
    }
  }
}

class AdPayment {
  final int id;
  final double amount;
  final String currency;
  final PaymentMethod? method;
  final String? status;
  final String? transactionId;

  AdPayment({
    required this.id,
    required this.amount,
    required this.currency,
    this.method,
    this.status,
    this.transactionId,
  });

  factory AdPayment.fromJson(Map<String, dynamic> j) {
    double parseAmount(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return AdPayment(
      id: j['id'] as int,
      amount: parseAmount(j['amount']),
      currency: j['currency'] as String? ?? 'ETB',
      method: j['method'] != null
          ? PaymentMethod.fromWire(j['method'] as String?)
          : null,
      status: j['status'] as String?,
      transactionId: j['transactionId'] as String?,
    );
  }
}

class Advertisement {
  final int id;
  final String companyName;
  final String contactEmail;
  final String contactPhone;
  final String title;
  final String? description;
  final String? imageUrl;
  final String targetUrl;
  final AdPlacementType placementType;
  final int durationDays;
  final AdStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int impressions;
  final int clicks;
  final AdPayment? payment;
  final String? rejectReason;

  Advertisement({
    required this.id,
    required this.companyName,
    required this.contactEmail,
    required this.contactPhone,
    required this.title,
    this.description,
    this.imageUrl,
    required this.targetUrl,
    required this.placementType,
    required this.durationDays,
    required this.status,
    this.startDate,
    this.endDate,
    this.impressions = 0,
    this.clicks = 0,
    this.payment,
    this.rejectReason,
  });

  factory Advertisement.fromJson(Map<String, dynamic> j) {
    DateTime? parseDt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    AdPayment? payment;
    if (j['payment'] is Map) {
      payment = AdPayment.fromJson(
        (j['payment'] as Map).cast<String, dynamic>(),
      );
    }

    return Advertisement(
      id: j['id'] as int,
      companyName: j['companyName'] as String? ?? '',
      contactEmail: j['contactEmail'] as String? ?? '',
      contactPhone: j['contactPhone'] as String? ?? '',
      title: j['title'] as String,
      description: j['description'] as String?,
      imageUrl: j['imageUrl'] as String?,
      targetUrl: j['targetUrl'] as String,
      placementType: AdPlacementType.fromWire(j['placementType'] as String?),
      durationDays: (j['durationDays'] as num?)?.toInt() ?? 0,
      status: AdStatus.fromWire(j['status'] as String?),
      startDate: parseDt(j['startDate']),
      endDate: parseDt(j['endDate']),
      impressions: (j['impressions'] as num?)?.toInt() ?? 0,
      clicks: (j['clicks'] as num?)?.toInt() ?? 0,
      payment: payment,
      rejectReason: j['rejectReason'] as String?,
    );
  }
}

class AdPricingInfo {
  final Map<String, double> rates;
  final double exampleAmount;

  AdPricingInfo({required this.rates, required this.exampleAmount});

  factory AdPricingInfo.fromJson(Map<String, dynamic> j) {
    final ratesRaw = (j['rates'] as Map?)?.cast<String, dynamic>() ?? {};
    final rates = ratesRaw.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    final example = (j['example'] as Map?)?.cast<String, dynamic>() ?? {};
    return AdPricingInfo(
      rates: rates,
      exampleAmount: (example['amountEtb'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AdRequestResult {
  final Advertisement advertisement;
  final double amountEtb;
  final double dailyRateEtb;
  final int durationDays;

  AdRequestResult({
    required this.advertisement,
    required this.amountEtb,
    required this.dailyRateEtb,
    required this.durationDays,
  });
}
