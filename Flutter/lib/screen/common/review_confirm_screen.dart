import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/screen/auth/login_screen.dart';
import '/providers/theme_provider.dart';

class ReviewConfirmScreen extends StatelessWidget {
  final String fullName, phone, email, nationalId;
  final String licenseNumber, licenseType;
  final String plateNumber, truckType, capacity;

  const ReviewConfirmScreen({
    super.key,
    required this.fullName, required this.phone,
    required this.email, required this.nationalId,
    required this.licenseNumber, required this.licenseType,
    required this.plateNumber, required this.truckType,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.regBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.isDark ? Colors.white.withOpacity(0.02) : Colors.transparent,
                borderRadius: BorderRadius.circular(45),
                border: Border.all(color: t.border, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                child: Column(children: [
                  Align(alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 45, height: 45,
                        decoration: BoxDecoration(color: t.fieldBg, shape: BoxShape.circle,
                          border: Border.all(color: t.border)),
                        child: Icon(Icons.arrow_back, color: AppTheme.primary, size: 22)))),
                  const SizedBox(height: 15),
                  Text('Review & Confirm',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: t.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Please check your details',
                      style: TextStyle(fontSize: 16, color: t.textMuted)),
                  const SizedBox(height: 30),
                  _reviewCard(context, t, 'Personal Information', Icons.person_outline, {
                    'Full Name': fullName, 'Phone': phone,
                    'Email': email, 'National ID': nationalId,
                  }),
                  const SizedBox(height: 15),
                  _reviewCard(context, t, 'License Details', Icons.badge_outlined, {
                    'License Number': licenseNumber, 'License Type': licenseType,
                  }),
                  const SizedBox(height: 15),
                  _reviewCard(context, t, 'Vehicle Information', Icons.local_shipping_outlined, {
                    'Plate Number': plateNumber, 'Truck Type': truckType, 'Capacity': capacity,
                  }),
                  const SizedBox(height: 40),
                  // Create Account button
                  Container(width: double.infinity, height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF009EA3), AppTheme.primary]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Create Account',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)))),
                  const SizedBox(height: 20),
                  Text('By clicking Create Account, you agree to our Terms and Services',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.5)),
                  const SizedBox(height: 10),
                  Text('© 2025 TruckMate', style: TextStyle(color: t.textMuted, fontSize: 13)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(BuildContext context, AppTheme t, String title, IconData icon, Map<String, String> items) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card, borderRadius: BorderRadius.circular(25),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(Icons.edit_outlined, color: t.textMuted, size: 18),
        ]),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: t.border, height: 1)),
        ...items.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 110, child: Text('${e.key}:', style: TextStyle(color: t.textMuted, fontSize: 13))),
            Expanded(child: Text(e.value, style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          ]))),
      ]),
    );
  }
}