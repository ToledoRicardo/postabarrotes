import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubscriptionStatus {
  final bool isActive;
  final bool isOfflineGrace;
  final DateTime? expiryDate;
  final DateTime? lastChecked;

  const SubscriptionStatus({
    required this.isActive,
    required this.isOfflineGrace,
    required this.expiryDate,
    required this.lastChecked,
  });

  bool get isEntitled => isActive || isOfflineGrace;
}

class SubscriptionService {
  static const String _keyExpiry = 'subscription_expiry';
  static const String _keyLastChecked = 'subscription_last_checked';
  static const Duration _offlineGrace = Duration(hours: 72);

  static SubscriptionService? _instance;
  final FlutterSecureStorage _storage;

  SubscriptionService._(this._storage);

  static Future<SubscriptionService> getInstance() async {
    _instance ??= SubscriptionService._(const FlutterSecureStorage());
    return _instance!;
  }

  Future<SubscriptionStatus> getStatus({bool allowNetwork = true}) async {
    final cached = await _readCache();

    if (!allowNetwork) {
      return cached;
    }

    // TODO: Integrate in_app_purchase + backend validation.
    return cached;
  }

  Future<void> cacheEntitlement(DateTime expiryDate) async {
    await _storage.write(
      key: _keyExpiry,
      value: expiryDate.toIso8601String(),
    );
    await _storage.write(
      key: _keyLastChecked,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<void> clearEntitlement() async {
    await _storage.delete(key: _keyExpiry);
    await _storage.delete(key: _keyLastChecked);
  }

  Future<SubscriptionStatus> _readCache() async {
    final expiryRaw = await _storage.read(key: _keyExpiry);
    final lastCheckedRaw = await _storage.read(key: _keyLastChecked);

    final expiryDate = _tryParseDate(expiryRaw);
    final lastChecked = _tryParseDate(lastCheckedRaw);
    final now = DateTime.now();

    final isActive = expiryDate != null && now.isBefore(expiryDate);
    final isOfflineGrace =
        !isActive && lastChecked != null && now.isBefore(lastChecked.add(_offlineGrace));

    return SubscriptionStatus(
      isActive: isActive,
      isOfflineGrace: isOfflineGrace,
      expiryDate: expiryDate,
      lastChecked: lastChecked,
    );
  }

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
