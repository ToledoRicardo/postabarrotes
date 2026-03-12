import 'package:shared_preferences/shared_preferences.dart';

class TrialStatus {
  final bool isExpired;
  final bool isTampered;
  final DateTime startDate;
  final DateTime expiryDate;

  const TrialStatus({
    required this.isExpired,
    required this.isTampered,
    required this.startDate,
    required this.expiryDate,
  });

  bool get isBlocked => isExpired || isTampered;
}

class TrialService {
  static const String _keyStartWall = 'trial_start_wall';
  static const String _keyLastWall = 'trial_last_wall';
  static const String _keyBlocked = 'trial_blocked';
  static const String _keyVersion = 'trial_version';
  static const int _trialVersion = 2;

  static TrialService? _instance;
  static SharedPreferences? _prefs;

  TrialService._();

  static Future<TrialService> getInstance() async {
    if (_instance == null) {
      _instance = TrialService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  Future<TrialStatus> checkStatus() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();

    final storedVersion = prefs.getInt(_keyVersion);
    if (storedVersion == null || storedVersion != _trialVersion) {
      await _resetTrial(prefs);
      await prefs.setInt(_keyVersion, _trialVersion);
    }

    final nowWall = DateTime.now();
    final blocked = prefs.getBool(_keyBlocked) ?? false;

    DateTime? startWall = _readDateTime(prefs.getString(_keyStartWall));

    if (startWall == null) {
      startWall = nowWall;
      await prefs.setString(_keyStartWall, startWall.toIso8601String());
    }

    final expiryDate = _addOneMonth(startWall);

    final lastWall = _readDateTime(prefs.getString(_keyLastWall));

    final tampered = blocked || _detectRollback(nowWall, lastWall);
    if (tampered) {
      await prefs.setBool(_keyBlocked, true);
    }

    await prefs.setString(_keyLastWall, nowWall.toIso8601String());

    final expired = !nowWall.isBefore(expiryDate);

    return TrialStatus(
      isExpired: expired,
      isTampered: tampered,
      startDate: startWall,
      expiryDate: expiryDate,
    );
  }

  DateTime _addOneMonth(DateTime base) {
    final nextMonth = base.month == 12 ? 1 : base.month + 1;
    final year = base.month == 12 ? base.year + 1 : base.year;
    final lastDay = DateTime(year, nextMonth + 1, 0).day;
    final day = base.day <= lastDay ? base.day : lastDay;

    return DateTime(
      year,
      nextMonth,
      day,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
      base.microsecond,
    );
  }

  bool _detectRollback(DateTime nowWall, DateTime? lastWall) {
    if (lastWall == null) return false;

    const tolerance = Duration(minutes: 5);
    final rollback = lastWall.subtract(tolerance);
    if (nowWall.isBefore(rollback)) {
      return true;
    }

    return false;
  }

  Future<void> _resetTrial(SharedPreferences prefs) async {
    await prefs.remove(_keyStartWall);
    await prefs.remove(_keyLastWall);
    await prefs.remove(_keyBlocked);
  }

  DateTime? _readDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
