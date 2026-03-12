
enum AccessBlockReason {
  trialTampered,
  subscriptionRequired,
}

class AccessDecision {
  final bool isAllowed;
  final AccessBlockReason? reason;
  final DateTime? trialExpiry;
  final DateTime? subscriptionExpiry;
  final bool isOfflineGrace;

  const AccessDecision._({
    required this.isAllowed,
    this.reason,
    this.trialExpiry,
    this.subscriptionExpiry,
    this.isOfflineGrace = false,
  });

  const AccessDecision.allowed({
    DateTime? trialExpiry,
    DateTime? subscriptionExpiry,
    bool isOfflineGrace = false,
  }) : this._(
          isAllowed: true,
          trialExpiry: trialExpiry,
          subscriptionExpiry: subscriptionExpiry,
          isOfflineGrace: isOfflineGrace,
        );

  const AccessDecision.blocked({
    required AccessBlockReason reason,
    DateTime? trialExpiry,
    DateTime? subscriptionExpiry,
  }) : this._(
          isAllowed: false,
          reason: reason,
          trialExpiry: trialExpiry,
          subscriptionExpiry: subscriptionExpiry,
        );
}

class AccessGuard {
  Future<AccessDecision> checkAccess({bool allowNetwork = true}) async {
    return const AccessDecision.allowed();
  }
}
