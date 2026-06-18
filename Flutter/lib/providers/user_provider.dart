import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  // ✅ Default Data زي اللي في الاسكرينات
  String _fullName = 'محمود ناصر';
  String _phone = '+02 01094357481';
  String _email = '2201977@student.eelu.edu.eg';
  String _nationalId = '';
  String _licenseNumber = '12345678';
  String _licenseType = 'Class B CDL';
  String _plateNumber = 'TRK-5432';
  String _truckType = 'Heavy Duty Semi';
  String _capacity = '25 Tons';

  // Getters
  String get fullName => _fullName;
  String get phone => _phone;
  String get email => _email;
  String get nationalId => _nationalId;
  String get licenseNumber => _licenseNumber;
  String get licenseType => _licenseType;
  String get plateNumber => _plateNumber;
  String get truckType => _truckType;
  String get capacity => _capacity;

  // ✅ Method to get initials (JM من John Michael)
  String get initials {
    if (_fullName.isEmpty) return '??';
    final parts = _fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void update({
    String? fullName,
    String? phone,
    String? email,
    String? nationalId,
    String? licenseNumber,
    String? licenseType,
    String? plateNumber,
    String? truckType,
    String? capacity,
  }) {
    _fullName = fullName ?? _fullName;
    _phone = phone ?? _phone;
    _email = email ?? _email;
    _nationalId = nationalId ?? _nationalId;
    _licenseNumber = licenseNumber ?? _licenseNumber;
    _licenseType = licenseType ?? _licenseType;
    _plateNumber = plateNumber ?? _plateNumber;
    _truckType = truckType ?? _truckType;
    _capacity = capacity ?? _capacity;
    notifyListeners();
  }

  // ✅ Load from API later
  Future<void> loadFromApi(Map<String, dynamic> data) async {
    _fullName = data['fullName'] ?? _fullName;
    _phone = data['phone'] ?? _phone;
    _email = data['email'] ?? _email;
    _licenseNumber = data['licenseNumber'] ?? _licenseNumber;
    _licenseType = data['licenseType'] ?? _licenseType;
    _plateNumber = data['plateNumber'] ?? _plateNumber;
    _truckType = data['truckType'] ?? _truckType;
    _capacity = data['capacity'] ?? _capacity;
    notifyListeners();
  }
}